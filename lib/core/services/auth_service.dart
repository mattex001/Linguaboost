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
  })  : _client = client ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(serverClientId: SupabaseConfig.googleWebClientId),
        _userRepository = userRepository ?? UserRepository();

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  bool get isSignedIn => _client.auth.currentSession != null;

  // ── Send OTP ───────────────────────────────────────────────────────────────
  // Supabase Auth emails a 6-digit code (Email OTP must be enabled and the
  // template must contain {{ .Token }}). Throws [AuthException] on failure.

  Future<void> sendOtp(String email) => _client.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
      );

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  // Validates the OTP, signs the user in, and returns the profile row plus
  // whether this account still needs onboarding.

  Future<({UserModel user, bool isNewUser})> signInWithEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: otp.trim(),
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException('Verification failed');
    }

    return _postSignIn(authUser, email: email.trim());
  }

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
    final profile = await _userRepository.getUser(authUser.id) ??
        UserModel(id: authUser.id, email: email);

    final isNewUser = profile.onboardingStep == 0;
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
