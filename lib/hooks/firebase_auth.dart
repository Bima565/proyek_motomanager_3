import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  // Web Client ID dari Google Cloud / Firebase Console
  static const String serverClientId =
      '596413030925-2g8q20qtp7r15i3p0qvokec2rorfi6su.apps.googleusercontent.com';

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _googleSignIn.initialize(
        serverClientId: serverClientId,
      );
      _isGoogleSignInInitialized = true;
    }
  }

  // User Firebase Auth yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 1. LOGIN MENGGUNAKAN EMAIL & PASSWORD
  Future<Map<String, dynamic>?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Autentikasi dengan Firebase Auth
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;
    if (user == null) return null;

    // Ambil data profil & role pengguna dari koleksi 'user' di Firestore
    return await getUserProfileByEmail(user.email ?? email.trim());
  }

  /// 2. LOGIN / REGISTER MENGGUNAKAN GOOGLE
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // Membuka popup autentikasi Google (Credential Manager / Google Identity)
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      // Masuk ke Firebase Auth menggunakan kredensial Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      // Cek apakah akun email ini sudah terdaftar di koleksi 'user' Firestore
      final querySnapshot = await _firestore
          .collection('user')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // User sudah terdaftar sebelumnya di database Firestore
        final existingDoc = querySnapshot.docs.first;
        final data = existingDoc.data();
        data['id'] = existingDoc.id;
        return data;
      } else {
        // Pengguna baru pertama kali login Google -> Daftarkan otomatis ke Firestore
        final newUserData = <String, dynamic>{
          'nama_lengkap': user.displayName ?? 'Pengguna Google',
          'email': user.email ?? '',
          'no_telepon': user.phoneNumber ?? '',
          'role': 'Kasir', // Role default untuk user baru
          'status': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        // Simpan dokumen baru dengan UID Firebase Auth sebagai document ID
        await _firestore.collection('user').doc(user.uid).set(newUserData);
        newUserData['id'] = user.uid;
        return newUserData;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Dibatalkan oleh pengguna
        return null;
      }
      rethrow;
    }
  }

  /// 3. REGISTER MENGGUNAKAN EMAIL & PASSWORD
  Future<Map<String, dynamic>?> registerWithEmailPassword({
    required String email,
    required String password,
    required String namaLengkap,
    required String noTelepon,
    String role = 'Kasir',
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;
    if (user == null) return null;

    // Simpan ke Firestore di koleksi 'user'
    final userData = <String, dynamic>{
      'nama_lengkap': namaLengkap,
      'email': user.email ?? email.trim(),
      'no_telepon': noTelepon,
      'role': role,
      'status': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('user').doc(user.uid).set(userData);
    userData['id'] = user.uid;
    return userData;
  }

  /// HELPER: Ambil data profil user dari Firestore berdasarkan email
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final querySnapshot = await _firestore
        .collection('user')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  /// 4. LOGOUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
