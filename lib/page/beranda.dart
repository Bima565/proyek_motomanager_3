import 'package:flutter/material.dart';
import '../components/create_password_dialog.dart';
import '../components/moto_bottom_nav.dart';
import '../hooks/firebase_auth.dart';
import 'data_sparepart.dart';
import 'kelola_stok_jasa.dart';
import 'laporan_pendapatan.dart';
import 'login.dart';
import 'profil.dart';
import 'riwayat_transaksi.dart';

class BerandaPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int initialIndex;

  const BerandaPage({
    super.key,
    this.userData,
    this.initialIndex = 0,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _liveUserData;
  PageController? _pageController;
  int _currentNavIndex = 0;

  PageController get _controller =>
      _pageController ??= PageController(initialPage: widget.initialIndex);

  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentYellow = Color(0xFFEAB308);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadLiveUserData();
    _checkPasswordStatus();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _animateToTab(int index) {
    setState(() => _currentNavIndex = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _checkPasswordStatus() async {
    final bool initialDocHasPass = widget.userData?['has_password'] == true;
    final bool isDocExplicitlyNoPass = widget.userData?['has_password'] == false;
    final bool hasPass = !isDocExplicitlyNoPass && (initialDocHasPass || await _authService.userHasPassword());
    if (!hasPass && mounted) {
      final email = _liveUserData?['email'] ??
          widget.userData?['email'] ??
          _authService.currentUser?.email ??
          '';

      if (email.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final created = await CreatePasswordDialog.show(
            context,
            email: email,
            isChangePassword: false,
          );

          if (!mounted) return;

          if (created == true) {
            _loadLiveUserData();
          } else {
            // Jika user belum memiliki password dan membatalkan dialog, logout
            await _authService.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        });
      }
    }
  }

  void _loadLiveUserData() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _liveUserData = profile;
      });
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

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final String email = _liveUserData?['email'] ??
        widget.userData?['email'] ??
        currentUser?.email ??
        '-';
    final String username = _liveUserData?['nama_lengkap'] ??
        widget.userData?['nama_lengkap'] ??
        currentUser?.displayName ??
        'Pengguna';
    final String role = _liveUserData?['role'] ?? widget.userData?['role'] ?? 'Kasir';
    final String initials = _getUserInitials(username);

    return Scaffold(
      backgroundColor: bgDark,
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentNavIndex = index);
        },
        children: [
          // 0. Tab Beranda
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(initials, username, role, email),
                  const SizedBox(height: 20),
                  _buildOmzetCard('Rp 140.000'),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 24),
                  _buildStokMenipisSection(),
                  const SizedBox(height: 24),
                  _buildTransaksiTerakhirSection(),
                ],
              ),
            ),
          ),
          // 1. Tab Kasir
          RiwayatTransaksiPage(
            userData: _liveUserData ?? widget.userData,
            showBottomNav: false,
          ),
          // 2. Tab Stok & Jasa
          KelolaStokJasaPage(
            userData: _liveUserData ?? widget.userData,
            showBottomNav: false,
          ),
          // 3. Tab Laporan
          LaporanPendapatanPage(
            userData: _liveUserData ?? widget.userData,
            showBottomNav: false,
          ),
          // 4. Tab Profil
          ProfilPage(
            userData: _liveUserData ?? widget.userData,
            showBottomNav: false,
          ),
        ],
      ),
      bottomNavigationBar: MotoBottomNav(
        currentIndex: _currentNavIndex,
        userData: _liveUserData ?? widget.userData,
        onTabSelected: _animateToTab,
      ),
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildHeader(String initials, String username, String role, String email) {
    return Row(
      children: [
        // Lingkaran Avatar dengan Border Merah
        GestureDetector(
          onTap: () => _animateToTab(4),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgDark,
              shape: BoxShape.circle,
              border: Border.all(color: accentRed, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Nama dan Role Badge (Responsif)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentRed, width: 1),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: accentRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOmzetCard(String nominal) {
    return GestureDetector(
      onTap: () => _animateToTab(3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          children: [
            const Text(
              'Omzet Hari Ini',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nominal,
              style: const TextStyle(
                color: textWhite,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Judul, Badge Tanggal, Tombol Detail
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Pendapatan Hari Ini',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge Tanggal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentRed.withValues(alpha: 0.6), width: 1),
                ),
                child: const Text(
                  'Sabtu, 26 Sept',
                  style: TextStyle(
                    color: accentRed,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Detail
              GestureDetector(
                onTap: () => _animateToTab(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2333),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Detail ›',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris Legend: Servis & Sparepart
          Row(
            children: [
              // Legend Servis
              Container(
                width: 14,
                height: 2.5,
                decoration: BoxDecoration(
                  color: accentRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Servis (Rp 65k)',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              // Legend Sparepart
              Container(
                width: 14,
                height: 2.5,
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Sparepart (Rp 75k)',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Chart Area
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: HourlyDualLineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStokMenipisSection() {
    return Column(
      children: [
        // Header Section Stok Menipis
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stok Menipis',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataSparepartPage(
                      userData: _liveUserData ?? widget.userData,
                    ),
                  ),
                );
              },
              child: const Text(
                'Semua (4) >',
                style: TextStyle(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Item 1: Oli Yamalube Silver 0.8L
        _buildStokItem(
          title: 'Oli Yamalube Silver 0.8L',
          subtitle: 'Sisa 2 pcs',
          isCritical: true,
        ),
        const SizedBox(height: 10),

        // Item 2: Kampas Rem Beat / Vario (3 pcs)
        _buildStokItem(
          title: 'Kampas Rem Beat / Vario',
          subtitle: 'Sisa 3 pcs',
          isCritical: false,
        ),
        const SizedBox(height: 10),

        // Item 3: Kampas Rem Beat / Vario (5 pcs)
        _buildStokItem(
          title: 'Kampas Rem Beat / Vario',
          subtitle: 'Sisa 5 pcs',
          isCritical: false,
        ),
      ],
    );
  }

  Widget _buildStokItem({
    required String title,
    required String subtitle,
    required bool isCritical,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Icon Exclamation Bulat
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCritical
                  ? accentRed.withValues(alpha: 0.15)
                  : accentYellow.withValues(alpha: 0.15),
              border: Border.all(
                color: isCritical ? accentRed : accentYellow,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: isCritical ? accentRed : accentYellow,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Detail Sparepart
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Restock
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DataSparepartPage(
                    userData: _liveUserData ?? widget.userData,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isCritical ? accentRed : const Color(0xFF1D2333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Restock',
                style: TextStyle(
                  color: isCritical ? textWhite : const Color(0xFFE2E8F0),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiTerakhirSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            color: textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => _animateToTab(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Row(
              children: [
                // Icon Motor
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      color: accentRed,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Kendaraan & Waktu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Honda Vario 160 (B 4921 KDF)',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '10:15',
                        style: TextStyle(
                          color: textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Biaya Transaksi
                const Text(
                  'Rp 175.000',
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk menggambar Dual Line Chart Penpot secara presisi
class HourlyDualLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const hours = ['08', '09', '10', '11', '12', '13', '14', '15', '16', '17'];
    const yLabels = ['15k', '10k', '5k', '0'];

    final leftGutter = 28.0;
    final bottomGutter = 20.0;
    final topGutter = 22.0;

    final chartWidth = size.width - leftGutter;
    final chartHeight = size.height - bottomGutter - topGutter;

    // Nilai Red (Servis) dalam rasio 0.0 - 1.0 (15k = 1.0)
    final redValues = [0.65, 0.35, 1.0, 0.35, 0.0, 0.35, 0.65, 0.35, 0.65, 0.0];
    // Nilai Blue (Sparepart)
    final blueValues = [0.65, 0.65, 1.0, 0.65, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35];

    final textStyle = const TextStyle(
      color: Color(0xFF64748B),
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
    );

    // 1. Gambar Y-Axis Labels & Garis Grid Halus
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2433)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yLabels.length; i++) {
      final y = topGutter + (chartHeight / (yLabels.length - 1)) * i;
      final textSpan = TextSpan(text: yLabels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(leftGutter - textPainter.width - 6, y - textPainter.height / 2));

      // Garis horizontal
      canvas.drawLine(Offset(leftGutter, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = chartWidth / (hours.length - 1);

    // Dapatkan titik-titik koordinat
    final redPoints = <Offset>[];
    final bluePoints = <Offset>[];

    for (int i = 0; i < hours.length; i++) {
      final x = leftGutter + i * stepX;
      final yRed = topGutter + (1.0 - redValues[i]) * chartHeight;
      final yBlue = topGutter + (1.0 - blueValues[i]) * chartHeight;

      redPoints.add(Offset(x, yRed));
      bluePoints.add(Offset(x, yBlue));

      // Label X-Axis
      final isPeak = (i == 2); // Jam '10'
      final xSpan = TextSpan(
        text: hours[i],
        style: textStyle.copyWith(
          color: isPeak ? const Color(0xFF22C55E) : const Color(0xFF64748B),
          fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final xPainter = TextPainter(
        text: xSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      xPainter.paint(
        canvas,
        Offset(x - xPainter.width / 2, size.height - bottomGutter + 4),
      );
    }

    // 2. Gambar Highlight Vertikal untuk Jam 10 (Peak)
    final peakX = redPoints[2].dx;
    final peakY = redPoints[2].dy;

    final dashPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    // Garis putus-putus
    double curY = peakY;
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    while (curY < size.height - bottomGutter) {
      canvas.drawLine(
        Offset(peakX, curY),
        Offset(peakX, (curY + dashHeight).clamp(0.0, size.height - bottomGutter)),
        dashPaint,
      );
      curY += dashHeight + dashSpace;
    }

    // 3. Gambar Gradient Fill di bawah Garis Merah
    final fillPath = Path()..moveTo(redPoints.first.dx, size.height - bottomGutter);
    for (final pt in redPoints) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(redPoints.last.dx, size.height - bottomGutter);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF1E27).withValues(alpha: 0.35),
          const Color(0xFFFF1E27).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topGutter, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // 4. Gambar Garis Biru (Sparepart)
    final bluePath = Path()..moveTo(bluePoints.first.dx, bluePoints.first.dy);
    for (int i = 1; i < bluePoints.length; i++) {
      bluePath.lineTo(bluePoints[i].dx, bluePoints[i].dy);
    }
    final blueLinePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bluePath, blueLinePaint);

    // Titik-titik Garis Biru
    final blueDotPaint = Paint()..color = const Color(0xFF3B82F6);
    final whiteDotPaint = Paint()..color = Colors.white;
    for (final pt in bluePoints) {
      canvas.drawCircle(pt, 3.5, blueDotPaint);
      canvas.drawCircle(pt, 1.8, whiteDotPaint);
    }

    // 5. Gambar Garis Merah (Servis)
    final redPath = Path()..moveTo(redPoints.first.dx, redPoints.first.dy);
    for (int i = 1; i < redPoints.length; i++) {
      redPath.lineTo(redPoints[i].dx, redPoints[i].dy);
    }
    final redLinePaint = Paint()
      ..color = const Color(0xFFFF1E27)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(redPath, redLinePaint);

    // Titik-titik Garis Merah
    final redDotPaint = Paint()..color = const Color(0xFFFF1E27);
    for (final pt in redPoints) {
      canvas.drawCircle(pt, 3.5, redDotPaint);
      canvas.drawCircle(pt, 1.8, whiteDotPaint);
    }

    // 6. Badge Hijau "30k" di atas Jam 10
    final badgeWidth = 28.0;
    final badgeHeight = 15.0;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(peakX, peakY - 14), width: badgeWidth, height: badgeHeight),
      const Radius.circular(4),
    );
    final badgePaint = Paint()..color = const Color(0xFF143322);
    final badgeBorder = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(badgeRect, badgePaint);
    canvas.drawRRect(badgeRect, badgeBorder);

    final badgeSpan = const TextSpan(
      text: '30k',
      style: TextStyle(
        color: Color(0xFF22C55E),
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    final badgePainter = TextPainter(
      text: badgeSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    badgePainter.paint(canvas, Offset(peakX - badgePainter.width / 2, peakY - 14 - badgePainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
