import 'package:flutter/material.dart';
import '../page/beranda.dart';
import '../page/kelola_stok_jasa.dart';
import '../page/laporan_pendapatan.dart';
import '../page/profil.dart';
import '../page/riwayat_transaksi.dart';

class MotoBottomNav extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? userData;

  const MotoBottomNav({
    super.key,
    required this.currentIndex,
    this.userData,
  });

  static const Color navBg = Color(0xFF0C0E13);
  static const Color navBorder = Color(0xFF1B202D);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF64748B);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = BerandaPage(userData: userData);
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

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => targetPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
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
            horizontal: isCompact ? 8 : 14,
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
    if (isActive) {
      return GestureDetector(
        onTap: () => _onItemTapped(context, index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: accentRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textWhite, size: isCompact ? 16 : 18),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: textWhite,
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textDim, size: isCompact ? 18 : 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: textDim,
                fontSize: isCompact ? 9 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
