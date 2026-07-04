import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late Timer _timer;
  int _secondsLeft = 60;
  bool _canResend = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _complete => _otp.length == 6;

  void _onChanged(int index, String value) {
    // Clear error as soon as the user edits
    if (_error != null) setState(() => _error = null);

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Pasted or autofilled code — distribute across all boxes.
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final lastFilled = (digits.length.clamp(1, 6)) - 1;
      _focusNodes[lastFilled].requestFocus();
      setState(() {});
      if (digits.length >= 6) _verify();
      return;
    }

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────

  Future<void> _resend() async {
    if (!_canResend || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(authServiceProvider).resendSignupOtp(widget.email);
      if (!mounted) return;
      // Reset boxes
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      _startTimer();
    } on AuthException catch (_) {
      setState(() => _error = 'Could not send a new code. Check your connection.');
    } catch (_) {
      setState(() => _error = 'Could not resend code. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────

  Future<void> _verify() async {
    if (!_complete || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await ref.read(authServiceProvider).verifySignupOtp(
        email: widget.email,
        otp: _otp,
      );
      if (!mounted) return;

      if (result.isNewUser) {
        context.go(AppRoutes.personalization);
      } else {
        final complete = LocalStorageService.instance.onboardingComplete;
        context.go(complete ? AppRoutes.dashboard : AppRoutes.personalization);
      }
    } on AuthException catch (e) {
      setState(() => _error = _friendlyOtpError(e.code));
    } catch (_) {
      setState(() => _error = 'Verification failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyOtpError(String? code) {
    switch (code) {
      // Supabase returns otp_expired for both wrong and stale codes.
      case 'otp_expired':
        return 'Incorrect or expired code. Double-check the digits or tap "Resend code".';
      case 'otp_disabled':
        return 'Email codes are temporarily unavailable. Try again later.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'validation_failed':
        return 'Incorrect code. Please double-check and try again.';
      default:
        return 'Incorrect or expired code. Please try again or request a new one.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(1, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final hasError = _error != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () { if (context.canPop()) context.pop(); },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          CoolIcons.chevron_left,
                          size: 28,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Verify your email address',
                  style: GoogleFonts.googleSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 1.1,
                  ),
                ).animate().fadeIn(duration: 350.ms),

                const SizedBox(height: 8),

                RichText(
                  text: TextSpan(
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textTertiary(context),
                      height: 19.6 / 14,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the code we sent to '),
                      TextSpan(
                        text: widget.email,
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

                const SizedBox(height: 48),

                // ── OTP boxes ──────────────────────────────────────────────
                Row(
                  children: List.generate(6, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                        child: _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          hasError: hasError,
                          onChanged: (v) => _onChanged(i, v),
                          onKeyEvent: (e) => _onKeyEvent(i, e),
                        )
                            .animate(delay: (i * 50).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0, duration: 300.ms),
                      ),
                    );
                  }),
                ),

                // ── Inline error ───────────────────────────────────────────
                if (hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      color: AppColors.textDanger(context),
                    ),
                  ),
                ],

                const SizedBox(height: 25),

                // ── Resend ─────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: GoogleFonts.googleSans(
                          fontSize: 12,
                          color: AppColors.textTertiary(context)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_canResend)
                        Text(
                          '$minutes:$seconds',
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: (_canResend && !_loading) ? _resend : null,
                        child: Opacity(
                          opacity: (_canResend && !_loading) ? 1.0 : 0.4,
                          child: _loading && _canResend
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandPrimary,
                                  ),
                                )
                              : Text(
                                  'Resend code',
                                  style: GoogleFonts.googleSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ── Continue button ────────────────────────────────────────
                Opacity(
                  opacity: (_complete && !_loading) ? 1.0 : 0.31,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF141413),
                          offset: Offset(0, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 47,
                      child: ElevatedButton(
                        onPressed: (_complete && !_loading) ? _verify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.brandPrimary,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: GoogleFonts.googleSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        // Length 6 (not 1) so a pasted code reaches onChanged intact,
        // where it is distributed across the boxes.
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onChanged: onChanged,
        style: GoogleFonts.googleSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: hasError
              ? AppColors.textDanger(context)
              : AppColors.textPrimary(context),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasError
              ? AppColors.backgroundDanger(context)
              : AppColors.backgroundPrimary(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError
                  ? AppColors.borderDanger(context)
                  : AppColors.borderTertiary(context),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppColors.borderDanger(context) : AppColors.brandPrimary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
