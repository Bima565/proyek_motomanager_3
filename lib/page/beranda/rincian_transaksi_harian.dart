import 'package:flutter/material.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/transaksi_service.dart';

/// Screen 10 - (FR09) Rincian Transaksi Harian (Terintegrasi Cloud Firestore)
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

  static const Map<String, int> _dayToWeekday = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };

  static const List<String> _namaBulanSingkat = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sept', 'Okt', 'Nov', 'Des'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: TransaksiService().transactionsNotifier,
          builder: (context, _) {
            final allTrx = TransaksiService().transactions;
            final validTrx = allTrx.where((t) => t.status.toLowerCase() != 'batal').toList();

            final targetWeekday = _dayToWeekday[_selectedDay] ?? 6;

            // Ambil transaksi yang sesuai dengan hari yang dipilih
            final dayTrx = validTrx.where((t) => t.dateTime.weekday == targetWeekday).toList();
            final bool hasRealData = dayTrx.isNotEmpty;

            // Cari tanggal yang relevan untuk subtitle header
            DateTime targetDate;
            if (hasRealData) {
              targetDate = dayTrx.first.dateTime;
            } else {
              final now = DateTime.now();
              final diff = targetWeekday - now.weekday;
              targetDate = now.add(Duration(days: diff));
            }

            final String subtitleDate =
                '$_selectedDay, ${targetDate.day} ${_namaBulanSingkat[targetDate.month - 1]} ${targetDate.year} • 08.00 - 17.00 WIB';

            // 1. Kalkulasi Pendapatan Hari Tersebut
            int totalHarian = 0;
            int totalServisHarian = 0;
            int totalPartHarian = 0;

            for (final trx in dayTrx) {
              totalHarian += trx.totalBayar;
              for (final item in trx.items) {
                final bool isJasa = item.isService == true ||
                    item.category.toLowerCase().contains('jasa') ||
                    item.category.toLowerCase().contains('servis');
                if (isJasa) {
                  totalServisHarian += item.price * item.quantity;
                } else {
                  totalPartHarian += item.price * item.quantity;
                }
              }
            }

            // Fallback mock baseline jika database hari ini belum ada transaksi
            final int displayTotal = hasRealData ? totalHarian : 140000;
            final int displayServis = hasRealData ? totalServisHarian : 65000;
            final int displayPart = hasRealData ? totalPartHarian : 75000;
            final int displayMotorCount = hasRealData ? dayTrx.length : 5;

            final int servisPct = displayTotal > 0 ? (displayServis / displayTotal * 100).round() : 46;
            final int partPct = displayTotal > 0 ? (displayPart / displayTotal * 100).round() : 54;

            String kasirName = 'Sri Ekowati';
            if (hasRealData && dayTrx.first.kasirName.isNotEmpty) {
              kasirName = dayTrx.first.kasirName;
            } else if (widget.userData?['name'] != null && widget.userData!['name'].toString().isNotEmpty) {
              kasirName = widget.userData!['name'].toString();
            }

            // 2. Kalkulasi Data Bar Chart per 2 Jam (Jam 08, 10, 12, 14, 16)
            final hourBuckets = [
              {'label': 'Jam\n08', 'start': 8, 'end': 10},
              {'label': 'Jam\n10', 'start': 10, 'end': 12},
              {'label': 'Jam\n12', 'start': 12, 'end': 14},
              {'label': 'Jam\n14', 'start': 14, 'end': 16},
              {'label': 'Jam\n16', 'start': 16, 'end': 18},
            ];

            int maxHourTotal = 1;
            final List<Map<String, dynamic>> calculatedHours = [];

            for (final b in hourBuckets) {
              final startH = b['start'] as int;
              final endH = b['end'] as int;
              int s = 0;
              int p = 0;

              for (final t in dayTrx) {
                if (t.dateTime.hour >= startH && t.dateTime.hour < endH) {
                  for (final item in t.items) {
                    final bool isJasa = item.isService == true ||
                        item.category.toLowerCase().contains('jasa') ||
                        item.category.toLowerCase().contains('servis');
                    if (isJasa) {
                      s += item.price * item.quantity;
                    } else {
                      p += item.price * item.quantity;
                    }
                  }
                }
              }

              if (s + p > maxHourTotal) maxHourTotal = s + p;
              calculatedHours.add({'s': s, 'p': p, 'tot': s + p});
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Back Button, Title, Subtitle, Day Dropdown)
                  _buildHeader(subtitleDate),
                  const SizedBox(height: 16),

                  // 2. Card Aktivitas Layanan per Jam
                  _buildAktivitasLayananCard(
                    totalHarian: displayTotal,
                    servisHarian: displayServis,
                    partHarian: displayPart,
                    servisPct: servisPct,
                    partPct: partPct,
                    motorCount: displayMotorCount,
                    kasirName: kasirName,
                    hasRealData: hasRealData,
                    calculatedHours: calculatedHours,
                    maxHourTotal: maxHourTotal,
                  ),
                  const SizedBox(height: 20),

                  // 3. Section Header: Daftar Transaksi per Jam & Selesai Badge
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
                        child: Text(
                          '✓ $displayMotorCount Selesai',
                          style: const TextStyle(
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
                  if (hasRealData)
                    ...dayTrx.map((trx) {
                      // Format Jam
                      final h = trx.dateTime.hour.toString().padLeft(2, '0');
                      final m = trx.dateTime.minute.toString().padLeft(2, '0');
                      final timeStr = '$h:$m';

                      // Format Pelanggan & Kendaraan
                      String custLine = trx.customerName.isEmpty ? 'Pelanggan Umum' : trx.customerName;
                      if (trx.vehicleInfo.isNotEmpty) {
                        custLine += ' • ${trx.vehicleInfo}';
                      }
                      if (trx.policeNumber.isNotEmpty) {
                        custLine += ' (${trx.policeNumber})';
                      }

                      // Breakdown Tag Servis & Part
                      final sItems = trx.items.where((i) {
                        return i.isService == true ||
                            i.category.toLowerCase().contains('jasa') ||
                            i.category.toLowerCase().contains('servis');
                      }).toList();
                      final pItems = trx.items.where((i) => !sItems.contains(i)).toList();

                      final int sTot = sItems.fold(0, (sum, i) => sum + i.price * i.quantity);
                      final int pTot = pItems.fold(0, (sum, i) => sum + i.price * i.quantity);

                      String sDesc = 'Tanpa Servis';
                      if (sItems.isNotEmpty) {
                        final sName = sItems.map((i) => i.name).join(' & ');
                        sDesc = '$sName (${(sTot / 1000).round()}k)';
                      }

                      String pDesc = 'Tanpa Part';
                      if (pItems.isNotEmpty) {
                        final pName = pItems.map((i) => i.name).join(' & ');
                        pDesc = 'Part: $pName (${(pTot / 1000).round()}k)';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTransaksiItem(
                          time: timeStr,
                          paymentType: trx.paymentMethod,
                          total: formatRupiah(trx.totalBayar),
                          customerName: custLine,
                          servisDesc: sDesc,
                          partDesc: pDesc,
                        ),
                      );
                    })
                  else ...[
                    // Mock baseline default bila data hari terpilih masih kosong
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String subtitleDate) {
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
            children: [
              const Text(
                'Rincian Transaksi',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleDate,
                style: const TextStyle(
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
              items: ['Sabtu', 'Jumat', 'Kamis', 'Rabu', 'Selasa', 'Senin', 'Minggu']
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

  Widget _buildAktivitasLayananCard({
    required int totalHarian,
    required int servisHarian,
    required int partHarian,
    required int servisPct,
    required int partPct,
    required int motorCount,
    required String kasirName,
    required bool hasRealData,
    required List<Map<String, dynamic>> calculatedHours,
    required int maxHourTotal,
  }) {
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
                child: Text(
                  'Total: ${formatRupiah(totalHarian)}',
                  style: const TextStyle(
                    color: accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dual Bar Chart (Jam 08, 10, 12, 14, 16) - Bebas dari overflow
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    SizedBox(
                      height: 84,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(5, (index) {
                          final labels = ['Jam\n08', 'Jam\n10', 'Jam\n12', 'Jam\n14', 'Jam\n16'];
                          if (!hasRealData) {
                            // Mock height default
                            final mockH = [
                              {'s': 16.0, 'p': 18.0},
                              {'s': 24.0, 'p': 28.0},
                              {'s': 14.0, 'p': 16.0},
                              {'s': 16.0, 'p': 18.0},
                              {'s': 14.0, 'p': 11.0},
                            ];
                            return _buildHourBar(labels[index], mockH[index]['s']!, mockH[index]['p']!);
                          }

                          final hData = calculatedHours[index];
                          final sVal = hData['s'] as int;
                          final pVal = hData['p'] as int;

                          final double sH = maxHourTotal > 0 ? (sVal / maxHourTotal * 28).clamp(3.0, 28.0) : 3.0;
                          final double pH = maxHourTotal > 0 ? (pVal / maxHourTotal * 28).clamp(3.0, 28.0) : 3.0;

                          return _buildHourBar(labels[index], sH, pH);
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '▼ Part (${(partHarian / 1000).round()}k)',
                          style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '▲ Servis (${(servisHarian / 1000).round()}k)',
                          style: const TextStyle(color: accentRed, fontSize: 8.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(width: 1, height: 86, color: cardBorder),
              const SizedBox(width: 12),

              // Right side: Donut Motor & details
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$motorCount',
                                  style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const Text(
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
                            children: [
                              Text('Servis ($servisPct%)', style: const TextStyle(color: textMuted, fontSize: 8.5)),
                              Text(formatRupiah(servisHarian), style: const TextStyle(color: Color(0xFFFF3B44), fontSize: 9.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text('Barang ($partPct%)', style: const TextStyle(color: textMuted, fontSize: 8.5)),
                              Text(formatRupiah(partHarian), style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kasir: $kasirName',
                      style: const TextStyle(color: textDim, fontSize: 8, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: textMuted, fontSize: 7.5, height: 1.05),
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
    final isQris = paymentType.toUpperCase() == 'QRIS';

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
