import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/user_model.dart';
import '../../shared/repositories/user_repository.dart';
import '../config/supabase_config.dart';
import 'local_storage_service.dart';
import 'purchase_service.dart';

class AuthService {
  AuthService({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  }) : _client = client ?? Supabase.instance.client,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(serverClientId: SupabaseConfig.googleWebClientId),
       _userRepository = userRepository ?? UserRepository();

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  bool get isSignedIn => _client.auth.currentSession != null;

  // ── Email + Password ──────────────────────────────────────────────────────

  Future<({UserModel user, bool isNewUser})> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final response = await _client.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Login failed');
    }

    return _postSignIn(authUser, email: authUser.email ?? normalizedEmail);
  }

  /// Creates the account. When email confirmation is required (the normal
  /// first-time path), no session is returned yet — the caller must send the
  /// user to the OTP screen to verify the 6-digit code from the confirmation
  /// email ([verifySignupOtp]).
  Future<({UserModel? user, bool isNewUser, bool needsVerification})>
      signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Sign up failed');
    }

    // Existing confirmed accounts get an obfuscated "pending" response with
    // no identities and NO email is sent — don't strand the user on the OTP
    // screen waiting for one.
    if (authUser.identities?.isEmpty ?? true) {
      throw const AuthException(
        'An account with this email already exists. Log in with your password instead.',
      );
    }

    if (response.session == null) {
      // Email confirmation pending — Supabase has emailed the OTP code.
      return (user: null, isNewUser: true, needsVerification: true);
    }

    final result =
        await _postSignIn(authUser, email: authUser.email ?? normalizedEmail);
    return (
      user: result.user,
      isNewUser: result.isNewUser,
      needsVerification: false,
    );
  }

  // ── Signup OTP verification ────────────────────────────────────────────────
  // Confirms a new account with the 6-digit code from the confirmation email
  // (the template must contain {{ .Token }}). Returns a signed-in session.

  Future<({UserModel user, bool isNewUser})> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: otp.trim(),
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Verification failed');
    }

    return _postSignIn(authUser, email: email.trim());
  }

  /// Re-sends the signup confirmation code.
  Future<void> resendSignupOtp(String email) =>
      _client.auth.resend(type: OtpType.signup, email: email.trim());

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<({UserModel user, bool isNewUser})> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in was cancelled.');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign-in returned no ID token.');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Google sign-in failed');
    }

    return _postSignIn(authUser, email: googleUser.email);
  }

  Future<({UserModel user, bool isNewUser})> _postSignIn(
    User authUser, {
    required String email,
  }) async {
    await LocalStorageService.instance.setUserId(authUser.id);
    await PurchaseService.instance.logIn(authUser.id);

    // Profile row is auto-created by the on_auth_user_created trigger; it may
    // lag the very first sign-in by a moment.
    final profile =
        await _userRepository.getUser(authUser.id) ??
        UserModel(id: authUser.id, email: email);

    // Sync the device-local onboarding flag from the server profile. The
    // local flag alone can't be trusted: SharedPreferences survive app
    // upgrades (including from the pre-pivot app), which would skip
    // onboarding for accounts that never completed it.
    final onboarded = profile.targetLanguage != null;
    if (onboarded) {
      await LocalStorageService.instance.setOnboardingComplete();
    } else {
      await LocalStorageService.instance.clearOnboardingComplete();
    }

    final isNewUser = !onboarded;
    return (user: profile, isNewUser: isNewUser);
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _client.auth.signOut();
    await PurchaseService.instance.logOut();
    await LocalStorageService.instance.clear();
  }

  // ── Delete account ─────────────────────────────────────────────────────────
  // Auth users can't delete themselves client-side; the delete-account Edge
  // Function does it with the service role. Profile + phrases cascade.

  Future<void> deleteAccount() async {
    if (currentUser == null) return;
    await _client.functions.invoke('delete-account');
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Session is already invalid after the server-side delete.
    }
    await LocalStorageService.instance.clear();
  }
}
