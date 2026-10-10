import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../hooks/firebase_auth.dart';
import 'login.dart';

class DasboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const DasboardPage({super.key, this.userData});

  @override
  State<DasboardPage> createState() => _DasboardPageState();
}

class _DasboardPageState extends State<DasboardPage> {
  final AuthService _authService = AuthService();
  bool _hasPassword = false;
  bool _isCheckingPassword = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  void _checkPasswordStatus() async {
    final hasPass = await _authService.userHasPassword();
    if (mounted) {
      setState(() {
        _hasPassword = hasPass;
        _isCheckingPassword = false;
      });

      // Jika belum memiliki password native, otomatis tampilkan dialog buat password
      if (!hasPass) {
        final email = widget.userData?['email'] ??
            _authService.currentUser?.email ??
            '';
        if (email.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleChangePassword(email);
            }
          });
        }
      }
    }
  }

  void _handleChangePassword(String email) async {
    final result = await CreatePasswordDialog.show(
      context,
      email: email,
      isChangePassword: true,
    );

    if (result == true && mounted) {
      setState(() => _hasPassword = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF143322),
          content: Text('Password berhasil diperbarui!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    final String email = widget.userData?['email'] ?? currentUser?.email ?? '-';
    final String username = widget.userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Pengguna';
    final String role = widget.userData?['role'] ?? 'Kasir';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF151821),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF222634), width: 2),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFFF2026),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 6),

              // Email Login
              Text(
                email,
                style: const TextStyle(
                  color: Color(0xFF8E95A2),
                  fontSize: 14.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Badge Role
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x22FF2026),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF2026).withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Role: $role',
                  style: const TextStyle(
                    color: Color(0xFFFF2026),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status Password Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151821),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF222634)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCheckingPassword
                          ? Icons.hourglass_empty_rounded
                          : (_hasPassword
                              ? Icons.verified_user_rounded
                              : Icons.warning_amber_rounded),
                      size: 20,
                      color: _isCheckingPassword
                          ? const Color(0xFF8E95A2)
                          : (_hasPassword
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isCheckingPassword
                          ? 'Memeriksa status password...'
                          : (_hasPassword
                              ? 'Password Native: Aktif'
                              : 'Password Native: Belum Ada'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Buat / Ubah Password
              TextButton.icon(
                onPressed: () => _handleChangePassword(email),
                icon: const Icon(Icons.key_rounded, size: 16, color: Color(0xFFFF2026)),
                label: Text(
                  _hasPassword ? 'Ubah Password' : 'Buat Password Sekarang',
                  style: const TextStyle(
                    color: Color(0xFFFF2026),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Logout
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(initialEmail: email),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
