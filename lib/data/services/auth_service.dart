import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  // Email/password registration
  static Future<String?> signUp({
    required String nic,
    required String username,
    required String email,
    required String contact,
    required String password,
    String? photoUrl,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'nic': nic,
        'username': username,
        'email': email,
        'contact': contact,
        'photoUrl': photoUrl ?? '',
        'role': 'user',
        'auth_provider': 'email',
        'created_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      print('FIREBASE_AUTH_ERROR: ${e.code} - ${e.message}');
      return e.message;
    } catch (e, stack) {
      print('SIGN UP ERROR: $e');
      print('STACKTRACE: $stack');
      return "Registration failed. Please try again.";
    }
  }

  // Email/password login
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Google sign in
  static Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Google sign in cancelled';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential cred = await _auth.signInWithCredential(credential);

      final userDoc = _firestore.collection('users').doc(cred.user!.uid);
      if (!(await userDoc.get()).exists) {
        await userDoc.set({
          'uid': cred.user!.uid,
          'nic': '',
          'username': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'contact': '',
          'created_at': FieldValue.serverTimestamp(),
          'auth_provider': 'google',
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Apple sign in (iOS only)
  static Future<String?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      UserCredential cred = await _auth.signInWithCredential(oauthCredential);

      final userDoc = _firestore.collection('users').doc(cred.user!.uid);
      if (!(await userDoc.get()).exists) {
        await userDoc.set({
          'uid': cred.user!.uid,
          'nic': '',
          'username': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'contact': '',
          'created_at': FieldValue.serverTimestamp(),
          'auth_provider': 'apple',
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Send email link for passwordless login
  static Future<String?> sendSignInLink(String email) async {
    try {
      ActionCodeSettings acs = ActionCodeSettings(
        url: 'https://eco-ev-app.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.yourcompany.eco_ev_app',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );
      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Complete sign-in with email link
  static Future<String?> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    try {
      await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Send password reset email
  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Logout
  static Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Save user profile
  static Future<void> saveUserProfile({
    required String uid,
    required String nic,
    required String username,
    required String email,
    required String contact,
    String? photoUrl,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'nic': nic,
      'username': username,
      'email': email,
      'contact': contact,
      'photoUrl': photoUrl ?? '',
      'role': 'user',
      'auth_provider': 'email',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<String?> getCurrentUid() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  static Future<void> updatePhotoUrl(String uid, String url) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'photoUrl': url,
    });
  }
}

