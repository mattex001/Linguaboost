import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';

/// Final step of password reset: the recovery code has just been verified
/// (see [OtpPurpose.passwordReset] in otp_screen.dart), so the Supabase
/// client already holds a session scoped to changing the password.
class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const NewPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
    _confirmController.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _passwordController.text.length >= 8 && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final password = _passwordController.text;
    if (password != _confirmController.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(authServiceProvider)
          .updatePasswordAfterReset(password);
      if (!mounted) return;
      if (result.isNewUser) {
        context.go(AppRoutes.personalization);
      } else {
        final complete = LocalStorageService.instance.onboardingComplete;
        context.go(complete ? AppRoutes.dashboard : AppRoutes.personalization);
      }
    } catch (_) {
      setState(() => _error = 'Could not update your password. Try again.');
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
                const SizedBox(height: 8),

                Text(
                  'Set a new password',
                  style: GoogleFonts.googleSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 25 / 24,
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 350.ms,
                    ),

                const SizedBox(height: 4),

                Text(
                  'Choose a new password for ${widget.email}',
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary(context),
                    height: 19.6 / 14,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

                const SizedBox(height: 40),

                _PasswordField(
                  controller: _passwordController,
                  label: 'New password',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),

                const SizedBox(height: 14),

                _PasswordField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  obscureText: _obscureConfirm,
                  onToggleVisibility: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmitted: _submit,
                ),

                const SizedBox(height: 8),

                Text(
                  'Must be at least 8 characters',
                  style: GoogleFonts.googleSans(
                    fontSize: 12,
                    color: AppColors.textTertiary(context),
                  ),
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

                Opacity(
                  opacity: (_canSubmit) ? 1.0 : 0.31,
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
                        onPressed: _canSubmit ? _submit : null,
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
                                'Update password',
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

// ── Password field ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    this.onSubmitted,
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
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      style: GoogleFonts.googleSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.googleSans(
          fontSize: 12,
          color: AppColors.textTertiary(context),
        ),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      ),
    );
  }
}
