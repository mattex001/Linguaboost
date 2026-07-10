import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// A glowing, gently floating microphone button — a blurred aurora halo
/// (purple → blue → teal) behind a solid dark core with an animated
/// sound-bar icon.
///
/// Idle: slow breathing glow + a soft float. Listening: faster pulse +
/// energetic bars, so the button visibly comes alive without needing real
/// microphone amplitude data. Pass `onTap: null` to disable (e.g. while a
/// request is loading).
///
/// Two interaction modes:
/// - Default (`growOnPress: false`): plain tap via [onTap], shrinks slightly
///   on press for tactile feedback (e.g. the dashboard's quick-capture card,
///   which just navigates rather than recording anything itself).
/// - Press-and-hold (`growOnPress: true`): [onHoldStart] fires on press-down
///   (with a haptic buzz) and [onHoldEnd] fires on release, growing instead
///   of shrinking while held — the voice-message mental model.
class GlowMicButton extends StatefulWidget {
  final bool listening;
  final VoidCallback? onTap;
  final double size;
  final bool growOnPress;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;

  const GlowMicButton({
    super.key,
    required this.listening,
    required this.onTap,
    this.size = 64,
    this.growOnPress = false,
    this.onHoldStart,
    this.onHoldEnd,
  });

  @override
  State<GlowMicButton> createState() => _GlowMicButtonState();
}

class _GlowMicButtonState extends State<GlowMicButton> {
  bool _pressed = false;

  static const _haloLavender = Color(0xFFB794F6);
  static const _haloBlue = Color(0xFF60A5FA);
  static const _haloTeal = Color(0xFF5EEAD4);

  @override
  Widget build(BuildContext context) {
    final listening = widget.listening;
    final size = widget.size;
    final enabled =
        widget.growOnPress ? widget.onHoldStart != null : widget.onTap != null;

    final floatDuration = listening ? 1400.ms : 2600.ms;
    final floatRange = listening ? 5.0 : 3.5;
    final pulseDuration = listening ? 700.ms : 1400.ms;
    final pulseMin = listening ? 0.9 : 0.94;
    final pulseMax = listening ? 1.2 : 1.1;
    final rimRotateDuration = listening ? 2000.ms : 4500.ms;

    // Press-and-hold uses a raw Listener rather than GestureDetector taps:
    // tap recognizers compete in the gesture arena with the surrounding
    // scroll view, so finger drift beyond the touch slop while holding
    // (inevitable when speaking for a few seconds) would fire onTapCancel
    // and cut the recording mid-sentence. Raw pointer events can't be
    // stolen by the scroll arena.
    final Widget Function(Widget child) wrapGesture;
    if (widget.growOnPress) {
      wrapGesture = (child) => Listener(
            onPointerDown: enabled
                ? (_) {
                    HapticFeedback.mediumImpact();
                    widget.onHoldStart?.call();
                    setState(() => _pressed = true);
                  }
                : null,
            onPointerUp: enabled
                ? (_) {
                    widget.onHoldEnd?.call();
                    setState(() => _pressed = false);
                  }
                : null,
            onPointerCancel: enabled
                ? (_) {
                    widget.onHoldEnd?.call();
                    setState(() => _pressed = false);
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: child,
          );
    } else {
      wrapGesture = (child) => GestureDetector(
            onTap: widget.onTap,
            onTapDown:
                enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                enabled ? () => setState(() => _pressed = false) : null,
            behavior: HitTestBehavior.opaque,
            child: child,
          );
    }

    final button = wrapGesture(AnimatedScale(
        scale: _pressed ? (widget.growOnPress ? 1.18 : 0.88) : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: SizedBox(
            width: size * 2,
            height: size * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer blurred aurora halo — breathes continuously.
                KeyedSubtree(
                  key: ValueKey('halo-$listening'),
                  child:
                      ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 16,
                              sigmaY: 16,
                            ),
                            child: Container(
                              width: size * 1.9,
                              height: size * 1.9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.brandPrimary.withValues(
                                      alpha: 0.85,
                                    ),
                                    _haloLavender.withValues(alpha: 0.55),
                                    _haloTeal.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: pulseMin,
                            end: pulseMax,
                            duration: pulseDuration,
                            curve: Curves.easeInOut,
                          )
                          .fadeIn(
                            begin: 0.75,
                            duration: pulseDuration,
                            curve: Curves.easeInOut,
                          ),
                ),

                // Crisp gradient rim — the purple/blue/teal ring, always
                // spinning so the glow visibly reads as "alive" even at rest.
                Container(
                      width: size * 1.32,
                      height: size * 1.32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.brandPrimary,
                            _haloBlue,
                            _haloTeal,
                            AppColors.brandPrimary,
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(
                      begin: 0,
                      end: 1,
                      duration: rimRotateDuration,
                      curve: Curves.linear,
                    ),

                // Dark core with the animated sound-bar icon.
                Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF141413),
                  ),
                  child: Center(
                    child: _SoundBars(active: listening, size: size),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Float applies to the whole button (including press-scale) so the
    // entire control gently bobs, not just its innards.
    return KeyedSubtree(
      key: ValueKey('float-$listening'),
      child: button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -floatRange / 2,
            end: floatRange / 2,
            duration: floatDuration,
            curve: Curves.easeInOut,
          ),
    );
  }
}

// ── Compact animated sound-bar icon ───────────────────────────────────────────

class _SoundBars extends StatelessWidget {
  final bool active;
  final double size;
  const _SoundBars({required this.active, required this.size});

  static const _relativeHeights = [0.35, 0.65, 1.0, 0.65, 0.35];

  @override
  Widget build(BuildContext context) {
    final barMaxHeight = size * 0.42;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_relativeHeights.length, (i) {
        final bar = Container(
          width: size * 0.07,
          height: barMaxHeight * _relativeHeights[i],
          margin: EdgeInsets.symmetric(horizontal: size * 0.035),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.04),
          ),
        );
        if (!active) return bar;
        return bar
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: Duration(milliseconds: i * 90),
            )
            .scaleY(
              begin: 0.5,
              end: 1.15,
              duration: 450.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}
