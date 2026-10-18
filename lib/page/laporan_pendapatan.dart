import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';

/// Screen 7 - (FR09) Laporan Pendapatan & Analitik Bengkel
class LaporanPendapatanPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool showBottomNav;

  const LaporanPendapatanPage({
    super.key,
    this.userData,
    this.showBottomNav = true,
  });

  @override
  State<LaporanPendapatanPage> createState() => _LaporanPendapatanPageState();
}

class _LaporanPendapatanPageState extends State<LaporanPendapatanPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentYellow = Color(0xFFEAB308);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  String _selectedPeriod = 'Sept 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section & Periode Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Laporan Pendapatan',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        dropdownColor: cardBg,
                        icon: const Icon(Icons.arrow_drop_down, color: textDim, size: 16),
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Sept 2026', 'Agt 2026', 'Jul 2026']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriod = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Card Total Omzet Bulanan (Cyan Box Penpot)
              _buildTotalOmzetCard(),
              const SizedBox(height: 16),

              // 3. Card Sumber Pendapatan (Donut Chart Penpot)
              _buildSumberPendapatanCard(),
              const SizedBox(height: 16),

              // 4. Card Grafik Pendapatan Minggu Ini (Dual Bar Chart)
              _buildGrafikMingguanCard(),
              const SizedBox(height: 16),

              // 5. Card Tren Omzet Bulanan (6 Bulan Line Chart)
              _buildTrenOmzetCard(),
              const SizedBox(height: 16),

              // 6. Card Ekspor Dokumen Laporan (PDF & WhatsApp)
              _buildEksporDokumenCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.showBottomNav == true)
          ? MotoBottomNav(
              currentIndex: 3,
              userData: widget.userData,
            )
          : null,
    );
  }

  // --- KOMPONEN KARTU-KARTU PENPOT ---

  Widget _buildTotalOmzetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL OMZET BULANAN',
            style: TextStyle(
              color: textDim,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1826),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentBlue, width: 1.5),
            ),
            child: const Center(
              child: Text(
                'Rp 2.750.000',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSumberPendapatanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sumber Pendapatan',
            style: TextStyle(
              color: textWhite,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Donut Chart Lingkaran
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    servisPercent: 0.45,
                    sparepartPercent: 0.55,
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '55%',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Part',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Detail List Sumber
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jasa Servis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jasa Servis (45%)',
                                style: TextStyle(
                                  color: textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rp 1.240.000 • 38 servis',
                                style: TextStyle(color: textMuted, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sparepart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sparepart (55%)',
                                style: TextStyle(
                                  color: textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rp 1.510.000 • 26 pcs',
                                style: TextStyle(color: textMuted, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrafikMingguanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Judul & Detail Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grafik Pendapatan Minggu Ini',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF281116),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5A1E24)),
                ),
                child: const Text(
                  'Detail ›',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Legend
          Row(
            children: [
              _buildLegendDot(accentRed, 'Servis'),
              const SizedBox(width: 14),
              _buildLegendDot(accentBlue, 'Sparepart'),
            ],
          ),
          const SizedBox(height: 16),

          // 7 Days Dual Bar Chart
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarCol('Sen', '75k', 0.55, 0.45, false),
                _buildBarCol('Sel', '85k', 0.65, 0.50, false),
                _buildBarCol('Rab', '80k', 0.60, 0.55, false),
                _buildBarCol('Kam', '95k', 0.70, 0.65, false),
                _buildBarCol('Jum', '90k', 0.68, 0.60, false),
                _buildBarCol('Sab', '140k', 1.0, 0.90, true),
                _buildBarCol('Min', '110k', 0.80, 0.75, false),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer Rata-rata
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10131B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Rata-rata: Rp 96.000 / hari • Total Minggu: Rp 675.000',
                style: TextStyle(
                  color: textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarCol(String day, String val, double hServis, double hPart, bool isHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          val,
          style: TextStyle(
            color: isHighlight ? accentYellow : textDim,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 7,
              height: 55 * hServis,
              decoration: BoxDecoration(
                color: accentRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 7,
              height: 55 * hPart,
              decoration: BoxDecoration(
                color: accentBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            color: isHighlight ? accentYellow : textMuted,
            fontSize: 9.5,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrenOmzetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tren Omzet Bulanan (6 Bulan)',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF281116),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5A1E24)),
                ),
                child: const Text(
                  'Detail ›',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Painted Line Chart with Dots & Gradients
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrenOmzetPainter(),
            ),
          ),
          const SizedBox(height: 6),

          // Bulan Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apr', style: TextStyle(color: textDim, fontSize: 9)),
              Text('Mei', style: TextStyle(color: textDim, fontSize: 9)),
              Text('Jun', style: TextStyle(color: textDim, fontSize: 9)),
              Text('Jul', style: TextStyle(color: textDim, fontSize: 9)),
              Text('Agu', style: TextStyle(color: textDim, fontSize: 9)),
              Text('Sep', style: TextStyle(color: accentGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEksporDokumenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A1A22), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ekspor Dokumen Laporan (PDF)',
            style: TextStyle(
              color: textWhite,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Tombol Unduh PDF (Solid Merah)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF143322),
                        content: Text('Laporan PDF bulan ini sedang diunduh...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                  label: const Text(
                    'Unduh PDF',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    foregroundColor: textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tombol Kirim WhatsApp (Green Dark)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF143322),
                        content: Text('Membuka WhatsApp untuk berbagi laporan...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text(
                    'Kirim WhatsApp',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2B1D),
                    foregroundColor: accentGreen,
                    side: const BorderSide(color: Color(0xFF166534), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: textMuted, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Painter untuk Donut Chart Sumber Pendapatan
class _DonutChartPainter extends CustomPainter {
  final double servisPercent;
  final double sparepartPercent;

  _DonutChartPainter({
    required this.servisPercent,
    required this.sparepartPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final paintBg = Paint()
      ..color = const Color(0xFF1C2232)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    canvas.drawCircle(center, radius, paintBg);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue arc (Sparepart 55%)
    final paintBlue = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final sweepBlue = 2 * math.pi * sparepartPercent;
    canvas.drawArc(rect, -math.pi / 2, sweepBlue, false, paintBlue);

    // Red arc (Servis 45%)
    final paintRed = Paint()
      ..color = const Color(0xFFFF1E27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final sweepRed = 2 * math.pi * servisPercent;
    canvas.drawArc(rect, -math.pi / 2 + sweepBlue + 0.08, sweepRed - 0.16, false, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk Tren Omzet Bulanan Line Chart
class _TrenOmzetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [1.35, 2.48, 2.80, 2.42, 2.58, 2.75];
    final labels = ['1,35 Jt', '2,48 Jt', '2,80 Jt', '2,42 Jt', '2,58 Jt', '2,75 Jt'];
    final minVal = 1.0;
    final maxVal = 3.2;

    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedY = (values[i] - minVal) / (maxVal - minVal);
      final y = size.height - (normalizedY * (size.height - 24)) - 10;
      points.add(Offset(x, y));
    }

    // Path area dengan gradient
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x33FF1E27),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Garis Merah
    final linePaint = Paint()
      ..color = const Color(0xFFFF1E27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Titik & Teks Nilai
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isLast = i == points.length - 1;

      // Titik Marker
      final dotPaint = Paint()
        ..color = isLast ? const Color(0xFF22C55E) : const Color(0xFFFF1E27);
      canvas.drawCircle(p, isLast ? 4 : 3, dotPaint);

      // Label teks di atas titik
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isLast ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
          fontSize: 7.5,
          fontWeight: isLast ? FontWeight.bold : FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, p.dy - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
