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

      final bool isNewAuth =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      try {
        // 1. Cek langsung dengan UID Firebase Auth
        final userDoc =
            await _firestore.collection('user').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          data['id'] = userDoc.id;
          if (isNewAuth || data['has_password'] != true) {
            data['has_password'] = false;
            data['is_new_user'] = true;
          }
          return data;
        }

        // 2. Cek apakah akun email ini sudah terdaftar di koleksi 'user' Firestore
        final cleanEmail = (user.email ?? '').trim().toLowerCase();
        final querySnapshot = await _firestore
            .collection('user')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // User sudah terdaftar sebelumnya di database Firestore
          final existingDoc = querySnapshot.docs.first;
          final data = existingDoc.data();
          data['id'] = existingDoc.id;
          if (isNewAuth || data['has_password'] != true) {
            data['has_password'] = false;
            data['is_new_user'] = true;
          }
          return data;
        } else {
          // Pengguna baru pertama kali login Google -> Daftarkan otomatis ke Firestore
          final newUserData = <String, dynamic>{
            'nama_lengkap': user.displayName ?? 'Pengguna Google',
            'email': cleanEmail,
            'no_telepon': user.phoneNumber ?? '',
            'role': 'Kasir', // Role default untuk user baru
            'status': true,
            'has_password': false, // Wajib false untuk akun baru
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          };

          // Simpan dokumen baru dengan UID Firebase Auth sebagai document ID
          await _firestore.collection('user').doc(user.uid).set(newUserData);
          newUserData['id'] = user.uid;
          newUserData['has_password'] = false;
          newUserData['is_new_user'] = true;
          return newUserData;
        }
      } catch (firestoreError) {
        // Fallback jika Firestore terkendala
        return <String, dynamic>{
          'id': user.uid,
          'nama_lengkap': user.displayName ?? 'Pengguna Google',
          'email': (user.email ?? '').trim().toLowerCase(),
          'no_telepon': user.phoneNumber ?? '',
          'role': 'Kasir',
          'status': true,
          'has_password': false,
          'is_new_user': true,
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

    final cleanName = namaLengkap.trim();
    final cleanEmail = (user.email ?? email.trim()).toLowerCase();
    try {
      await user.updateDisplayName(cleanName);
    } catch (_) {}

    // Simpan ke Firestore di koleksi 'user'
    final userData = <String, dynamic>{
      'nama_lengkap': cleanName,
      'email': cleanEmail,
      'no_telepon': noTelepon.trim(),
      'role': role,
      'status': true,
      'has_password': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('user').doc(user.uid).set(userData);
    userData['id'] = user.uid;
    return userData;
  }

  /// HELPER: Ambil data profil user dari Firestore berdasarkan email
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final querySnapshot = await _firestore
        .collection('user')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }

    // Coba juga tanpa toLowerCase jika sebelumnya tersimpan dengan case berbeda
    final queryOriginal = await _firestore
        .collection('user')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (queryOriginal.docs.isNotEmpty) {
      final doc = queryOriginal.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }

    return null;
  }

  /// HELPER: Ambil profil user saat ini (via UID atau Email)
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // 1. Cek langsung lewat UID
    try {
      final doc = await _firestore.collection('user').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
    } catch (_) {}

    // 2. Cek lewat email
    if (user.email != null && user.email!.isNotEmpty) {
      return await getUserProfileByEmail(user.email!);
    }

    return null;
  }

  /// Cek apakah akun saat ini sudah memiliki password
  Future<bool> userHasPassword() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // 1. Cek apakah provider 'password' sudah terdaftar di Firebase Auth
    final hasProvider =
        user.providerData.any((p) => p.providerId == 'password');
    if (hasProvider) return true;

    // 2. Cek di dokumen Firestore berdasarkan UID
    try {
      final userDoc = await _firestore.collection('user').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data['has_password'] == true) return true;
        if (data['has_password'] == false) return false;
      }
    } catch (e) {
      debugPrint('Error checking user doc for password: $e');
    }

    // 3. Fallback cek di dokumen Firestore berdasarkan email
    try {
      final profile = await getUserProfileByEmail(user.email ?? '');
      return profile?['has_password'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 4. SET / UPDATE PASSWORD UNTUK AKUN LOGIN GOOGLE / NATIVE
  Future<void> setAccountPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Pengguna tidak sedang login');
    }

    // 1. Daftarkan / perbarui password di Firebase Auth jika memungkinkan
    final hasProvider =
        user.providerData.any((p) => p.providerId == 'password');

    try {
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
            try {
              await user.updatePassword(newPassword);
            } catch (_) {}
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth password update notice: [${e.code}] ${e.message}');
    } catch (e) {
      debugPrint('Password update exception: $e');
    }

    // 2. Simpan status ke Firestore (password hanya disimpan aman di Firebase Auth, bukan Firestore)
    final updateData = <String, dynamic>{
      'has_password': true,
      'password': FieldValue.delete(), // Hapus field password plain-text jika sebelumnya ada
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Update dokumen dengan ID UID
    await _firestore
        .collection('user')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));

    // Update juga dokumen dengan query email jika ada dokumen terpisah
    final querySnapshot = await _firestore
        .collection('user')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.set(
        updateData,
        SetOptions(merge: true),
      );
    } else {
      await _firestore.collection('user').doc(user.uid).set({
        'nama_lengkap': user.displayName ?? 'Pengguna',
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

  /// 5. UPDATE DATA PROFIL USER (Nama Lengkap, No Telepon)
  Future<void> updateUserProfile({
    required String namaLengkap,
    String? noTelepon,
  }) async {
    final user = _auth.currentUser;
    final cleanName = namaLengkap.trim();

    if (user != null) {
      try {
        await user.updateDisplayName(cleanName);
      } catch (_) {}
    }

    final updateData = <String, dynamic>{
      'nama_lengkap': cleanName,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (noTelepon != null) {
      updateData['no_telepon'] = noTelepon.trim();
    }

    if (user != null) {
      await _firestore
          .collection('user')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      if (user.email != null && user.email!.isNotEmpty) {
        final querySnapshot = await _firestore
            .collection('user')
            .where('email', isEqualTo: user.email)
            .get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.set(updateData, SetOptions(merge: true));
        }
      }
    }
  }

  /// 5b. UPDATE EMAIL USER DI FIREBASE AUTH & FIRESTORE
  Future<void> updateUserEmail(String newEmail) async {
    final user = _auth.currentUser;
    final cleanEmail = newEmail.trim().toLowerCase();
    final oldEmail = user?.email;

    if (user != null) {
      try {
        await user.verifyBeforeUpdateEmail(cleanEmail);
      } catch (e) {
        debugPrint('Notice on verifyBeforeUpdateEmail: $e');
      }
    }

    final updateData = <String, dynamic>{
      'email': cleanEmail,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (user != null) {
      await _firestore
          .collection('user')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
    }

    if (oldEmail != null && oldEmail.isNotEmpty) {
      final querySnapshot = await _firestore
          .collection('user')
          .where('email', isEqualTo: oldEmail)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.set(updateData, SetOptions(merge: true));
      }
    }
  }

  /// 6. STREAM DAFTAR SEMUA USER DARI FIRESTORE
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _firestore.collection('user').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 7. TAMBAHKAN USER BARU KE FIRESTORE
  Future<void> addNewUser({
    required String namaLengkap,
    required String email,
    String role = 'Kasir',
    String? password,
    String? noTelepon,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = namaLengkap.trim();

    final newUserData = <String, dynamic>{
      'nama_lengkap': cleanName,
      'email': cleanEmail,
      'role': role,
      'no_telepon': (noTelepon ?? '').trim(),
      'status': true,
      'has_password': password != null && password.isNotEmpty,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('user').add(newUserData);
  }

  /// 8. UPDATE USER DI FIRESTORE BERDASARKAN DOC ID
  Future<void> updateUser({
    required String docId,
    required String namaLengkap,
    required String email,
    String? role,
    String? noTelepon,
  }) async {
    final updateData = <String, dynamic>{
      'nama_lengkap': namaLengkap.trim(),
      'email': email.trim().toLowerCase(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (role != null) {
      updateData['role'] = role;
    }
    if (noTelepon != null) {
      updateData['no_telepon'] = noTelepon.trim();
    }

    await _firestore.collection('user').doc(docId).set(
      updateData,
      SetOptions(merge: true),
    );
  }

  /// 9. HAPUS USER DI FIRESTORE BERDASARKAN DOC ID
  Future<void> deleteUser(String docId) async {
    await _firestore.collection('user').doc(docId).delete();
  }

  /// 10. LOGOUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
