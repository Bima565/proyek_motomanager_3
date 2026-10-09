import 'package:flutter/material.dart';
import '../hooks/firebase_auth.dart';
import 'login.dart';

class DasboardPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const DasboardPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    final String email = userData?['email'] ?? currentUser?.email ?? '-';
    final String username = userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Pengguna';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      appBar: AppBar(
        title: const Text('Dashboard Test'),
        backgroundColor: const Color(0xFF151821),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Username / Nama Lengkap
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Email Login
              Text(
                email,
                style: const TextStyle(
                  color: Color(0xFF8E95A2),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Tombol Logout
              SizedBox(
                width: 200,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2026),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
