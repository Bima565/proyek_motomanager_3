import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../components/moto_bottom_nav.dart';
import '../hooks/firebase_auth.dart';
import 'dasboard.dart';
import 'login.dart';

class ProfilPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(int)? onNavigateTab;
  final bool showBottomNav;

  const ProfilPage({
    super.key,
    this.userData,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final AuthService _authService = AuthService();

  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF2A35);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);

  String? _customUsername;
  Map<String, dynamic>? _liveUserData;

  @override
  void initState() {
    super.initState();
    _loadLiveUserData();
  }

  void _loadLiveUserData() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _liveUserData = profile;
      });
    } else {
      final email =
          widget.userData?['email'] ?? _authService.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        final profileEmail = await _authService.getUserProfileByEmail(email);
        if (profileEmail != null && mounted) {
          setState(() {
            _liveUserData = profileEmail;
          });
        }
      }
    }
  }

  bool get _isSuperAdmin {
    final role = (_liveUserData?['role'] ?? widget.userData?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]'), '');
    return role == 'superadmin';
  }

  String _getUserInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  void _handleChangePassword(String email) async {
    final result = await CreatePasswordDialog.show(
      context,
      email: email,
      isChangePassword: true,
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF143322),
          content: Text('Kata sandi akun Anda berhasil diperbarui!'),
        ),
      );
    }
  }

  void _showChangeEmailDialog(String currentEmail) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: const Text('Ganti Email Akun',
              style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email Saat Ini', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                currentEmail,
                style: const TextStyle(color: textDim, fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text('Email Baru', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                style: const TextStyle(color: textWhite),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@motomanage.id',
                  hintStyle: const TextStyle(color: textDim),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final newEmail = emailController.text.trim();
                      if (newEmail.isEmpty || !newEmail.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF3B1517),
                            content: Text('Masukkan alamat email yang valid!'),
                          ),
                        );
                        return;
                      }

                      if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF3B1517),
                            content: Text('Email baru sama dengan email saat ini!'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        await _authService.updateUserEmail(newEmail);

                        if (mounted) {
                          setState(() {
                            if (_liveUserData != null) {
                              _liveUserData!['email'] = newEmail;
                            }
                            if (widget.userData != null) {
                              widget.userData!['email'] = newEmail;
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF143322),
                              content: Text('Email berhasil diperbarui di database Firebase!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF3B1517),
                              content: Text('Gagal memperbarui email: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan', style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      String currentName, String currentEmail, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: const Text('Ubah Data Diri',
              style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Lengkap', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nomor Telepon', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  hintText: 'Contoh: 081234567890',
                  hintStyle: const TextStyle(color: textDim),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Email', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                currentEmail,
                style: const TextStyle(color: textDim, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final newName = nameController.text.trim();
                      final newPhone = phoneController.text.trim();
                      if (newName.isEmpty) return;

                      setDialogState(() => isLoading = true);
                      try {
                        // Simpan perubahan ke Firestore & Firebase Auth
                        await _authService.updateUserProfile(
                          namaLengkap: newName,
                          noTelepon: newPhone,
                        );

                        if (mounted) {
                          setState(() {
                            _customUsername = newName;
                            if (_liveUserData != null) {
                              _liveUserData!['nama_lengkap'] = newName;
                              _liveUserData!['no_telepon'] = newPhone;
                            }
                            if (widget.userData != null) {
                              widget.userData!['nama_lengkap'] = newName;
                              widget.userData!['no_telepon'] = newPhone;
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF143322),
                              content: Text('Data profil berhasil disimpan di Firebase!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF3B1517),
                              content: Text('Gagal menyimpan profil: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan', style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Text('Konfirmasi Keluar',
            style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun MotoManage?',
          style: TextStyle(color: textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(initialEmail: email),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final String email = _liveUserData?['email'] ??
        widget.userData?['email'] ??
        currentUser?.email ??
        'sugeng@motomanage.id';
    final String username = _customUsername ??
        _liveUserData?['nama_lengkap'] ??
        widget.userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Pengguna';
    final String phone = (_liveUserData?['no_telepon'] ??
            widget.userData?['no_telepon'] ??
            currentUser?.phoneNumber ??
            '')
        .toString();
    final String role = (_liveUserData?['role'] ??
            widget.userData?['role'] ??
            'Kasir')
        .toString()
        .toUpperCase();
    final String initials = _getUserInitials(username);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Pengaturan & Akun)
              const Text(
                'Pengaturan & Akun',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola Profil & Pengguna Sistem',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // 2. Card Profil Utama (Inisial, Nama, Email, Role)
              _buildUserProfileCard(initials, username, email, role),
              const SizedBox(height: 24),

              // 3. Section Pengaturan Akun Mandiri
              const Text(
                'Pengaturan Akun Mandiri',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionMenuItem(
                title: 'Ubah Data Diri & Nomor Telepon',
                onTap: () => _showEditProfileDialog(username, email, phone),
              ),
              const SizedBox(height: 10),
              _buildActionMenuItem(
                title: 'Ganti Email Akun',
                onTap: () => _showChangeEmailDialog(email),
              ),
              const SizedBox(height: 10),
              _buildActionMenuItem(
                title: 'Ganti Kata Sandi (Password)',
                onTap: () => _handleChangePassword(email),
              ),
              const SizedBox(height: 10),
              _buildActionMenuItem(
                title: 'Status Keamanan & Akun (Dashboard)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DasboardPage(userData: widget.userData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 4. Card Pencadangan Data Basis Data
              _buildBackupCard(),
              const SizedBox(height: 24),

              // 5. Tombol Keluar Akun
              _buildLogoutButton(() => _handleLogout(email)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.showBottomNav == true)
          ? MotoBottomNav(
              currentIndex: _isSuperAdmin ? 5 : 4,
              userData: _liveUserData ?? widget.userData,
            )
          : null,
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildUserProfileCard(
    String initials,
    String username,
    String email,
    String role,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Lingkaran Avatar Merah
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgDark,
              border: Border.all(color: accentRed, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nama & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Badge SUPERADMIN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentRed, width: 1),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: accentRed,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              '›',
              style: TextStyle(
                color: textDim,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pencadangan Data Basis Data',
            style: TextStyle(
              color: textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cadangan otomatis aktif setiap hari pukul 00:00 WIB',
            style: TextStyle(
              color: accentGreen,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(VoidCallback onLogout) {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF181013),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentRed, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: accentRed, size: 17),
            SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(
                color: accentRed,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
