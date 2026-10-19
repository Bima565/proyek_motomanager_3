import 'package:flutter/material.dart';

/// Screen 15 - (FR09) Rincian Laporan Omzet 6 Bulan
class RincianOmzet6BulanPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const RincianOmzet6BulanPage({super.key, this.userData});

  @override
  State<RincianOmzet6BulanPage> createState() => _RincianOmzet6BulanPageState();
}

class _RincianOmzet6BulanPageState extends State<RincianOmzet6BulanPage> {
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  String _selectedYear = '2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button, Title, Subtitle, Year Dropdown)
              _buildHeader(),
              const SizedBox(height: 16),

              // 2. Card Total Akumulasi Omzet (6 Bulan)
              _buildAkumulasiCard(),
              const SizedBox(height: 16),

              // 3. List Kartu Bulan-Bulan
              _buildMonthCard(
                month: 'September 2026',
                omzet: 'Rp 2.750.000',
                comparison: '▲ +7.8% vs Agu',
                isPositive: true,
                isHighlight: true,
                servisText: 'Servis: Rp 1.240.000 (45%)',
                partText: 'Part: Rp 1.510.000 (55%)',
                servisRatio: 0.45,
              ),
              const SizedBox(height: 10),

              _buildMonthCard(
                month: 'Agustus 2026',
                omzet: 'Rp 2.550.000',
                comparison: '▲ +5.4% vs Jul',
                isPositive: true,
                isHighlight: false,
                servisText: 'Servis: Rp 1.150.000 (45%)',
                partText: 'Part: Rp 1.400.000 (55%)',
                servisRatio: 0.45,
              ),
              const SizedBox(height: 10),

              _buildMonthCard(
                month: 'Juli 2026',
                omzet: 'Rp 2.420.000',
                comparison: '▼ -6.9% vs Jun',
                isPositive: false,
                isHighlight: false,
                servisText: 'Servis: Rp 1.090.000 (45%)',
                partText: 'Part: Rp 1.330.000 (55%)',
                servisRatio: 0.45,
              ),
              const SizedBox(height: 10),

              _buildMonthCard(
                month: 'Juni 2026',
                omzet: 'Rp 2.600.000',
                comparison: '▲ +4.8% vs Mei',
                isPositive: true,
                isHighlight: false,
                servisText: 'Servis: Rp 1.170.000 (45%)',
                partText: 'Part: Rp 1.430.000 (55%)',
                servisRatio: 0.45,
              ),
              const SizedBox(height: 10),

              _buildMonthCard(
                month: 'Mei 2026',
                omzet: 'Rp 2.480.000',
                comparison: '▲ +5.5% vs Apr',
                isPositive: true,
                isHighlight: false,
                servisText: 'Servis: Rp 1.120.000 (45%)',
                partText: 'Part: Rp 1.360.000 (55%)',
                servisRatio: 0.45,
              ),
              const SizedBox(height: 10),

              _buildMonthCard(
                month: 'April 2026',
                omzet: 'Rp 2.350.000',
                comparison: 'Basis Awal',
                isPositive: null,
                isHighlight: false,
                servisText: 'Servis: Rp 1.060.000 (45%)',
                partText: 'Part: Rp 1.290.000 (55%)',
                servisRatio: 0.45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: textWhite, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Rincian Omzet 6 Bulan',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Periode Apr - Sept 2026 • Basis UMR Madiun',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedYear,
              dropdownColor: cardBg,
              icon: const Icon(Icons.arrow_drop_down, color: textDim, size: 16),
              style: const TextStyle(
                color: textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              items: ['2026', '2025']
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedYear = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAkumulasiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TOTAL AKUMULASI OMZET (6 BULAN)',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Rp 15.150.000',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Rata-rata: Rp 2.525.000 / bln',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2818),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF166534), width: 1),
                ),
                child: const Text(
                  '▲ +17.0%',
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tren Positif',
                style: TextStyle(
                  color: textDim,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard({
    required String month,
    required String omzet,
    required String comparison,
    required bool? isPositive,
    required bool isHighlight,
    required String servisText,
    required String partText,
    required double servisRatio,
  }) {
    Color compColor = textDim;
    if (isPositive == true) compColor = accentGreen;
    if (isPositive == false) compColor = const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? const Color(0xFF166534) : cardBorder,
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    omzet,
                    style: TextStyle(
                      color: isHighlight ? accentGreen : textWhite,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comparison,
                    style: TextStyle(
                      color: compColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorIndicator(accentRed),
              const SizedBox(width: 4),
              Text(servisText, style: const TextStyle(color: textMuted, fontSize: 9.5)),
              const Spacer(),
              _buildColorIndicator(accentBlue),
              const SizedBox(width: 4),
              Text(partText, style: const TextStyle(color: textMuted, fontSize: 9.5)),
            ],
          ),
          const SizedBox(height: 8),

          // Dual color progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(
                    flex: (servisRatio * 100).toInt(),
                    child: Container(color: accentRed),
                  ),
                  Expanded(
                    flex: ((1 - servisRatio) * 100).toInt(),
                    child: Container(color: accentBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorIndicator(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
