import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'goal_service.dart';
import 'settings_service.dart';
import 'split_service.dart';
import 'transaction_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Switches active storage and in-memory caches to the specified user
  static Future<void> switchUserSession(String? userId) async {
    final effectiveUserId = userId ?? 'guest';
    // Switch TransactionService first so active user ID is set before SplitService checks or credits balances
    await TransactionService.switchUser(effectiveUserId);
    await Future.wait([
      GoalService.switchUser(effectiveUserId),
      SplitService.switchUser(effectiveUserId),
      SettingsService.switchUser(effectiveUserId),
    ]);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        await switchUserSession(userCred.user!.uid);
        await SplitService.syncCurrentAuthUser();
      }
      return userCred;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await switchUserSession('guest');
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}