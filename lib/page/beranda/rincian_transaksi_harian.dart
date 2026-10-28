import 'package:flutter/material.dart';

/// Screen 10 - (FR09) Rincian Transaksi Harian
class RincianTransaksiHarianPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const RincianTransaksiHarianPage({super.key, this.userData});

  @override
  State<RincianTransaksiHarianPage> createState() => _RincianTransaksiHarianPageState();
}

class _RincianTransaksiHarianPageState extends State<RincianTransaksiHarianPage> {
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  String _selectedDay = 'Sabtu';

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
              // 1. Header (Back Button, Title, Subtitle, Day Dropdown)
              _buildHeader(),
              const SizedBox(height: 16),

              // 2. Card Aktivitas Layanan per Jam
              _buildAktivitasLayananCard(),
              const SizedBox(height: 20),

              // 3. Section Header: Daftar Transaksi per Jam & 5 Selesai Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Transaksi per Jam',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2818),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF166534), width: 1),
                    ),
                    child: const Text(
                      '✓ 5 Selesai',
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. List Transaksi Items
              _buildTransaksiItem(
                time: '08:45',
                paymentType: 'Tunai',
                total: 'Rp 35.000',
                customerName: 'Budi Santoso • Beat FI (AE 3912 BE)',
                servisDesc: 'Servis Ringan (15k)',
                partDesc: 'Part: Oli & Busi (20k)',
              ),
              const SizedBox(height: 10),

              _buildTransaksiItem(
                time: '10:15',
                paymentType: 'QRIS',
                total: 'Rp 45.000',
                customerName: 'Ahmad Fauzi • Vario 160 (AE 4921 KF)',
                servisDesc: 'Servis CVT (20k)',
                partDesc: 'Part: Kampas Rem (25k)',
              ),
              const SizedBox(height: 10),

              _buildTransaksiItem(
                time: '11:30',
                paymentType: 'Tunai',
                total: 'Rp 25.000',
                customerName: 'Ibu Sri Wahyuni • Mio M3 (AE 2481 RK)',
                servisDesc: 'Ganti Oli (10k)',
                partDesc: 'Part: Oli Mesin (15k)',
              ),
              const SizedBox(height: 10),

              _buildTransaksiItem(
                time: '14:10',
                paymentType: 'Tunai',
                total: 'Rp 20.000',
                customerName: 'Rudi Hartono • Supra X 125 (AE 5109 DA)',
                servisDesc: 'Servis: Stel Rem & Rantai (10k)',
                partDesc: 'Part: Rantai (10k)',
              ),
              const SizedBox(height: 10),

              _buildTransaksiItem(
                time: '16:00',
                paymentType: 'QRIS',
                total: 'Rp 15.000',
                customerName: 'Dian Pratama • NMAX (AE 6820 GL)',
                servisDesc: 'Tambal Tubeless (10k)',
                partDesc: 'Part: Cairan Ban (5k)',
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
                'Rincian Transaksi',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sabtu, 26 Sept 2026 • 08.00 - 17.00 WIB',
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
              value: _selectedDay,
              dropdownColor: cardBg,
              icon: const Icon(Icons.arrow_drop_down, color: textDim, size: 16),
              style: const TextStyle(
                color: textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              items: ['Sabtu', 'Jumat', 'Kamis', 'Rabu', 'Selasa', 'Senin']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDay = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAktivitasLayananCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                'Aktivitas Layanan per Jam',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2818),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF166534), width: 1),
                ),
                child: const Text(
                  'Total: Rp 140.000',
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dual Bar Chart (Jam 08, 10, 12, 14, 16)
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    SizedBox(
                      height: 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHourBar('Jam\n08', 20, 22),
                          _buildHourBar('Jam\n10', 32, 38),
                          _buildHourBar('Jam\n12', 15, 18),
                          _buildHourBar('Jam\n14', 20, 20),
                          _buildHourBar('Jam\n16', 16, 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '▼ Part (75k)',
                          style: TextStyle(color: Color(0xFF3B82F6), fontSize: 8.5, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 14),
                        Text(
                          '▲ Servis (65k)',
                          style: TextStyle(color: accentRed, fontSize: 8.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(width: 1, height: 90, color: cardBorder),
              const SizedBox(width: 12),

              // Right side: Donut 5 Motor & details
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '5',
                                  style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'MOTOR',
                                  style: TextStyle(color: textDim, fontSize: 6.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Servis (46%)', style: TextStyle(color: textMuted, fontSize: 8.5)),
                              Text('Rp 65.000', style: TextStyle(color: Color(0xFFFF3B44), fontSize: 9.5, fontWeight: FontWeight.bold)),
                              SizedBox(height: 3),
                              Text('Sparepart (54%)', style: TextStyle(color: textMuted, fontSize: 8.5)),
                              Text('Rp 75.000', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kasir: Sri Ekowati',
                      style: TextStyle(color: textDim, fontSize: 8, fontWeight: FontWeight.w500),
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

  Widget _buildHourBar(String label, double servisHeight, double partHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: textMuted, fontSize: 7.5, height: 1.1),
        ),
        const SizedBox(height: 4),
        Container(
          width: 8,
          height: servisHeight,
          decoration: BoxDecoration(
            color: accentRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 8,
          height: partHeight,
          decoration: BoxDecoration(
            color: accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTransaksiItem({
    required String time,
    required String paymentType,
    required String total,
    required String customerName,
    required String servisDesc,
    required String partDesc,
  }) {
    final isQris = paymentType == 'QRIS';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B202D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(color: textMuted, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isQris ? const Color(0xFF112239) : const Color(0xFF0F2B1D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      paymentType,
                      style: TextStyle(
                        color: isQris ? const Color(0xFF60A5FA) : accentGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                total,
                style: const TextStyle(
                  color: accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customerName,
            style: const TextStyle(
              color: textWhite,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26190F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF5A391A), width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      servisDesc,
                      style: const TextStyle(color: accentOrange, fontSize: 8.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C192E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1D3B66), width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      partDesc,
                      style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 8.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
