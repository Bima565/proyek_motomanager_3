import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../hooks/firebase_auth.dart';
import 'login.dart';

class ProfilPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(int)? onNavigateTab;

  const ProfilPage({
    super.key,
    this.userData,
    this.onNavigateTab,
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
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);

  // List Admin User lokal (bisa diintegrasikan ke Firestore 'user')
  final List<Map<String, String>> _adminUsers = [
    {
      'initials': 'SE',
      'name': 'Sri Ekowati',
      'email': 'sri.eko@motomanage.id',
      'role': 'Administrator',
    },
  ];

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
          content: Text('Kata sandi berhasil diperbarui!'),
        ),
      );
    }
  }

  void _showEditProfileDialog(String currentName, String currentEmail) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
          ],
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (widget.userData != null) {
                  widget.userData!['nama_lengkap'] = nameController.text.trim();
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF143322),
                  content: Text('Data profil berhasil disimpan'),
                ),
              );
            },
            child: const Text('Simpan', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Administrator';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: const Text('Tambah Pengguna Baru',
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
                  hintText: 'Contoh: Budi Santoso',
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
              const SizedBox(height: 14),
              const Text('Email', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                style: const TextStyle(color: textWhite),
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
              const SizedBox(height: 14),
              const Text('Peran / Role', style: TextStyle(color: textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: cardBg,
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
                items: const [
                  DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
                  DropdownMenuItem(value: 'Kasir', child: Text('Kasir')),
                  DropdownMenuItem(value: 'Mekanik', child: Text('Mekanik')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
              ),
            ],
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
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isNotEmpty && email.isNotEmpty) {
                  setState(() {
                    _adminUsers.add({
                      'initials': _getUserInitials(name),
                      'name': name,
                      'email': email,
                      'role': selectedRole,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF143322),
                      content: Text('Pengguna $name berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('Tambah', style: TextStyle(color: textWhite)),
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
    final String email = widget.userData?['email'] ??
        currentUser?.email ??
        'sugeng@motomanage.id';
    final String username = widget.userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Sugeng Yulianto';
    final String role = (widget.userData?['role'] ?? 'SUPERADMIN').toString().toUpperCase();
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

              // 2. Card Profil Utama (SY, Sugeng Yulianto, SUPERADMIN)
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
                title: 'Ubah Data Diri & Profil',
                onTap: () => _showEditProfileDialog(username, email),
              ),
              const SizedBox(height: 10),
              _buildActionMenuItem(
                title: 'Ganti Kata Sandi (Password)',
                onTap: () => _handleChangePassword(email),
              ),
              const SizedBox(height: 24),

              // 4. Section Kelola Pengguna Administrator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kelola Pengguna Administrator',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddUserDialog,
                    child: const Text(
                      '+ Tambah User',
                      style: TextStyle(
                        color: accentRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._adminUsers.map((admin) => _buildAdminUserCard(admin)),
              const SizedBox(height: 24),

              // 5. Card Pencadangan Data Basis Data
              _buildBackupCard(),
              const SizedBox(height: 24),

              // 6. Tombol Keluar Akun
              _buildLogoutButton(() => _handleLogout(email)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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

  Widget _buildAdminUserCard(Map<String, String> admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Avatar Biru SE
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF192336),
              border: Border.all(color: accentBlue, width: 1.5),
            ),
            child: Center(
              child: Text(
                admin['initials'] ?? 'SE',
                style: const TextStyle(
                  color: accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Nama & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['name'] ?? '',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${admin['email']} • ${admin['role']}',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Edit (Pensil)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: cardBg,
                  content: Text('Edit data ${admin['name']}'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded, color: textMuted, size: 14),
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Hapus (Tong Sampah)
          GestureDetector(
            onTap: () {
              setState(() => _adminUsers.remove(admin));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF3B1517),
                  content: Text('${admin['name']} berhasil dihapus'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2B191E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: accentRed, size: 14),
            ),
          ),
        ],
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0E13),
        border: Border(top: BorderSide(color: Color(0xFF1B202D), width: 1)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Beranda
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Beranda',
            isActive: false,
            onTap: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(0);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          // 2. Kasir
          _buildNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Kasir',
            isActive: false,
          ),
          // 3. Stok
          _buildNavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Stok',
            isActive: false,
          ),
          // 4. Laporan
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Laporan',
            isActive: false,
          ),
          // 5. Profil (Active Capsule)
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accentRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textWhite, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: textWhite,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textDim, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: textDim,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
