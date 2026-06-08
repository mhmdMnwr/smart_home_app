import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/robot_stream_service.dart';
import '../widgets/joystick_widget.dart';

/// Fullscreen landscape robot teleoperation page.
/// Video fills the entire screen with transparent joysticks overlaid on top.
class RobotControlPage extends StatefulWidget {
  const RobotControlPage({super.key, this.onExit});

  /// Called when the user taps the back/exit button to leave the robot view.
  final VoidCallback? onExit;

  @override
  State<RobotControlPage> createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  late final RobotStreamService _stream;
  late final RTCVideoRenderer _renderer;
  late final TextEditingController _urlCtrl;
  bool _rendererReady = false;
  bool _showHud = true;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _stream = RobotStreamService();
    _renderer = RTCVideoRenderer();
    _urlCtrl = TextEditingController(text: AppConfig.defaultWhepUrl);
    _initRenderer();
    _stream.status.addListener(_onStatusChanged);
  }

  Future<void> _initRenderer() async {
    try {
      await _renderer.initialize();
      if (mounted) setState(() => _rendererReady = true);
    } catch (e) {
      debugPrint('[WebRTC] Renderer init error: $e');
      // Don't crash — the status overlay will show a useful state.
    }
  }

  void _onStatusChanged() {
    if (_stream.status.value == StreamStatus.connected &&
        _stream.remoteStream != null) {
      _renderer.srcObject = _stream.remoteStream;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stream.status.removeListener(_onStatusChanged);
    _stream.dispose();
    _renderer.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ?? AppColors.darkTokens;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Fullscreen video ──
          if (_rendererReady)
            RTCVideoView(
              _renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),

          // ── Layer 2: Status overlay (when not connected) ──
          _buildStatusOverlay(),

          // ── Layer 3: Top bar (title + buttons) ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(tokens),
          ),

          // ── Layer 4: HUD (bottom-center) ──
          if (_showHud) _buildHud(),

          // ── Layer 5: Joysticks (bottom corners) ──
          Positioned(
            left: 24, bottom: 24,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              JoystickWidget(size: 130, onMove: (dx, dy) {
                debugPrint('Move: ${dx.toStringAsFixed(2)}, ${dy.toStringAsFixed(2)}');
              }),
              const SizedBox(height: 4),
              Text('MOVE', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 2)),
            ]),
          ),
          Positioned(
            right: 24, bottom: 24,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              JoystickWidget(size: 130, onMove: (dx, dy) {
                debugPrint('Look: ${dx.toStringAsFixed(2)}, ${dy.toStringAsFixed(2)}');
              }),
              const SizedBox(height: 4),
              Text('LOOK', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 2)),
            ]),
          ),

          // ── Layer 6: Connection controls panel (expandable) ──
          if (_showControls) _buildControlsPanel(tokens),
        ],
      ),
    );
  }

  // ─────────────── Top Bar ───────────────

  Widget _buildTopBar(AppColorTokens tokens) {
    final st = _stream.status.value;
    final isLive = st == StreamStatus.connected;
    final statusColor = switch (st) {
      StreamStatus.connected => const Color(0xFF4CAF50),
      StreamStatus.connecting || StreamStatus.reconnecting => const Color(0xFFFFB74D),
      StreamStatus.error => const Color(0xFFFF5252),
      _ => Colors.white38,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          // Back button to exit robot view
          _iconBtn(Icons.arrow_back_rounded, () {
            widget.onExit?.call();
          }),
          const SizedBox(width: 10),
          // Status dot + title
          Container(width: 8, height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 6)])),
          const SizedBox(width: 8),
          Text('Robot Control', style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(isLive ? 'LIVE' : st.name.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),

          const Spacer(),

          // Connect / Disconnect button
          GestureDetector(
            onTap: () {
              if (isLive || st == StreamStatus.connecting || st == StreamStatus.reconnecting) {
                _stream.disconnect();
              } else {
                _stream.connect(_urlCtrl.text);
              }
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isLive
                  ? [const Color(0xFFD32F2F), const Color(0xFFFF5252)]
                  : [const Color(0xFF1565C0), const Color(0xFF42A5F5)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isLive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(isLive ? 'Stop' : 'Connect',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),

          // Settings (URL editor)
          _iconBtn(Icons.settings_rounded, () {
            setState(() => _showControls = !_showControls);
          }),
          const SizedBox(width: 4),

          // HUD toggle
          _iconBtn(
            _showHud ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            () => setState(() => _showHud = !_showHud),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }

  // ─────────────── Status Overlay ───────────────

  Widget _buildStatusOverlay() {
    final st = _stream.status.value;
    if (st == StreamStatus.disconnected) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.videocam_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 14),
        Text('Tap Connect to start', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
      ]));
    }
    if (st == StreamStatus.connecting) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 36, height: 36,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4FAEFF))),
        SizedBox(height: 14),
        Text('Connecting via WHEP…', style: TextStyle(color: Colors.white70, fontSize: 13)),
      ]));
    }
    if (st == StreamStatus.reconnecting) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
        SizedBox(height: 10),
        Text('Reconnecting…', style: TextStyle(color: Colors.amber, fontSize: 12)),
      ]));
    }
    if (st == StreamStatus.error) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFFF5252)),
        const SizedBox(height: 8),
        Text(_stream.errorMessage.value ?? 'Connection error',
          textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Will retry…', style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]));
    }
    return const SizedBox.shrink();
  }

  // ─────────────── HUD ───────────────

  Widget _buildHud() {
    return Positioned(
      bottom: 12, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
          child: Text(
            'WebRTC · WHEP · ${_stream.currentUrl}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ─────────────── Controls Panel ───────────────

  Widget _buildControlsPanel(AppColorTokens tokens) {
    return Positioned(
      top: 60, right: 16,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Stream URL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _urlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true,
                hintText: 'http://host:8889/stream/whep',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded, size: 14, color: Colors.white38),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) _urlCtrl.text = data!.text!;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                _stream.connect(_urlCtrl.text);
                setState(() => _showControls = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                  borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text('Apply & Connect',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
