import 'package:flutter/material.dart';
import '../page/beranda.dart';
import '../page/kelola_stok_jasa.dart';
import '../page/laporan_pendapatan.dart';
import '../page/profil.dart';
import '../page/riwayat_transaksi.dart';

class MotoBottomNav extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? userData;
  final ValueChanged<int>? onTabSelected;

  const MotoBottomNav({
    super.key,
    required this.currentIndex,
    this.userData,
    this.onTabSelected,
  });

  static const Color navBg = Color(0xFF0C0E13);
  static const Color navBorder = Color(0xFF1B202D);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF64748B);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = BerandaPage(userData: userData, initialIndex: 0);
        break;
      case 1:
        targetPage = RiwayatTransaksiPage(userData: userData);
        break;
      case 2:
        targetPage = KelolaStokJasaPage(userData: userData);
        break;
      case 3:
        targetPage = LaporanPendapatanPage(userData: userData);
        break;
      case 4:
        targetPage = ProfilPage(userData: userData);
        break;
      default:
        return;
    }

    final isForward = index > currentIndex;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = Offset(isForward ? 1.0 : -1.0, 0.0);
          final end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      decoration: const BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 12,
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
                isActive: currentIndex == 0,
                isCompact: isCompact,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Kasir',
                isActive: currentIndex == 1,
                isCompact: isCompact,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.inventory_2_outlined,
                label: 'Stok',
                isActive: currentIndex == 2,
                isCompact: isCompact,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.bar_chart_rounded,
                label: 'Laporan',
                isActive: currentIndex == 3,
                isCompact: isCompact,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: currentIndex == 4,
                isCompact: isCompact,
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
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompact,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: isCompact ? 58 : 64,
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
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
