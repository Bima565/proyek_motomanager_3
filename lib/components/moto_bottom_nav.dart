import 'package:flutter/material.dart';
import '../hooks/firebase_auth.dart';
import '../page/beranda.dart';
import '../page/kelola_stok_jasa.dart';
import '../page/laporan_pendapatan.dart';
import '../page/mengelola_user.dart';
import '../page/profil.dart';
import '../page/riwayat_transaksi.dart';

class MotoBottomNav extends StatefulWidget {
  final int currentIndex;
  final Map<String, dynamic>? userData;
  final ValueChanged<int>? onTabSelected;

  const MotoBottomNav({
    super.key,
    required this.currentIndex,
    this.userData,
    this.onTabSelected,
  });

  @override
  State<MotoBottomNav> createState() => _MotoBottomNavState();
}

class _MotoBottomNavState extends State<MotoBottomNav> {
  static const Color navBg = Color(0xFF0C0E13);
  static const Color navBorder = Color(0xFF1B202D);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF64748B);

  Map<String, dynamic>? _liveUserData;

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  void _checkUserData() async {
    if (widget.userData?['role'] == null) {
      final profile = await AuthService().getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _liveUserData = profile;
        });
      }
    }
  }

  Map<String, dynamic>? get _effectiveUserData =>
      _liveUserData ?? widget.userData;

  bool get _isSuperAdmin {
    final role = (_effectiveUserData?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]'), '');
    return role == 'superadmin';
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }

    Widget targetPage;
    if (_isSuperAdmin) {
      switch (index) {
        case 0:
          targetPage = BerandaPage(userData: _effectiveUserData, initialIndex: 0);
          break;
        case 1:
          targetPage = RiwayatTransaksiPage(userData: _effectiveUserData);
          break;
        case 2:
          targetPage = KelolaStokJasaPage(userData: _effectiveUserData);
          break;
        case 3:
          targetPage = LaporanPendapatanPage(userData: _effectiveUserData);
          break;
        case 4:
          targetPage = MengelolaUserPage(userData: _effectiveUserData);
          break;
        case 5:
          targetPage = ProfilPage(userData: _effectiveUserData);
          break;
        default:
          return;
      }
    } else {
      switch (index) {
        case 0:
          targetPage = BerandaPage(userData: _effectiveUserData, initialIndex: 0);
          break;
        case 1:
          targetPage = RiwayatTransaksiPage(userData: _effectiveUserData);
          break;
        case 2:
          targetPage = KelolaStokJasaPage(userData: _effectiveUserData);
          break;
        case 3:
          targetPage = LaporanPendapatanPage(userData: _effectiveUserData);
          break;
        case 4:
          targetPage = ProfilPage(userData: _effectiveUserData);
          break;
        default:
          return;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSuperAdmin = _isSuperAdmin;

    return Container(
      decoration: const BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSuperAdmin ? 4 : (isCompact ? 6 : 12),
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: widget.currentIndex == 0,
                isCompact: isCompact,
                isSuperAdmin: isSuperAdmin,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Transaksi',
                isActive: widget.currentIndex == 1,
                isCompact: isCompact,
                isSuperAdmin: isSuperAdmin,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.inventory_2_outlined,
                label: 'Stok',
                isActive: widget.currentIndex == 2,
                isCompact: isCompact,
                isSuperAdmin: isSuperAdmin,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.bar_chart_rounded,
                label: 'Laporan',
                isActive: widget.currentIndex == 3,
                isCompact: isCompact,
                isSuperAdmin: isSuperAdmin,
              ),
              if (isSuperAdmin)
                _buildNavItem(
                  context: context,
                  index: 4,
                  imageAsset: 'assets/nav/image.png',
                  label: 'Pengguna',
                  isActive: widget.currentIndex == 4,
                  isCompact: isCompact,
                  isSuperAdmin: true,
                ),
              _buildNavItem(
                context: context,
                index: isSuperAdmin ? 5 : 4,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: widget.currentIndex == (isSuperAdmin ? 5 : 4),
                isCompact: isCompact,
                isSuperAdmin: isSuperAdmin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    IconData? icon,
    String? imageAsset,
    required String label,
    required bool isActive,
    required bool isCompact,
    bool isSuperAdmin = false,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: isSuperAdmin ? (isCompact ? 48 : 54) : (isCompact ? 58 : 64),
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? accentRed : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentRed.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset,
                width: 20,
                height: 20,
                color: isActive ? textWhite : textDim,
              )
            else if (icon != null)
              Icon(
                icon,
                color: isActive ? textWhite : textDim,
                size: 20,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? textWhite : textDim,
                fontSize: isSuperAdmin ? 9.5 : 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
