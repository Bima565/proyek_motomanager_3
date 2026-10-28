import 'package:flutter/material.dart';

/// Tombol kembali berbentuk lingkaran tema gelap khas MotoManage.
/// Dipakai seragam di header berbagai halaman navigasi sub-menu.
class BackButtonCircle extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const BackButtonCircle({
    super.key,
    this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.maybePop(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF151821),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF222634), width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFFFFFFFF),
            size: 24,
          ),
        ),
      ),
    );
  }
}
