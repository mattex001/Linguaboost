import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';

/// Step 1 of password reset: collect the email and trigger the 6-digit
/// recovery code. Supabase never reveals whether the address is registered,
/// so this step can't leak account existence either way.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _emailValid = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final valid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_emailController.text.trim());
    if (valid != _emailValid) setState(() => _emailValid = valid);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailValid || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(email);
      if (!mounted) return;
      context.push(
        AppRoutes.authResetOtp,
        extra: email,
      );
    } catch (_) {
      setState(
        () => _error = 'Could not send the code. Check your connection.',
      );
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
                  'Reset your password',
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
                  "Enter your email and we'll send you a code to reset it",
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary(context),
                    height: 19.6 / 14,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  autofocus: true,
                  onSubmitted: (_) => _sendCode(),
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
                      borderSide:
                          BorderSide(color: AppColors.borderDisabled(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                        width: 1.5,
                      ),
                    ),
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
                  opacity: (_emailValid && !_loading) ? 1.0 : 0.31,
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
                        onPressed:
                            (_emailValid && !_loading) ? _sendCode : null,
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
                                'Send code',
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
