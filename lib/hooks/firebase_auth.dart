import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _isGoogleSignInInitialized = false;
  static Future<void>? _initFuture;

  // Web Client ID dari Google Cloud / Firebase Console
  static const String serverClientId =
      '596413030925-2g8q20qtp7r15i3p0qvokec2rorfi6su.apps.googleusercontent.com';

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _googleSignIn.initialize(
      serverClientId: serverClientId,
    );
    await _initFuture;
    _isGoogleSignInInitialized = true;
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
    final cleanEmail = email.trim();

    // Login via Firebase Auth (aman & ter-hash di server Google)
    final UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final User? user = credential.user;
    if (user == null) return null;

    return await getUserProfileByEmail(user.email ?? cleanEmail);
  }

  /// 2. LOGIN / REGISTER MENGGUNAKAN GOOGLE
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // Membuka popup autentikasi Google (Credential Manager / Google Identity)
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      // Ambil accessToken jika tersedia sebagai fallback/pelengkap
      String? accessToken;
      try {
        final authClient = await account.authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = authClient?.accessToken;
      } catch (_) {}

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: accessToken,
      );

      // Masuk ke Firebase Auth menggunakan kredensial Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      try {
        // 1. Cek langsung dengan UID Firebase Auth
        final userDoc =
            await _firestore.collection('user').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          data['id'] = userDoc.id;
          return data;
        }

        // 2. Cek apakah akun email ini sudah terdaftar di koleksi 'user' Firestore
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
      } catch (firestoreError) {
        // Fallback jika Firestore terkendala, tetap izinkan login ke dashboard
        return <String, dynamic>{
          'id': user.uid,
          'nama_lengkap': user.displayName ?? 'Pengguna Google',
          'email': user.email ?? '',
          'no_telepon': user.phoneNumber ?? '',
          'role': 'Kasir',
          'status': true,
        };
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // Dibatalkan oleh pengguna
        return null;
      }
      debugPrint('GoogleSignInException [${e.code}]: ${e.description}');
      rethrow;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('canceled') || errStr.contains('cancelled')) {
        // Dibatalkan oleh pengguna
        return null;
      }
      debugPrint('AuthService.signInWithGoogle error: $e');
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

  /// Cek apakah akun saat ini sudah memiliki password
  Future<bool> userHasPassword() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Cek apakah provider 'password' sudah terdaftar di Firebase Auth
    final hasProvider =
        user.providerData.any((p) => p.providerId == 'password');
    if (hasProvider) return true;

    // Cek juga di dokumen Firestore
    final profile = await getUserProfileByEmail(user.email ?? '');
    return profile?['has_password'] == true;
  }

  /// 4. SET / UPDATE PASSWORD UNTUK AKUN LOGIN GOOGLE
  Future<void> setAccountPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Pengguna tidak sedang login');
    }

    // 1. Daftarkan / perbarui password di Firebase Auth
    final hasProvider =
        user.providerData.any((p) => p.providerId == 'password');

    if (hasProvider) {
      await user.updatePassword(newPassword);
    } else {
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPassword,
        );
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked' ||
            e.code == 'credential-already-in-use') {
          await user.updatePassword(newPassword);
        } else {
          // Fallback update password langsung
          await user.updatePassword(newPassword);
        }
      }
    }

    // 2. Simpan status bahwa user sudah punya password ke Firestore (tanpa menyimpan plaintext password)
    final querySnapshot = await _firestore
        .collection('user')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'has_password': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('user').doc(user.uid).set({
        'nama_lengkap': user.displayName ?? 'Pengguna Google',
        'email': user.email,
        'no_telepon': user.phoneNumber ?? '',
        'role': 'Kasir',
        'status': true,
        'has_password': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// 5. LOGOUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
