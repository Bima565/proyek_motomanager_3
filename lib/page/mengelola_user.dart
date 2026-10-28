import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';
import '../hooks/firebase_auth.dart';

class MengelolaUserPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool showBottomNav;

  const MengelolaUserPage({
    super.key,
    this.userData,
    this.showBottomNav = true,
  });

  @override
  State<MengelolaUserPage> createState() => _MengelolaUserPageState();
}

class _MengelolaUserPageState extends State<MengelolaUserPage> {
  final AuthService _authService = AuthService();

  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF2A35);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);

  Map<String, dynamic>? _liveUserData;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLiveUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _getUserInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
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
          title: const Text('Tambah Pengguna Baru',
              style: TextStyle(
                  color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Lengkap',
                    style: TextStyle(color: textMuted, fontSize: 12)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Email',
                    style: TextStyle(color: textMuted, fontSize: 12)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Nomor Telepon',
                    style: TextStyle(color: textMuted, fontSize: 12)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Kata Sandi Awal',
                    style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: textWhite),
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: const TextStyle(color: textDim),
                    filled: true,
                    fillColor: bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textDim,
                        size: 18,
                      ),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF3B1517),
                            content: Text('Nama dan email wajib diisi!'),
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      setDialogState(() => isLoading = true);

                      try {
                        await _authService.addNewUser(
                          namaLengkap: name,
                          email: email,
                          role: 'Kasir',
                          noTelepon: phone,
                          password: password.isNotEmpty ? password : null,
                        );

                        if (ctx.mounted) {
                          nav.pop();
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF143322),
                              content: Text(
                                  'Pengguna $name berhasil ditambahkan ke Firebase!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF3B1517),
                              content: Text('Gagal menambahkan pengguna: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Tambah',
                      style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(
        text: user['nama_lengkap'] ?? user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(
        text: user['no_telepon'] ?? user['noTelepon'] ?? '');
    final passwordController = TextEditingController();
    bool obscurePassword = true;
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
          title: Text('Edit Data ${user['nama_lengkap'] ?? 'Pengguna'}',
              style: const TextStyle(
                  color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Lengkap',
                    style: TextStyle(color: textMuted, fontSize: 12)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Email',
                    style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: textWhite),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Nomor Telepon',
                    style: TextStyle(color: textMuted, fontSize: 12)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Password Baru',
                    style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: textWhite),
                  decoration: InputDecoration(
                    hintText: 'Kosongkan jika tidak diubah',
                    hintStyle: const TextStyle(color: textDim, fontSize: 12),
                    filled: true,
                    fillColor: bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textDim,
                        size: 18,
                      ),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final pass = passwordController.text.trim();
                      final docId = user['id'];

                      if (name.isEmpty || email.isEmpty) return;

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      setDialogState(() => isLoading = true);
                      try {
                        await _authService.updateUser(
                          docId: docId,
                          namaLengkap: name,
                          email: email,
                          noTelepon: phone,
                          password: pass.isNotEmpty ? pass : null,
                        );

                        if (ctx.mounted) {
                          nav.pop();
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF143322),
                              content: Text(
                                  'Data $name berhasil diperbarui di Firebase!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF3B1517),
                              content: Text(
                                  'Gagal memperbarui pengguna: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan',
                      style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    final String name = user['nama_lengkap'] ?? user['name'] ?? 'Pengguna';
    final String docId = user['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Text('Konfirmasi Hapus',
            style: TextStyle(
                color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna $name dari database Firebase?',
          style: const TextStyle(color: textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await _authService.deleteUser(docId);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF143322),
                      content: Text(
                          'Pengguna $name berhasil dihapus dari Firebase!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF3B1517),
                      content: Text('Gagal menghapus pengguna: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> admin) {
    final String name = admin['nama_lengkap'] ?? admin['name'] ?? 'Pengguna';
    final String email = admin['email'] ?? '-';
    final String noTelepon =
        (admin['no_telepon'] ?? admin['noTelepon'] ?? '').toString().trim();
    final String telpDisplay = noTelepon.isNotEmpty ? noTelepon : '-';
    final String role = (admin['role'] ?? 'Kasir').toString().toUpperCase();
    final String initials = _getUserInitials(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Avatar Initial
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF192336),
              border: Border.all(color: accentBlue, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Nama & Kontak & Role Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF132338),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1E3A5F)),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$email • $telpDisplay',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Tombol Edit (Pensil)
          GestureDetector(
            onTap: () => _showEditUserDialog(admin),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: textMuted, size: 15),
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Hapus (Tong Sampah)
          GestureDetector(
            onTap: () => _showDeleteUserDialog(admin),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2B191E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: accentRed, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final currentEmailClean =
        (_liveUserData?['email'] ?? widget.userData?['email'] ?? currentUser?.email ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final currentUid = currentUser?.uid ?? '';
    final currentDocId =
        (_liveUserData?['id'] ?? widget.userData?['id'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kelola Pengguna',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola Akun Kasir & Administrator Sistem',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      foregroundColor: textWhite,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah User',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Box
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: textWhite, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email pengguna...',
                    hintStyle: const TextStyle(color: textDim, fontSize: 12),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: textDim, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: textDim, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Stream of Users
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _authService.streamUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentRed,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        'Gagal memuat pengguna: ${snapshot.error}',
                        style: const TextStyle(color: accentRed, fontSize: 12),
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];

                  // Sembunyikan superadmin & akun yang sedang aktif
                  final filteredUsers = users.where((user) {
                    final userRole = (user['role'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'[\s_-]'), '');
                    final userEmail =
                        (user['email'] ?? '').toString().trim().toLowerCase();
                    final userId = (user['id'] ?? '').toString().trim();
                    final userName =
                        (user['nama_lengkap'] ?? user['name'] ?? '')
                            .toString()
                            .toLowerCase();

                    if (userRole == 'superadmin') return false;
                    if (currentEmailClean.isNotEmpty &&
                        userEmail == currentEmailClean) {
                      return false;
                    }
                    if (currentUid.isNotEmpty && userId == currentUid) {
                      return false;
                    }
                    if (currentDocId.isNotEmpty && userId == currentDocId) {
                      return false;
                    }

                    if (_searchQuery.isNotEmpty) {
                      final matchName = userName.contains(_searchQuery);
                      final matchEmail = userEmail.contains(_searchQuery);
                      if (!matchName && !matchEmail) return false;
                    }

                    return true;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 36, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                color: textDim, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada pengguna yang cocok dengan "$_searchQuery"'
                                  : 'Belum ada pengguna kasir/admin terdaftar.',
                              style: const TextStyle(
                                  color: textMuted, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Daftar Pengguna (${filteredUsers.length})',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...filteredUsers.map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildUserCard(user),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.showBottomNav == true)
          ? MotoBottomNav(
              currentIndex: 4,
              userData: _liveUserData ?? widget.userData,
            )
          : null,
    );
  }
}
