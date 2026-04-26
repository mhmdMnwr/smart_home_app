import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A modern floating action button for voice commands.
///
/// **Idle** – sits at the bottom-left with a pulsing blue glow.
/// **Listening** – animates to the horizontal centre and expands into a
/// pill-shaped overlay with animated sound-wave bars.
///
/// Currently **UI-only** — no speech-recognition logic is wired up.
class VoiceCommandFab extends StatefulWidget {
  const VoiceCommandFab({super.key});

  @override
  State<VoiceCommandFab> createState() => _VoiceCommandFabState();
}

class _VoiceCommandFabState extends State<VoiceCommandFab>
    with TickerProviderStateMixin {
  bool _isListening = false;

  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final AnimationController _expandController;

  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    // Idle pulsing ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Sound-wave bars while listening
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Expand / collapse + position transition
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _expandController.forward();
      _waveController.repeat();
    } else {
      _expandController.reverse();
      _waveController.stop();
      _waveController.reset();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, _) {
        final double t = _expandAnimation.value;

        // Animate alignment: bottom-left ➜ bottom-center
        // Y = 0.68 keeps the widget above the floating nav bar
        final Alignment alignment = Alignment.lerp(
          const Alignment(-0.85, 0.68),
          const Alignment(0.0, 0.68),
          t,
        )!;

        return Align(
          alignment: alignment,
          child: t > 0.01
              ? _buildExpandedOverlay(t)
              : _buildIdleFab(),
        );
      },
    );
  }

  // ── Idle FAB ─────────────────────────────────────────────────────────

  Widget _buildIdleFab() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulse =
            0.5 + 0.5 * math.sin(_pulseController.value * 2 * math.pi);

        return GestureDetector(
          onTap: _toggleListening,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF1F78FF),
                  Color(0xFF3D8FFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                // Outer pulsing glow
                BoxShadow(
                  color: const Color(0xFF1F78FF)
                      .withValues(alpha: 0.25 + 0.15 * pulse),
                  blurRadius: 18 + 8 * pulse,
                  spreadRadius: 2 + 4 * pulse,
                ),
                // Deeper shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.mic_none_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Expanded listening overlay ───────────────────────────────────────

  Widget _buildExpandedOverlay(double t) {
    return GestureDetector(
      onTap: _toggleListening,
      child: Container(
        width: 60 + 140 * t,
        height: 60 + 80 * t,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30 + 4 * t),
          gradient: LinearGradient(
            colors: <Color>[
              const Color(0xFF0E2A5A).withValues(alpha: 0.95),
              const Color(0xFF153B7A).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF1F78FF).withValues(alpha: 0.3),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF1F78FF).withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top row: mic icon + label
            Opacity(
              opacity: t,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F78FF).withValues(alpha: 0.25),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF64B5F6),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Listening…',
                    style: TextStyle(
                      color: Color(0xFFD4E4FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10 * t),
            // Animated sound-wave bars
            Opacity(
              opacity: t,
              child: SizedBox(
                height: 28,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (i) {
                        final double phase =
                            _waveController.value * 2 * math.pi + i * 0.9;
                        final double height =
                            8 + 16 * ((math.sin(phase) + 1) / 2);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 4,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF1F78FF),
                                Color(0xFF64B5F6),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF1F78FF)
                                    .withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
