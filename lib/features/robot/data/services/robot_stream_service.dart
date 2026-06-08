import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';

/// Connection state for the WebRTC stream.
enum StreamStatus { disconnected, connecting, connected, error, reconnecting }

/// Manages a WebRTC WHEP connection to a MediaMTX server for low-latency
/// robot camera streaming.
///
/// ## WHEP (WebRTC-HTTP Egress Protocol) Flow:
/// 1. Create a local RTCPeerConnection with receive-only transceivers.
/// 2. Generate an SDP offer and set it as the local description.
/// 3. POST the offer SDP to the MediaMTX WHEP endpoint.
/// 4. MediaMTX responds with an SDP answer.
/// 5. Set the answer as the remote description → media flows.
/// 6. The `Location` header in the response gives us a session URL
///    for teardown (DELETE) when disconnecting.
class RobotStreamService {
  RobotStreamService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;

  final ValueNotifier<StreamStatus> status =
      ValueNotifier(StreamStatus.disconnected);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  String _currentUrl = AppConfig.defaultWhepUrl;
  String get currentUrl => _currentUrl;

  /// The session URL returned by MediaMTX for teardown.
  String? _sessionUrl;

  Timer? _reconnectTimer;
  bool _disposed = false;

  /// The remote video stream renderer should listen to.
  MediaStream? get remoteStream => _remoteStream;

  // ────────────────────── Connect ──────────────────────

  /// Connect to the given WHEP [url].
  ///
  /// Creates a peer connection, generates an SDP offer, sends it to the
  /// MediaMTX WHEP endpoint via HTTP POST, and applies the SDP answer.
  Future<void> connect([String? url]) async {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _currentUrl = (url ?? _currentUrl).trim();
    if (_currentUrl.isEmpty) return;

    status.value = StreamStatus.connecting;
    errorMessage.value = null;

    try {
      // Ensure camera/microphone permissions are granted before
      // initialising the native WebRTC engine (required on Android even
      // for receive-only streams).
      await _ensurePermissions();
      await _createPeerConnection();
      await _negotiateWhep();
    } catch (e) {
      debugPrint('[WebRTC] Connection error: $e');
      status.value = StreamStatus.error;
      errorMessage.value = e.toString();
      _scheduleReconnect();
    }
  }

  /// Whether permissions have already been granted this session.
  bool _permissionsGranted = false;

  /// Request camera & microphone permissions via the WebRTC helper.
  ///
  /// On Android 6+, this triggers the system permission dialog.
  /// The resulting dummy stream is disposed immediately — we only need
  /// this to obtain the runtime permission grant.
  Future<void> _ensurePermissions() async {
    if (_permissionsGranted) return;
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });
      // Stop all tracks immediately — we don't need a local capture.
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
      _permissionsGranted = true;
      debugPrint('[WebRTC] Permissions granted');
    } catch (e) {
      debugPrint('[WebRTC] Permission request failed: $e');
      throw Exception(
        'Camera/microphone permission is required for the robot stream. '
        'Please grant the permission and try again.',
      );
    }
  }

  /// Create the RTCPeerConnection with low-latency ICE config.
  Future<void> _createPeerConnection() async {
    // Clean up any existing connection
    await _closePeerConnection();

    // ICE configuration — no STUN/TURN needed for local network.
    final config = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(config);

    // Add receive-only transceivers for audio and video.
    // This tells the peer we want to receive media, not send.
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // Listen for remote tracks — MediaMTX sends video here.
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint('[WebRTC] onTrack: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        status.value = StreamStatus.connected;
      }
    };

    // Monitor ICE connection state for disconnect detection.
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[WebRTC] ICE state: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          status.value = StreamStatus.connected;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          if (!_disposed) {
            status.value = StreamStatus.error;
            errorMessage.value = 'ICE connection lost';
            _scheduleReconnect();
          }
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          status.value = StreamStatus.disconnected;
          break;
        default:
          break;
      }
    };
  }

  /// Perform the WHEP SDP exchange with MediaMTX.
  ///
  /// MediaMTX WHEP compatibility:
  /// - POST the SDP offer with Content-Type: application/sdp
  /// - Receive SDP answer with status 201
  /// - The Location header contains the session URL for DELETE teardown
  Future<void> _negotiateWhep() async {
    final pc = _peerConnection;
    if (pc == null) return;

    // 1. Create SDP offer
    final offer = await pc.createOffer();

    // 2. Set local description
    await pc.setLocalDescription(offer);

    // 3. POST the offer to the WHEP endpoint
    debugPrint('[WebRTC] POST SDP offer to $_currentUrl');
    final response = await http.post(
      Uri.parse(_currentUrl),
      headers: {'Content-Type': 'application/sdp'},
      body: offer.sdp,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'WHEP server returned ${response.statusCode}: ${response.body}',
      );
    }

    // 4. Store the session URL for teardown (DELETE)
    final location = response.headers['location'];
    if (location != null) {
      // Location can be relative or absolute
      if (location.startsWith('http')) {
        _sessionUrl = location;
      } else {
        final baseUri = Uri.parse(_currentUrl);
        _sessionUrl = baseUri.resolve(location).toString();
      }
      debugPrint('[WebRTC] Session URL: $_sessionUrl');
    }

    // 5. Set the remote SDP answer
    final answer = RTCSessionDescription(response.body, 'answer');
    await pc.setRemoteDescription(answer);

    debugPrint('[WebRTC] WHEP negotiation complete — waiting for media');
  }

  // ────────────────────── Disconnect ──────────────────────

  /// Disconnect from the stream, sending DELETE to teardown the session.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();

    // Send DELETE to MediaMTX to teardown the WHEP session.
    if (_sessionUrl != null) {
      try {
        await http.delete(Uri.parse(_sessionUrl!));
        debugPrint('[WebRTC] Session torn down: $_sessionUrl');
      } catch (e) {
        debugPrint('[WebRTC] Teardown error: $e');
      }
      _sessionUrl = null;
    }

    await _closePeerConnection();
    status.value = StreamStatus.disconnected;
    errorMessage.value = null;
  }

  Future<void> _closePeerConnection() async {
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _remoteStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
  }

  // ────────────────────── Auto-reconnect ──────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_disposed) return;
    status.value = StreamStatus.reconnecting;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed && status.value != StreamStatus.connected) {
        debugPrint('[WebRTC] Auto-reconnecting...');
        connect();
      }
    });
  }

  // ────────────────────── Dispose ──────────────────────

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    disconnect();
    status.dispose();
    errorMessage.dispose();
  }
}
