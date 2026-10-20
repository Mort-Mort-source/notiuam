import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    hostedDomain: 'cua.uam.mx',
    // Este es el Client ID de tipo 3 (Web) de tu archivo
    serverClientId: '584002587099-4f11cuec4p8divavhmsm7j7n3ss15te0.apps.googleusercontent.com',
  );

  static Future<String?> signInAndGetIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}