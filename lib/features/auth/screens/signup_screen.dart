import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _passwordObscured = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
  }

  bool get _canSubmit => _emailValid && _passwordValid && !_loading;

  void _onFormChanged() {
    final emailValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_emailController.text.trim());
    final passwordValid = _passwordController.text.length >= 8;
    if (emailValid != _emailValid || passwordValid != _passwordValid) {
      setState(() {
        _emailValid = emailValid;
        _passwordValid = passwordValid;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(authServiceProvider)
          .signUpWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (result.needsVerification) {
        // First-time signup: verify the emailed 6-digit code
        context.push(AppRoutes.authOtp, extra: _emailController.text.trim());
      } else if (result.isNewUser) {
        context.go(AppRoutes.personalization);
      } else {
        final complete = LocalStorageService.instance.onboardingComplete;
        context.go(complete ? AppRoutes.dashboard : AppRoutes.personalization);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign up failed. Check your details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      if (result.isNewUser) {
        context.go(AppRoutes.personalization);
      } else {
        final complete = LocalStorageService.instance.onboardingComplete;
        context.go(complete ? AppRoutes.dashboard : AppRoutes.personalization);
      }
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled')) {
        setState(() => _error = 'Google sign-in failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (context.canPop()) context.pop();
                    },
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
                      'Create your account',
                      style: GoogleFonts.googleSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 25 / 24,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, end: 0, duration: 350.ms),

                const SizedBox(height: 4),

                Text(
                  'Start saving phrases with your own login',
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary(context),
                    height: 19.6 / 14,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

                const SizedBox(height: 72),

                _GoogleButton(onTap: _signInWithGoogle, isLoading: _loading)
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0, duration: 350.ms),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.borderDisabled(context),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or continue with email',
                        style: GoogleFonts.googleSans(
                          fontSize: 12,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.borderDisabled(context),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Text(
                  'Use your email and create a password to continue',
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary(context),
                    height: 19.6 / 14,
                  ),
                ),

                const SizedBox(height: 25),

                _EmailInput(controller: _emailController),

                const SizedBox(height: 14),

                _PasswordInput(
                  controller: _passwordController,
                  obscureText: _passwordObscured,
                  onToggleVisibility: () {
                    setState(() => _passwordObscured = !_passwordObscured);
                  },
                  onSubmitted: _continue,
                ),

                if (_error != null) ...[
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

                _AuthButton(
                  label: 'Create account',
                  enabled: _canSubmit,
                  isLoading: _loading,
                  onTap: _continue,
                ),

                const SizedBox(height: 32),

                // ── Login link ─────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.authLogin),
                    behavior: HitTestBehavior.opaque,
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          color: AppColors.textTertiary(context),
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.googleSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
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

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _GoogleButton({required this.onTap, this.isLoading = false});

  static const _googleIconSvg = '''
<svg width="19" height="19" viewBox="0 0 19 19" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.7 9.72c0-.63-.06-1.24-.16-1.83H9.5v3.46h5.16a4.41 4.41 0 0 1-1.91 2.89v2.4h3.09c1.81-1.67 2.86-4.12 2.86-6.92z" fill="#4285F4"/>
  <path d="M9.5 19c2.59 0 4.76-.86 6.34-2.32l-3.09-2.4c-.86.57-1.95.91-3.25.91-2.5 0-4.62-1.69-5.38-3.96H.93v2.48A9.5 9.5 0 0 0 9.5 19z" fill="#34A853"/>
  <path d="M4.12 11.23A5.72 5.72 0 0 1 3.83 9.5c0-.6.1-1.18.29-1.73V5.29H.93A9.5 9.5 0 0 0 0 9.5c0 1.53.37 2.98 1.03 4.26l3.09-2.53z" fill="#FBBC05"/>
  <path d="M9.5 3.81c1.41 0 2.67.48 3.67 1.43l2.74-2.74C14.25.95 12.08 0 9.5 0A9.5 9.5 0 0 0 .93 5.29l3.19 2.48C4.88 5.5 7 3.81 9.5 3.81z" fill="#EA4335"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          height: 51,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary(context),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: AppColors.borderSecondary(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandPrimary,
                  ),
                )
              else
                SvgPicture.string(_googleIconSvg, width: 19, height: 19),
              const SizedBox(width: 10),
              Text(
                isLoading ? 'Signing in…' : 'Continue with Google',
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email input ───────────────────────────────────────────────────────────────

class _EmailInput extends StatelessWidget {
  final TextEditingController controller;
  const _EmailInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      style: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: 'Email address',
        labelStyle: GoogleFonts.googleSans(
          fontSize: 12,
          color: AppColors.textTertiary(context),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDisabled(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Password input ───────────────────────────────────────────────────────────

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmitted;

  const _PasswordInput({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => onSubmitted(),
      style: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.googleSans(
          fontSize: 12,
          color: AppColors.textTertiary(context),
        ),
        helperText: '8 characters minimum',
        helperStyle: GoogleFonts.googleSans(
          fontSize: 12,
          color: AppColors.textTertiary(context),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? CoolIcons.show : CoolIcons.hide,
            size: 20,
            color: AppColors.textTertiary(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDisabled(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Auth primary button ───────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.31,
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
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brandPrimary,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
