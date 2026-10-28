import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';
import 'transaksi/kasir_transaksi.dart';
import 'transaksi/nota_pembayaran.dart';
import 'transaksi/pengadaan_restock.dart';

class TransaksiRecord {
  final String code;
  final DateTime dateTime;
  final String payment; // 'QRIS' | 'TUNAI'
  final int amount;
  final String customer;
  final String vehicle;
  final String service;

  const TransaksiRecord({
    required this.code,
    required this.dateTime,
    required this.payment,
    required this.amount,
    required this.customer,
    required this.vehicle,
    required this.service,
  });

  String get timeFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$min $d/$m/$y';
  }

  String get dayName {
    switch (dateTime.weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }
}

/// Screen 12 & Screen 12B - (FR07 & FR09) Riwayat Transaksi & Pembelian
class RiwayatTransaksiPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool showBottomNav;

  const RiwayatTransaksiPage({
    super.key,
    this.userData,
    this.showBottomNav = true,
  });

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color inputBg = Color(0xFF0A0C10);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  // Tab Index: 0 = Transaksi Penjualan / Jasa (Screen 12), 1 = Transaksi Pembelian (Screen 12B)
  int _activeTab = 0;

  // Filter Tanggal Rentang Waktu
  DateTime _startDate = DateTime(2026, 9, 20);
  DateTime _endDate = DateTime(2026, 10, 26);

  // Quick Period Pill (1 Hari | 7 Hari | 30 Hari | Semua)
  String _selectedQuickPeriod = 'Semua';

  // Filter Metode Pembayaran (khusus penjualan): 'Semua' | 'QRIS' | 'TUNAI'
  String _selectedPayment = 'Semua';

  // Seed Data Transaksi Penjualan / Jasa (Screen 12)
  final List<TransaksiRecord> _salesTransactions = [
    TransaksiRecord(
      code: '#TRX-005',
      dateTime: DateTime(2026, 9, 20, 8, 30),
      payment: 'QRIS',
      amount: 40000,
      customer: 'Dian Pratama',
      vehicle: 'Yamaha NMAX',
      service: 'Tambal Tubeless + Cairan Ban',
    ),
    TransaksiRecord(
      code: '#TRX-004',
      dateTime: DateTime(2026, 9, 20, 10, 15),
      payment: 'TUNAI',
      amount: 95000,
      customer: 'Rudi Hartono',
      vehicle: 'Honda Supra X 125',
      service: 'Bersihkan Karburator + Rantai Roda',
    ),
    TransaksiRecord(
      code: '#TRX-003',
      dateTime: DateTime(2026, 9, 19, 14, 20),
      payment: 'TUNAI',
      amount: 80000,
      customer: 'Ibu Sri Wahyuni',
      vehicle: 'Yamaha Mio M3',
      service: 'Ganti Oli Mesin & Gardan',
    ),
    TransaksiRecord(
      code: '#TRX-002',
      dateTime: DateTime(2026, 9, 18, 11, 0),
      payment: 'QRIS',
      amount: 130000,
      customer: 'Ahmad Fauzi',
      vehicle: 'Honda Vario 160',
      service: 'Servis CVT & Rem + Roller + Kampas',
    ),
    TransaksiRecord(
      code: '#TRX-001',
      dateTime: DateTime(2026, 9, 17, 9, 10),
      payment: 'TUNAI',
      amount: 105000,
      customer: 'Budi Santoso',
      vehicle: 'Honda Beat FI',
      service: 'Servis Ringan + Oli MPX2 + Busi',
    ),
  ];

  // Seed Data Transaksi Pembelian / Restock (Screen 12B)
  final List<PembelianRecord> _purchaseTransactions = [
    PembelianRecord(
      code: '#BELI-005',
      dateTime: DateTime(2026, 10, 5),
      buyerName: 'Sugeng Yulianto',
      supplier: 'Toko Sumber Jaya',
      items: [
        RestockItemModel(
          id: '1',
          name: 'Velg Jari-jari 125',
          category: 'velg',
          buyPrice: 90000,
          quantity: 10,
        ),
        RestockItemModel(
          id: '2',
          name: 'Oli MPX2',
          category: 'oli',
          buyPrice: 60000,
          quantity: 20,
        ),
      ],
      totalAmount: 2100000,
      status: 'LUNAS',
    ),
    PembelianRecord(
      code: '#BELI-004',
      dateTime: DateTime(2026, 10, 12),
      buyerName: 'Sugeng Yulianto',
      supplier: 'PT Astra Motor Parts',
      items: [
        RestockItemModel(
          id: '3',
          name: 'Kampas Rem Depan',
          category: 'rem',
          buyPrice: 40000,
          quantity: 15,
        ),
        RestockItemModel(
          id: '4',
          name: 'Busi NGK',
          category: 'kelistrikan',
          buyPrice: 20000,
          quantity: 20,
        ),
      ],
      totalAmount: 875000,
      status: 'LUNAS',
    ),
    PembelianRecord(
      code: '#BELI-003',
      dateTime: DateTime(2026, 10, 18),
      buyerName: 'Sugeng Yulianto',
      supplier: 'Distributor Ban FDR',
      items: [
        RestockItemModel(
          id: '5',
          name: 'Ban Luar Tubeless FDR 90/90-14',
          category: 'ban',
          buyPrice: 150000,
          quantity: 8,
        ),
      ],
      totalAmount: 1480000,
      status: 'LUNAS',
    ),
    PembelianRecord(
      code: '#BELI-002',
      dateTime: DateTime(2026, 10, 22),
      buyerName: 'Sugeng Yulianto',
      supplier: 'PT Yamalube Indonesia',
      items: [
        RestockItemModel(
          id: '6',
          name: 'Oli Yamalube Silver 0.8L',
          category: 'oli',
          buyPrice: 35000,
          quantity: 24,
        ),
      ],
      totalAmount: 840000,
      status: 'LUNAS',
    ),
    PembelianRecord(
      code: '#BELI-001',
      dateTime: DateTime(2026, 10, 26),
      buyerName: 'Sugeng Yulianto',
      supplier: 'Grosir Jaya Part',
      items: [
        RestockItemModel(
          id: '7',
          name: 'Roller Set Honda Beat FI (11g)',
          category: 'cvt',
          buyPrice: 28000,
          quantity: 12,
        ),
      ],
      totalAmount: 480000,
      status: 'LUNAS',
    ),
  ];

  String _formatRupiah(int nominal) {
    final str = nominal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String _formatDateIso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // --- POPUP DATE PICKER DIALOG SESUAI REQUEST USER ---
  Future<void> _openDatePickerPopup({required bool isStart}) async {
    DateTime tempDate = isStart ? _startDate : _endDate;
    DateTime viewMonth = DateTime(tempDate.year, tempDate.month, 1);
    String viewMode = 'day'; // 'day' | 'month' | 'year'

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = DateUtils.getDaysInMonth(viewMonth.year, viewMonth.month);
            final firstDayOffset = DateTime(viewMonth.year, viewMonth.month, 1).weekday % 7; // Sunday = 0

            const monthNames = [
              'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
              'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
            ];

            // Daftar tahun dinamis sesuai tahun saat ini (10 tahun ke belakang s/d 25 tahun ke depan)
            final int currentYear = DateTime.now().year;
            final List<int> yearsList = List.generate(36, (i) => (currentYear - 10) + i);

            return Dialog(
              backgroundColor: const Color(0xFF151821),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: cardBorder, width: 1),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 345),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bulan & Tahun (Klik untuk Timpa Pop-up Pilih Bulan / Tahun)
                    Row(
                      children: [
                        // Tombol Pilih Bulan (Timpa Pop-up)
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              viewMode = (viewMode == 'month') ? 'day' : 'month';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: viewMode == 'month' ? accentRed.withValues(alpha: 0.2) : cardBorder.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: viewMode == 'month' ? accentRed : cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  monthNames[viewMonth.month - 1],
                                  style: TextStyle(
                                    color: viewMode == 'month' ? accentRed : textWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  viewMode == 'month' ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                  color: viewMode == 'month' ? accentRed : textMuted,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Tombol Pilih Tahun (Timpa Pop-up)
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              viewMode = (viewMode == 'year') ? 'day' : 'year';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: viewMode == 'year' ? accentRed.withValues(alpha: 0.2) : cardBorder.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: viewMode == 'year' ? accentRed : cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${viewMonth.year}',
                                  style: TextStyle(
                                    color: viewMode == 'year' ? accentRed : textWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  viewMode == 'year' ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                  color: viewMode == 'year' ? accentRed : textMuted,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Tombol Navigasi Prev/Next Bulan (hanya saat mode hari)
                        if (viewMode == 'day') ...[
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                viewMonth = DateTime(viewMonth.year, viewMonth.month - 1, 1);
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2333),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Center(
                                child: Icon(Icons.chevron_left_rounded, color: textWhite, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                viewMonth = DateTime(viewMonth.year, viewMonth.month + 1, 1);
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2333),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Center(
                                child: Icon(Icons.chevron_right_rounded, color: textWhite, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // BODY TAMPILAN TIMPA POP-UP (Bulan / Tahun / Hari)
                    if (viewMode == 'month') ...[
                      // 1. Grid Pilihan Bulan
                      SizedBox(
                        height: 230,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 12,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final isCurrentMonth = (index + 1) == viewMonth.month;
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  viewMonth = DateTime(viewMonth.year, index + 1, 1);
                                  viewMode = 'day';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentMonth ? const Color(0xFF007BFF) : inputBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentMonth ? const Color(0xFF007BFF) : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    monthNames[index],
                                    style: TextStyle(
                                      color: isCurrentMonth ? textWhite : const Color(0xFFCBD5E1),
                                      fontSize: 12,
                                      fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (viewMode == 'year') ...[
                      // 2. Grid Pilihan Tahun (Scrollable & Update Dinamis)
                      SizedBox(
                        height: 230,
                        child: GridView.builder(
                          itemCount: yearsList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final year = yearsList[index];
                            final isCurrentYear = year == viewMonth.year;
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  viewMonth = DateTime(year, viewMonth.month, 1);
                                  viewMode = 'day';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentYear ? const Color(0xFF007BFF) : inputBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentYear ? const Color(0xFF007BFF) : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$year',
                                    style: TextStyle(
                                      color: isCurrentYear ? textWhite : const Color(0xFFCBD5E1),
                                      fontSize: 13,
                                      fontWeight: isCurrentYear ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // 3. Grid Kalender Hari (Normal)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Text('Min', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Sen', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Sel', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Rab', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Kam', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Jum', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Sab', style: TextStyle(color: textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 42,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final dayNumber = index - firstDayOffset + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox();
                          }

                          final currentCalDate = DateTime(viewMonth.year, viewMonth.month, dayNumber);
                          final isSelected = currentCalDate.year == tempDate.year &&
                              currentCalDate.month == tempDate.month &&
                              currentCalDate.day == tempDate.day;

                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempDate = currentCalDate;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF007BFF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    color: isSelected ? textWhite : const Color(0xFFCBD5E1),
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Footer Dialog: Tombol Today, Cancel, OK
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setDialogState(() {
                              tempDate = now;
                              viewMonth = DateTime(now.year, now.month, 1);
                              viewMode = 'day';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: textWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            if (isStart) {
                              setState(() => _startDate = tempDate);
                            } else {
                              setState(() => _endDate = tempDate);
                            }
                            Navigator.pop(dialogCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: textWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('OK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF475569),
                            foregroundColor: textWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyQuickPeriod(String period) {
    setState(() {
      _selectedQuickPeriod = period;
      final now = DateTime(2026, 10, 26);
      if (period == '1 Hari') {
        _startDate = now;
        _endDate = now;
      } else if (period == '7 Hari') {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (period == '30 Hari') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      } else {
        _startDate = DateTime(2026, 9, 1);
        _endDate = DateTime(2026, 10, 31);
      }
    });
  }

  List<TransaksiRecord> get _filteredSales {
    return _salesTransactions.where((t) {
      if (_selectedPayment != 'Semua' &&
          t.payment.toUpperCase() != _selectedPayment.toUpperCase()) {
        return false;
      }
      final dateOnly = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
      final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);

      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
          (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }).toList();
  }

  List<PembelianRecord> get _filteredPurchases {
    return _purchaseTransactions.where((p) {
      final dateOnly = DateTime(p.dateTime.year, p.dateTime.month, p.dateTime.day);
      final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);

      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
          (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }).toList();
  }

  void _openTambahPembelian() async {
    final newBeli = await Navigator.push<PembelianRecord>(
      context,
      MaterialPageRoute(
        builder: (context) => PengadaanRestockPage(userData: widget.userData),
      ),
    );

    if (newBeli != null) {
      setState(() {
        _purchaseTransactions.insert(0, newBeli);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF143322),
            content: Text('Pembelian ${newBeli.code} berhasil disimpan & stok bertambah!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _filteredSales;
    final filteredPurchases = _filteredPurchases;

    final int totalPenjualan = filteredSales.fold(0, (sum, t) => sum + t.amount);
    final int totalPembelian = filteredPurchases.fold(0, (sum, p) => sum + p.totalAmount);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Judul & Subjudul Info)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeTab == 0
                            ? '${filteredSales.length} Transaksi • ${_formatRupiah(totalPenjualan)}'
                            : '${filteredPurchases.length} Pembelian • ${_formatRupiah(totalPembelian)}',
                        style: TextStyle(
                          color: _activeTab == 0 ? accentGreen : const Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Tab Segmented Sesuai Penpot Screen 12 & Screen 12B
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    _buildMainTabSegment(0, 'Transaksi Penjualan / Jasa'),
                    const SizedBox(width: 4),
                    _buildMainTabSegment(1, 'Transaksi Pembelian'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Date Range Selector Bar Pop-up (Start & End Date)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Start Date Input Box
                  Expanded(
                    child: _buildDateBox(
                      label: 'Start',
                      dateStr: _formatDateIso(_startDate),
                      onTap: () => _openDatePickerPopup(isStart: true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, color: textDim, size: 14),
                  ),
                  // End Date Input Box
                  Expanded(
                    child: _buildDateBox(
                      label: 'End',
                      dateStr: _formatDateIso(_endDate),
                      onTap: () => _openDatePickerPopup(isStart: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Quick Duration Pills: 1 Hari | 7 Hari | 30 Hari
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _activeTab == 0
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickPill('1 Hari'),
                          const SizedBox(width: 8),
                          _buildQuickPill('7 Hari'),
                          const SizedBox(width: 8),
                          _buildQuickPill('30 Hari'),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 16, color: cardBorder),
                          const SizedBox(width: 14),
                          _buildPaymentChip('Semua'),
                          const SizedBox(width: 6),
                          _buildPaymentChip('QRIS'),
                          const SizedBox(width: 6),
                          _buildPaymentChip('TUNAI'),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        _buildQuickPill('1 Hari', isExpanded: true),
                        const SizedBox(width: 8),
                        _buildQuickPill('7 Hari', isExpanded: true),
                        const SizedBox(width: 8),
                        _buildQuickPill('30 Hari', isExpanded: true),
                      ],
                    ),
            ),
            const SizedBox(height: 10),

            // 5. Daftar Transaksi (Tab 0: Penjualan / Tab 1: Pembelian)
            Expanded(
              child: _activeTab == 0
                  ? _buildSalesList(filteredSales)
                  : _buildPurchasesList(filteredPurchases),
            ),

            // 6. Sticky Red Button (Tambah Transaksi / Tambah Pembelian)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_activeTab == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KasirTransaksiPage(
                            userData: widget.userData,
                          ),
                        ),
                      );
                    } else {
                      _openTambahPembelian();
                    }
                  },
                  icon: const Icon(Icons.add, color: textWhite, size: 20),
                  label: Text(
                    _activeTab == 0 ? 'Tambah Transaksi Baru' : 'Tambah Pembelian Baru',
                    style: const TextStyle(
                      color: textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (widget.showBottomNav == true)
          ? MotoBottomNav(
              currentIndex: 1,
              userData: widget.userData,
            )
          : null,
    );
  }

  // --- KOMPONEN WIDGET ---

  Widget _buildMainTabSegment(int index, String title) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentRed : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? textWhite : textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required String dateStr,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: textDim, fontSize: 8.5)),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(color: textWhite, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: textDim, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPill(String label, {bool isExpanded = false}) {
    final isSelected = _selectedQuickPeriod == label;
    final content = GestureDetector(
      onTap: () => _applyQuickPeriod(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentRed : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? accentRed : cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textWhite : textMuted,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(child: content);
    }
    return content;
  }

  Widget _buildPaymentChip(String payment) {
    final isSelected = _selectedPayment == payment;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = payment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16253B) : const Color(0xFF10131B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? accentBlue : cardBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          payment,
          style: TextStyle(
            color: isSelected ? accentBlue : textDim,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- LIST TRANSAKSI PENJUALAN (Screen 12) ---
  Widget _buildSalesList(List<TransaksiRecord> list) {
    if (list.isEmpty) return _buildEmptyState('Tidak ada transaksi penjualan pada periode ini.');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trx = list[index];
        final isQris = trx.payment == 'QRIS';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotaPembayaranPage(
                  noNota: trx.code,
                  waktu: trx.timeFormatted,
                  pelanggan: '${trx.customer} (${trx.vehicle})',
                  kasir: widget.userData?['nama_lengkap'] ?? 'Sri Ekowati',
                  items: [
                    KasirItemModel(
                      id: '1',
                      name: trx.service,
                      category: 'Layanan Servis',
                      subInfo: 'Transaksi Kasir',
                      price: trx.amount,
                      quantity: 1,
                      isService: true,
                    ),
                  ],
                  totalBayar: trx.amount,
                  tunaiDiterima: trx.amount,
                  paymentMethod: isQris ? 'QRIS' : 'Tunai',
                  userData: widget.userData,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${trx.code} • ${trx.timeFormatted}',
                      style: const TextStyle(
                        color: textDim,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isQris ? const Color(0xFF0C243B) : const Color(0xFF0F2E1E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isQris ? const Color(0xFF1E40AF) : const Color(0xFF166534),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        trx.payment,
                        style: TextStyle(
                          color: isQris ? accentBlue : accentGreen,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRupiah(trx.amount),
                      style: const TextStyle(
                        color: accentGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trx.customer} • ${trx.vehicle}',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trx.service,
                        style: const TextStyle(color: textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('›', style: TextStyle(color: textMuted, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LIST TRANSAKSI PEMBELIAN (Screen 12B) ---
  Widget _buildPurchasesList(List<PembelianRecord> list) {
    if (list.isEmpty) return _buildEmptyState('Tidak ada transaksi pembelian pada periode ini.');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Code & Date, Badge LUNAS, Total Amount (Merah)
              Row(
                children: [
                  Text(
                    '${item.code} • ${item.dateFormatted}',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2E1E),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF166534), width: 0.8),
                    ),
                    child: const Text(
                      'LUNAS',
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatRupiah(item.totalAmount),
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Buyer & Supplier
              Text(
                '${item.buyerName} • ${item.supplier}',
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              // Row 3: Items summary & Chevron
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.summaryItems,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('›', style: TextStyle(color: textMuted, fontSize: 16)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: textDim, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(color: textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
