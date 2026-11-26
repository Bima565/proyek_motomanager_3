import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../components/custom_calendar_dialog.dart';
import '../components/moto_bottom_nav.dart';
import '../components/rupiah_formatter.dart';
import '../services/barang_service.dart';
import '../services/laporan_pdf_service.dart';
import '../services/pembelian_service.dart';
import '../services/transaksi_service.dart';
import 'beranda/rincian_omzet_6bulan.dart';
import 'beranda/rincian_transaksi_harian.dart';

/// Screen 7B - (FR09) Laporan Pendapatan & Analitik Bengkel
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
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  String _selectedFilter = '30 Hari';
  int _selectedTrenYear = 2026;
  int _selectedSemester = 2; // 1 = Jan - Jun, 2 = Jul - Des
  int? _tappedMonthIndex;
  int? _tappedDayIndex; // 1 = Sen, ..., 7 = Min
  late DateTime _startDate;
  late DateTime _endDate;
  bool _hasInitializedDates = false;
  bool _userPickedStartDate = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTrenYear = now.year >= 2026 ? now.year : 2026;
    _selectedSemester = now.month <= 6 ? 1 : 2;
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate.subtract(const Duration(days: 29));
  }

  void _syncFilterPill() {
    final diff = _endDate.difference(_startDate).inDays;
    final bool sameDay = _startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day;

    if (sameDay) {
      _selectedFilter = '1 Hari';
    } else if (diff == 6) {
      _selectedFilter = '7 Hari';
    } else if (diff == 29 || diff == 30) {
      _selectedFilter = '30 Hari';
    } else {
      _selectedFilter = '';
    }
  }

  void _applyQuickFilter(String label) {
    setState(() {
      _selectedFilter = label;
      _tappedDayIndex = null;
      if (_userPickedStartDate) {
        // Jika user baru memilih tanggal awal (misal 01/11/2026), hitung maju dari _startDate
        if (label == '1 Hari') {
          _endDate = _startDate;
        } else if (label == '7 Hari') {
          _endDate = _startDate.add(const Duration(days: 6));
        } else if (label == '30 Hari') {
          _endDate = _startDate.add(const Duration(days: 29));
        }
      } else {
        final now = DateTime.now();
        _endDate = DateTime(now.year, now.month, now.day);
        if (label == '1 Hari') {
          _startDate = _endDate;
        } else if (label == '7 Hari') {
          _startDate = _endDate.subtract(const Duration(days: 6));
        } else if (label == '30 Hari') {
          _startDate = _endDate.subtract(const Duration(days: 29));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            TransaksiService().transactionsNotifier,
            BarangService().barangsNotifier,
            PembelianService().pembelianNotifier,
          ]),
          builder: (context, _) {
            return _buildContent();
          },
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

  /// Helper untuk mencari modal beli (buyPrice) dari suatu sparepart
  int _findPartBuyPrice(
    TransaksiItemModel item,
    List<BarangModel> barangs,
    List<PembelianRecord> pembelians,
  ) {
    final bool isJasa = item.isService == true ||
        item.category.toLowerCase().contains('jasa') ||
        item.category.toLowerCase().contains('servis');
    if (isJasa) return 0;

    int resolvedPrice = 0;

    if (item.buyPrice != null && item.buyPrice! > 0) {
      resolvedPrice = item.buyPrice!;
    } else {
      // 1. Cari berdasarkan ID di BarangService
      if (item.id.isNotEmpty) {
        final byId = barangs.where((b) => b.id == item.id);
        if (byId.isNotEmpty && byId.first.buyPrice > 0) {
          resolvedPrice = byId.first.buyPrice;
        }
      }

      // 2. Cari berdasarkan Nama di BarangService
      if (resolvedPrice == 0) {
        final normName = item.name.trim().toLowerCase();
        final byName = barangs.where((b) => b.name.trim().toLowerCase() == normName);
        if (byName.isNotEmpty && byName.first.buyPrice > 0) {
          resolvedPrice = byName.first.buyPrice;
        }
      }

      // 3. Cari di Riwayat Transaksi Pembelian (Restock)
      if (resolvedPrice == 0) {
        final normName = item.name.trim().toLowerCase();
        for (final p in pembelians) {
          for (final r in p.items) {
            if ((r.id.isNotEmpty && r.id == item.id) ||
                r.name.trim().toLowerCase() == normName) {
              if (r.buyPrice > 0) {
                resolvedPrice = r.buyPrice;
                break;
              }
            }
          }
          if (resolvedPrice > 0) break;
        }
      }
    }

    // Pastikan modal beli tidak melebihi harga jual agar laba part tetap positif wajar
    if (resolvedPrice > 0 && resolvedPrice < item.price) {
      return resolvedPrice;
    }

    // 4. Fallback wajar (estimasi modal ~70% dari harga jual toko)
    return (item.price * 0.70).round();
  }

  Widget _buildContent() {
    final allTrx = TransaksiService().transactions;
    final allBarang = BarangService().barangs;
    final allPembelian = PembelianService().pembelianList;

    // Filter transaksi yang valid (bukan status 'batal')
    final validTrx = allTrx.where((t) => t.status.toLowerCase() != 'batal').toList();
    final bool hasAnyData = validTrx.isNotEmpty || allPembelian.isNotEmpty;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Inisialisasi pintar: hanya geser ke tanggal transaksi terbaru jika 30 hari terakhir benar-benar kosong
    if (!_hasInitializedDates && hasAnyData) {
      _hasInitializedDates = true;
      final defaultStart = today.subtract(const Duration(days: 29));
      final defaultEnd = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
      final bool hasRecentWindow = validTrx.any((t) =>
              !t.dateTime.isBefore(defaultStart) && !t.dateTime.isAfter(defaultEnd)) ||
          allPembelian.any((p) =>
              !p.dateTime.isBefore(defaultStart) && !p.dateTime.isAfter(defaultEnd));

      if (hasRecentWindow) {
        _endDate = today;
        _startDate = defaultStart;
      } else {
        DateTime? latestDate;
        if (validTrx.isNotEmpty) {
          latestDate = validTrx.first.dateTime;
        }
        if (allPembelian.isNotEmpty) {
          final firstBeliDate = allPembelian.first.dateTime;
          if (latestDate == null || firstBeliDate.isAfter(latestDate)) {
            latestDate = firstBeliDate;
          }
        }
        if (latestDate != null) {
          _endDate = DateTime(latestDate.year, latestDate.month, latestDate.day);
          _startDate = _endDate.subtract(const Duration(days: 29));
        }
      }
    }

    // Filter transaksi sesuai rentang tanggal (_startDate s/d _endDate)
    final startWindow = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final endWindow = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59, 999);

    final filteredTrx = validTrx.where((t) {
      return !t.dateTime.isBefore(startWindow) && !t.dateTime.isAfter(endWindow);
    }).toList();

    // Kalkulasi Data Keuangan Berdasarkan Rentang Tanggal Terpilih
    int totalOmzetPart = 0;
    int totalOmzetJasa = 0;
    int countServis = 0;
    int countPart = 0;
    int totalHppPart = 0;

    for (final trx in filteredTrx) {
      for (final item in trx.items) {
        final bool isJasa = item.isService == true ||
            item.category.toLowerCase().contains('jasa') ||
            item.category.toLowerCase().contains('servis');
        if (isJasa) {
          totalOmzetJasa += item.price * item.quantity;
          countServis += item.quantity;
        } else {
          totalOmzetPart += item.price * item.quantity;
          countPart += item.quantity;
          final buyPrice = _findPartBuyPrice(item, allBarang, allPembelian);
          totalHppPart += buyPrice * item.quantity;
        }
      }
    }

    // Kalkulasi Biaya Pengeluaran Pembelian Sparepart (Stok) sesuai rentang tanggal terpilih
    int totalPengeluaranBeli = 0;
    int countBeli = 0;
    for (final p in allPembelian) {
      if (p.status.toUpperCase() != 'BATAL') {
        if (!p.dateTime.isBefore(startWindow) && !p.dateTime.isAfter(endWindow)) {
          totalPengeluaranBeli += p.totalAmount;
          countBeli++;
        }
      }
    }

    // Nilai terhitung dinamis dari Firestore (fallback ke mock bila database kosong)
    final int omzetTotal = hasAnyData ? (totalOmzetPart + totalOmzetJasa) : 2750000;
    final int displayedOmzetPart = hasAnyData ? totalOmzetPart : 1510000;
    final int displayedOmzetJasa = hasAnyData ? totalOmzetJasa : 1240000;
    final int displayedCountPart = hasAnyData ? countPart : 26;
    final int displayedCountServis = hasAnyData ? countServis : 38;

    // Laba Part = Harga Jual - Modal Beli (HPP)
    final int keuntunganPart = hasAnyData ? math.max(0, totalOmzetPart - totalHppPart) : 460000;
    // Jasa Servis = 100% laba langsung (karena tanpa modal part)
    final int keuntunganJasa = hasAnyData ? totalOmzetJasa : 1240000;

    // 1. OMZET & MARGIN BENGKEL (Total Kotor Penjualan dari Servis & Sparepart Terjual)
    final int labaKotor = hasAnyData ? (keuntunganPart + keuntunganJasa) : 1700000;
    final double marginOmzet = omzetTotal > 0 ? (labaKotor / omzetTotal * 100) : (hasAnyData ? 0.0 : 61.8);

    // 2. PENGELUARAN (Total Biaya Belanja Sparepart untuk Stok / Restock dari Database)
    final int pengeluaranTotal = totalPengeluaranBeli;

    // 3. KEUNTUNGAN BERSIH (Keuntungan Mengalami Pengurangan Karena Belanja Restock Stok dan Biaya Operasional)
    final int bebanOperasional = hasAnyData ? (labaKotor * 0.205).round() : 350000;
    final int baseKeuntungan = hasAnyData ? math.max(0, labaKotor - bebanOperasional) : 1350000;
    final int keuntunganBersih = math.max(0, baseKeuntungan - pengeluaranTotal);

    final double partPercent = omzetTotal > 0 ? (displayedOmzetPart / omzetTotal) : (hasAnyData ? 0.0 : 0.55);
    final double servisPercent = omzetTotal > 0 ? (displayedOmzetJasa / omzetTotal) : (hasAnyData ? 0.0 : 0.45);

    // 2. Chart Aktivitas Pendapatan Harian (Sen - Min) sinkron dengan box tanggalan (_startDate s/d _endDate)
    final Map<int, Map<String, int>> dailyStats = {
      1: {'servis': 0, 'part': 0, 'total': 0}, // Sen
      2: {'servis': 0, 'part': 0, 'total': 0}, // Sel
      3: {'servis': 0, 'part': 0, 'total': 0}, // Rab
      4: {'servis': 0, 'part': 0, 'total': 0}, // Kam
      5: {'servis': 0, 'part': 0, 'total': 0}, // Jum
      6: {'servis': 0, 'part': 0, 'total': 0}, // Sab
      7: {'servis': 0, 'part': 0, 'total': 0}, // Min
    };

    final bool isSingleDayFilter =
        _startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day;
    final DateTime weekMonday = _endDate.subtract(Duration(days: _endDate.weekday - 1));
    final DateTime weekSunday = weekMonday.add(const Duration(days: 6));

    // Jika mode '1 Hari', tampilkan minggu berjalan (Sen-Min) dari tanggal terpilih agar perbandingan harian tetap terlihat
    final List<TransaksiPenjualanModel> chartSourceTrx = isSingleDayFilter
        ? validTrx.where((t) {
            final startW = DateTime(weekMonday.year, weekMonday.month, weekMonday.day, 0, 0, 0);
            final endW = DateTime(weekSunday.year, weekSunday.month, weekSunday.day, 23, 59, 59, 999);
            return !t.dateTime.isBefore(startW) && !t.dateTime.isAfter(endW);
          }).toList()
        : filteredTrx;

    if (hasAnyData) {
      for (final trx in chartSourceTrx) {
        final dayIndex = trx.dateTime.weekday;
        if (dailyStats.containsKey(dayIndex)) {
          int s = 0;
          int p = 0;
          for (final item in trx.items) {
            final bool isJasa = item.isService == true ||
                item.category.toLowerCase().contains('jasa') ||
                item.category.toLowerCase().contains('servis');
            if (isJasa) {
              s += item.price * item.quantity;
            } else {
              p += item.price * item.quantity;
            }
          }
          dailyStats[dayIndex]!['servis'] = (dailyStats[dayIndex]!['servis'] ?? 0) + s;
          dailyStats[dayIndex]!['part'] = (dailyStats[dayIndex]!['part'] ?? 0) + p;
          dailyStats[dayIndex]!['total'] = (dailyStats[dayIndex]!['total'] ?? 0) + s + p;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          _buildHeader(),
          const SizedBox(height: 16),

          // 2. Card Aktivitas Pendapatan Harian (Tren omzet di atas chart dihilangkan sesuai permintaan)
          _buildMainOmzetCard(
            hasData: hasAnyData,
            dailyStats: dailyStats,
            validTrx: validTrx,
            allBarang: allBarang,
            allPembelian: allPembelian,
          ),
          const SizedBox(height: 16),

          // 3. Filter Rentang Tanggal & Periode
          _buildDateAndFilterSection(
            isFilterEmpty: filteredTrx.isEmpty,
            hasData: hasAnyData,
          ),
          const SizedBox(height: 18),

          // 4. Section Ringkasan Portofolio Keuangan (Omzet, Pengeluaran, Keuntungan Bersih)
          _buildPortofolioKeuanganSection(
            omzet: omzetTotal,
            marginOmzet: marginOmzet,
            pengeluaran: pengeluaranTotal,
            countBeli: countBeli,
            pendapatan: keuntunganBersih,
          ),
          const SizedBox(height: 16),

          // 5. Card Sumber Pendapatan (Donut Chart)
          _buildSumberPendapatanCard(
            displayedOmzetPart: displayedOmzetPart,
            displayedOmzetJasa: displayedOmzetJasa,
            displayedCountPart: displayedCountPart,
            displayedCountServis: displayedCountServis,
            partPercent: partPercent,
            servisPercent: servisPercent,
          ),
          const SizedBox(height: 16),

          // 6. Card Tren Laba Bulanan (Multi-Line Chart)
          _buildTrenLabaBulananCard(
            validTrx: validTrx,
            allBarang: allBarang,
            allPembelian: allPembelian,
          ),
        ],
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Laporan Pendapatan',
          style: TextStyle(
            color: textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Bengkel & Toko Sparepart',
          style: TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- 2. MAIN OMZET & DAILY ACTIVITY CARD ---
  Widget _buildMainOmzetCard({
    required bool hasData,
    required Map<int, Map<String, int>> dailyStats,
    required List<TransaksiPenjualanModel> validTrx,
    required List<BarangModel> allBarang,
    required List<PembelianRecord> allPembelian,
  }) {
    // Hitung bar chart data
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dayNames = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'};
    int maxVal = 1;
    for (int i = 1; i <= 7; i++) {
      final t = dailyStats[i]?['total'] ?? 0;
      if (t > maxVal) maxVal = t;
    }

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
          // Aktivitas Pendapatan Harian + Periode Sinkron + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktivitas Pendapatan Harian',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (context) {
                        final bool isSingleDay =
                            _startDate.year == _endDate.year &&
                            _startDate.month == _endDate.month &&
                            _startDate.day == _endDate.day;
                        final monday = _endDate.subtract(Duration(days: _endDate.weekday - 1));
                        final sunday = monday.add(const Duration(days: 6));
                        final String periodInfo = isSingleDay
                            ? 'Minggu ${monday.day}/${monday.month} – ${sunday.day}/${sunday.month} (Fokus ${dayNames[_endDate.weekday]})'
                            : 'Periode ${_startDate.day}/${_startDate.month} – ${_endDate.day}/${_endDate.month}';
                        return Text(
                          periodInfo,
                          style: const TextStyle(
                            color: textDim,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(accentRed, 'Servis'),
                  const SizedBox(width: 10),
                  _buildLegendDot(accentBlue, 'Part'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dual Bar Chart (Sen - Min) - Interaktif saat ditekan
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final dayNum = index + 1; // 1 to 7
                final dayLabel = days[index];

                if (!hasData) {
                  // Mock baseline values sesuai desain gambar
                  final mockHeights = [
                    {'val': '75k', 's': 30.0, 'p': 38.0, 'hi': false},
                    {'val': '85k', 's': 36.0, 'p': 44.0, 'hi': false},
                    {'val': '80k', 's': 34.0, 'p': 42.0, 'hi': false},
                    {'val': '95k', 's': 42.0, 'p': 50.0, 'hi': false},
                    {'val': '90k', 's': 40.0, 'p': 46.0, 'hi': false},
                    {'val': '140k', 's': 58.0, 'p': 68.0, 'hi': true},
                    {'val': '110k', 's': 48.0, 'p': 56.0, 'hi': false},
                  ];
                  final m = mockHeights[index];
                  return _buildBarDay(
                    dayLabel,
                    m['val'] as String,
                    m['s'] as double,
                    m['p'] as double,
                    m['hi'] as bool,
                  );
                }

                // Nilai Riil dari Database
                final sVal = dailyStats[dayNum]?['servis'] ?? 0;
                final pVal = dailyStats[dayNum]?['part'] ?? 0;
                final tot = sVal + pVal;

                final double sH = maxVal > 0 ? (sVal / maxVal * 55).clamp(4.0, 65.0) : 4.0;
                final double pH = maxVal > 0 ? (pVal / maxVal * 65).clamp(4.0, 70.0) : 4.0;
                final bool isPeak = tot == maxVal && tot > 0;
                final bool isSingleDay =
                    _startDate.year == _endDate.year &&
                    _startDate.month == _endDate.month &&
                    _startDate.day == _endDate.day;
                final bool isFocusedDay = isSingleDay && dayNum == _endDate.weekday;
                final String valText = tot >= 1000000
                    ? '${(tot / 1000000).toStringAsFixed(1)}jt'
                    : (tot > 0 ? '${(tot / 1000).round()}k' : '0k');
                final bool isTapped = _tappedDayIndex == dayNum;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      if (_tappedDayIndex == dayNum) {
                        _tappedDayIndex = null;
                      } else {
                        _tappedDayIndex = dayNum;
                      }
                    });
                  },
                  child: _buildBarDay(
                    dayLabel,
                    valText,
                    sH,
                    pH,
                    isTapped || (_tappedDayIndex == null && (isFocusedDay || (!isSingleDay && isPeak))),
                    isSelected: isTapped,
                  ),
                );
              }),
            ),
          ),

          // Detail Card saat Bar Harian Ditekan (lengkap dengan tanggal pada periode tersebut)
          if (_tappedDayIndex != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                final bool isSingleDay =
                    _startDate.year == _endDate.year &&
                    _startDate.month == _endDate.month &&
                    _startDate.day == _endDate.day;
                final DateTime rangeStart = isSingleDay
                    ? _endDate.subtract(Duration(days: _endDate.weekday - 1))
                    : DateTime(_startDate.year, _startDate.month, _startDate.day);
                final DateTime rangeEnd = isSingleDay
                    ? rangeStart.add(const Duration(days: 6))
                    : DateTime(_endDate.year, _endDate.month, _endDate.day);

                final List<DateTime> matchingDates = [];
                DateTime cursor = rangeStart;
                int guard = 0;
                while (!cursor.isAfter(rangeEnd) && guard < 120) {
                  if (cursor.weekday == _tappedDayIndex) {
                    matchingDates.add(cursor);
                  }
                  cursor = cursor.add(const Duration(days: 1));
                  guard++;
                }

                String dateLabel = dayNames[_tappedDayIndex] ?? '';
                if (matchingDates.length == 1) {
                  final d = matchingDates.first;
                  dateLabel = '${dayNames[_tappedDayIndex]}, ${d.day} ${shortMonths[d.month - 1]} ${d.year}';
                } else if (matchingDates.length > 1) {
                  final sameMonth = matchingDates.every((d) => d.month == matchingDates.first.month && d.year == matchingDates.first.year);
                  if (sameMonth) {
                    final daysStr = matchingDates.map((d) => d.day.toString()).join(', ');
                    final mStr = shortMonths[matchingDates.first.month - 1];
                    dateLabel = '${dayNames[_tappedDayIndex]} ($daysStr $mStr ${matchingDates.first.year})';
                  } else {
                    final datesStr = matchingDates.map((d) => '${d.day} ${shortMonths[d.month - 1]}').join(', ');
                    dateLabel = '${dayNames[_tappedDayIndex]} ($datesStr)';
                  }
                }

                final int totVal = dailyStats[_tappedDayIndex]?['total'] ?? 0;
                final int srvVal = dailyStats[_tappedDayIndex]?['servis'] ?? 0;
                final int prtVal = dailyStats[_tappedDayIndex]?['part'] ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2433),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentYellow.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: accentYellow, size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRupiah(totVal),
                            style: const TextStyle(
                              color: accentYellow,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _tappedDayIndex = null;
                              });
                            },
                            child: const Icon(Icons.close_rounded, color: textDim, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jasa Servis: ${formatRupiah(srvVal)}  •  Sparepart: ${formatRupiah(prtVal)}',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Ketuk batang hari (Sen - Min) untuk melihat rincian omzet per hari',
                style: TextStyle(
                  color: textDim.withValues(alpha: 0.8),
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Tombol Unduh PDF (Pill Merah di Tengah)
          Center(
            child: SizedBox(
              width: 180,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  LaporanPdfService.showDownloadPdfDialog(
                    context: context,
                    allTransactions: validTrx,
                    allBarang: allBarang,
                    allPembelian: allPembelian,
                    initialStartDate: _startDate,
                    initialEndDate: _endDate,
                  );
                },
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                label: const Text(
                  'Unduh PDF',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentRed,
                  foregroundColor: textWhite,
                  elevation: 4,
                  shadowColor: accentRed.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarDay(String day, String value, double hServis, double hPart, bool isHighlight, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
              color: accentYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentYellow.withValues(alpha: 0.8), width: 1.2),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? accentYellow : textDim,
              fontSize: 9,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 7.5,
                height: hServis,
                decoration: BoxDecoration(
                  color: accentRed,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 2.5),
              Container(
                width: 7.5,
                height: hPart,
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            day,
            style: TextStyle(
              color: isHighlight ? accentYellow : textDim,
              fontSize: 10,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. FILTER RENTANG TANGGAL & HARI ---
  Widget _buildDateAndFilterSection({required bool isFilterEmpty, required bool hasData}) {
    return Column(
      children: [
        // Rentang Tanggal Row
        Row(
          children: [
            Expanded(
              child: _buildDateBox(
                '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                isHighlighted: true,
                onTap: () async {
                  final picked = await CustomCalendarDialog.show(
                    context,
                    initialDate: _startDate,
                  );
                  if (picked != null) {
                    setState(() {
                      _userPickedStartDate = true;
                      _startDate = DateTime(picked.year, picked.month, picked.day);
                      if (_startDate.isAfter(_endDate)) {
                        _endDate = _startDate;
                      }
                      _syncFilterPill();
                    });
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: textDim,
                size: 16,
              ),
            ),
            Expanded(
              child: _buildDateBox(
                '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                isHighlighted: false,
                onTap: () async {
                  final picked = await CustomCalendarDialog.show(
                    context,
                    initialDate: _endDate,
                  );
                  if (picked != null) {
                    setState(() {
                      _userPickedStartDate = false;
                      _endDate = DateTime(picked.year, picked.month, picked.day);
                      if (_endDate.isBefore(_startDate)) {
                        _startDate = _endDate;
                      }
                      _syncFilterPill();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Pills: 1 Hari, 7 Hari, 30 Hari
        Row(
          children: [
            Expanded(child: _buildFilterTab('1 Hari')),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterTab('7 Hari')),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterTab('30 Hari')),
          ],
        ),

        // Banner Informatif jika periode terpilih belum ada transaksi
        if (isFilterEmpty && hasData) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF19202E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: accentBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada transaksi di rentang tanggal ini. Ketuk tombol untuk melihat seluruh data:',
                    style: const TextStyle(color: textMuted, fontSize: 10.5),
                  ),
                ),
                GestureDetector(
                  onTap: () => _applyQuickFilter('30 Hari'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '30 Hari',
                      style: TextStyle(
                        color: accentBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateBox(String dateText, {required bool isHighlighted, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: const TextStyle(
                color: textWhite,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFF0E2A32) : const Color(0xFF1B202D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHighlighted ? const Color(0xFF14B8A6) : const Color(0xFF2D3548),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: isHighlighted ? const Color(0xFF14B8A6) : textDim,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final bool isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyQuickFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentRed : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: cardBorder, width: 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentRed.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? textWhite : textDim,
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. SECTION RINGKASAN PORTOFOLIO KEUANGAN ---
  Widget _buildPortofolioKeuanganSection({
    required int omzet,
    required double marginOmzet,
    required int pengeluaran,
    required int countBeli,
    required int pendapatan,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ringkasan Portofolio Keuangan',
              style: TextStyle(
                color: textWhite,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                DateTime targetDetailDate = _endDate;
                if (_tappedDayIndex != null) {
                  DateTime cursor = _endDate;
                  for (int i = 0; i < 7; i++) {
                    if (cursor.weekday == _tappedDayIndex) {
                      targetDetailDate = cursor;
                      break;
                    }
                    cursor = cursor.subtract(const Duration(days: 1));
                  }
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RincianTransaksiHarianPage(
                      userData: widget.userData,
                      initialDate: targetDetailDate,
                    ),
                  ),
                );
              },
              child: const Text(
                'Lihat Rincian ›',
                style: TextStyle(
                  color: accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Baris 1: Dua Kartu Berdampingan (OMZET & PENGELUARAN)
        Row(
          children: [
            // Kartu 1: OMZET (Aksen Biru - Total Penjualan Kotor)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131926),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E283C), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          color: accentBlue,
                          size: 18,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C2338),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF0369A1), width: 1),
                          ),
                          child: Text(
                            'Margin ${marginOmzet.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: accentBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'OMZET',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(omzet),
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Total Penjualan Kotor',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Kartu 2: PENGELUARAN (Aksen Oranye / Merah - Biaya Pembelian Sparepart untuk Stok)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22161A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3F1F27), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFFF87171),
                          size: 18,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B1820),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF991B1B), width: 1),
                          ),
                          child: Text(
                            countBeli > 0 ? '$countBeli Pembelian' : '0 Pembelian',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'PENGELUARAN',
                      style: TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(pengeluaran),
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Beli Sparepart Stok',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Baris 2: Kartu PENDAPATAN (Full Width - Aksen Hijau Bersih)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E17),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentGreen, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: accentGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'KEUNTUNGAN BERSIH',
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B291A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF15803D), width: 1),
                          ),
                          child: const Text(
                            'Kas Bersih',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(pendapatan),
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Keuntungan Bersih (Omzet - Operasional - Belanja Stok)',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 5. CARD SUMBER PENDAPATAN (DONUT CHART) ---
  Widget _buildSumberPendapatanCard({
    required int displayedOmzetPart,
    required int displayedOmzetJasa,
    required int displayedCountPart,
    required int displayedCountServis,
    required double partPercent,
    required double servisPercent,
  }) {
    final int roundPartPct = (partPercent * 100).round();
    final int roundServisPct = (servisPercent * 100).round();

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
          const Text(
            'Sumber Pendapatan',
            style: TextStyle(
              color: textWhite,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Donut Chart Lingkaran
              SizedBox(
                width: 86,
                height: 86,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    servisPercent: servisPercent,
                    barangPercent: partPercent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$roundPartPct%',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Part',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // Detail List Sumber
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jasa Servis (Square Box Red)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentRed,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jasa Servis ($roundServisPct%)',
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatRupiah(displayedOmzetJasa)} • $displayedCountServis servis',
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sparepart (Square Box Blue)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sparepart ($roundPartPct%)',
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatRupiah(displayedOmzetPart)} • $displayedCountPart pcs',
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 10.5,
                                ),
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

  Future<void> _showCustomYearDialog() async {
    final controller = TextEditingController(text: '$_selectedTrenYear');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Text(
          'Ketik Tahun',
          style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Contoh: 2026',
            hintStyle: const TextStyle(color: textDim),
            filled: true,
            fillColor: const Color(0xFF0E1015),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: accentBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton(
            onPressed: () {
              final y = int.tryParse(controller.text.trim());
              if (y != null && y >= 2000 && y <= 2100) {
                Navigator.pop(ctx, y);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTrenYear = result;
        _tappedMonthIndex = null;
      });
    }
  }

  Widget _buildTrenLabaDropdown() {
    final int currentYear = DateTime.now().year; // 2026
    final Set<int> allAvailableYears = {currentYear, _selectedTrenYear};
    for (final t in TransaksiService().transactions) {
      if (t.dateTime.year >= 2026) {
        allAvailableYears.add(t.dateTime.year);
      }
    }
    final sortedYears = allAvailableYears.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B202D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: '$_selectedTrenYear',
          dropdownColor: cardBg,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: textDim, size: 16),
          style: const TextStyle(
            color: textWhite,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          items: [
            ...sortedYears.map((yr) {
              return DropdownMenuItem<String>(
                value: '$yr',
                child: Text(
                  'Tahun $yr',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
            const DropdownMenuItem<String>(
              value: 'custom',
              child: Row(
                children: [
                  Icon(Icons.edit_calendar_outlined, size: 12, color: accentBlue),
                  SizedBox(width: 5),
                  Text(
                    'Ketik Tahun...',
                    style: TextStyle(
                      color: accentBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == 'custom') {
              _showCustomYearDialog();
            } else if (val != null) {
              setState(() {
                _selectedTrenYear = int.parse(val);
                _tappedMonthIndex = null;
              });
            }
          },
        ),
      ),
    );
  }

  // --- Tombol Geser Bulan Sederhana & Rapi (Semester 1: Jan-Jun, Semester 2: Jul-Des) ---
  Widget _buildSemesterSwitcher() {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D121D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSemesterTab(1, 'Januari – Juni', 'Semester 1'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSemesterTab(2, 'Juli – Desember', 'Semester 2'),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTab(int semester, String label, String sublabel) {
    final bool isSelected = _selectedSemester == semester;
    return GestureDetector(
      onTap: () {
        if (_selectedSemester != semester) {
          setState(() {
            _selectedSemester = semester;
            _tappedMonthIndex = null;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF162338) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: accentBlue.withValues(alpha: 0.6), width: 1)
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_circle_rounded, color: accentBlue, size: 11),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? textWhite : textDim,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. CARD TREN LABA BULANAN (MULTI-LINE CHART) ---
  Widget _buildTrenLabaBulananCard({
    required List<TransaksiPenjualanModel> validTrx,
    required List<BarangModel> allBarang,
    required List<PembelianRecord> allPembelian,
  }) {
    final List<String> allMonthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    // Tampilkan 6 bulan sesuai semester (Semester 1: Jan - Jun, Semester 2: Jul - Des)
    final int startMonth = _selectedSemester == 1 ? 1 : 7;
    final int endMonth = _selectedSemester == 1 ? 6 : 12;
    final List<String> displayMonths = allMonthNames.sublist(startMonth - 1, endMonth);

    // Hitung pemasukan omzet & laba bersih (keuntungan) per bulan dengan rumus identik dengan Portofolio Keuangan
    final Map<int, int> monthlyKotor = {};
    final Map<int, int> monthlyBersih = {};
    final Map<int, int> monthlyOmzetPart = {};
    final Map<int, int> monthlyOmzetJasa = {};
    final Map<int, int> monthlyHppPart = {};
    final Map<int, int> monthlyBeli = {};
    for (int m = 1; m <= 12; m++) {
      monthlyKotor[m] = 0;
      monthlyBersih[m] = 0;
      monthlyOmzetPart[m] = 0;
      monthlyOmzetJasa[m] = 0;
      monthlyHppPart[m] = 0;
      monthlyBeli[m] = 0;
    }

    for (final trx in validTrx) {
      if (trx.dateTime.year == _selectedTrenYear) {
        final m = trx.dateTime.month;
        for (final item in trx.items) {
          final bool isJasa = item.isService == true ||
              item.category.toLowerCase().contains('jasa') ||
              item.category.toLowerCase().contains('servis');
          if (isJasa) {
            monthlyOmzetJasa[m] = (monthlyOmzetJasa[m] ?? 0) + item.price * item.quantity;
          } else {
            monthlyOmzetPart[m] = (monthlyOmzetPart[m] ?? 0) + item.price * item.quantity;
            final buyPrice = _findPartBuyPrice(item, allBarang, allPembelian);
            monthlyHppPart[m] = (monthlyHppPart[m] ?? 0) + buyPrice * item.quantity;
          }
        }
      }
    }

    for (final p in allPembelian) {
      if (p.status.toUpperCase() != 'BATAL' && p.dateTime.year == _selectedTrenYear) {
        final m = p.dateTime.month;
        monthlyBeli[m] = (monthlyBeli[m] ?? 0) + p.totalAmount;
      }
    }

    for (int m = 1; m <= 12; m++) {
      final int omzetPartM = monthlyOmzetPart[m] ?? 0;
      final int omzetJasaM = monthlyOmzetJasa[m] ?? 0;
      final int hppPartM = monthlyHppPart[m] ?? 0;
      final int beliM = monthlyBeli[m] ?? 0;

      final int untungPartM = math.max(0, omzetPartM - hppPartM);
      final int labaKotorM = untungPartM + omzetJasaM;
      final int operasionalM = (labaKotorM * 0.205).round();
      final int baseKeuntunganM = math.max(0, labaKotorM - operasionalM);

      monthlyKotor[m] = omzetPartM + omzetJasaM;
      monthlyBersih[m] = math.max(0, baseKeuntunganM - beliM);
    }

    final now = DateTime.now();
    int maxMonthToDraw;
    if (_selectedTrenYear < now.year) {
      maxMonthToDraw = 6; // Tahun sebelumnya: semua 6 bulan sudah lewat
    } else if (_selectedTrenYear == now.year) {
      if (_selectedSemester == 1) {
        maxMonthToDraw = now.month >= 6 ? 6 : now.month;
      } else {
        if (now.month < 7) {
          maxMonthToDraw = 0; // Belum masuk semester 2
        } else {
          maxMonthToDraw = (now.month - 6).clamp(0, 6);
        }
      }
    } else {
      maxMonthToDraw = 0; // Tahun depan: garis belum ada
    }

    final List<double> labaKotorValues = [];
    final List<double> labaBersihValues = [];

    int sumKotor = 0;
    int countActive = 0;

    for (int m = startMonth; m <= endMonth; m++) {
      final int kotorRp = monthlyKotor[m] ?? 0;
      final int bersihRp = monthlyBersih[m] ?? 0;

      final double kVal = kotorRp > 0 ? (kotorRp / 1000000) : 0.0;
      final double bVal = bersihRp > 0 ? (bersihRp / 1000000) : 0.0;

      labaKotorValues.add(kVal);
      labaBersihValues.add(bVal);

      final int relativeIndex = m - startMonth;
      if (relativeIndex < maxMonthToDraw) {
        sumKotor += kotorRp;
        countActive++;
      }
    }

    final int avgKotor = countActive > 0 ? (sumKotor / countActive).round() : 0;

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
          // 1. Header Row (Judul, Dropdown Tahun, Detail) - Rapi & Bebas Overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Laba Bulanan',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '(Omzet vs Keuntungan Bersih)',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrenLabaDropdown(),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RincianOmzet6BulanPage(
                            userData: widget.userData,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2033),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E3A5F)),
                      ),
                      child: const Text(
                        'Detail ›',
                        style: TextStyle(
                          color: accentBlue,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Tombol Geser Bulan Sederhana (Full-Width, Sangat Rapi & Tidak Memakan Ruang)
          _buildSemesterSwitcher(),
          const SizedBox(height: 12),

          // Multi-Line Chart with Touch Interactivity & Swipe / Drag support
          LayoutBuilder(
            builder: (context, constraints) {
              final double chartWidth = constraints.maxWidth;
              const double leftMargin = 32.0;
              const double rightMargin = 12.0;
              final double usableWidth = chartWidth - leftMargin - rightMargin;
              final double stepX = usableWidth / (displayMonths.length - 1);

              void handleTouch(Offset localPos) {
                if (maxMonthToDraw <= 0) return;
                final double dx = localPos.dx;
                final int idx = ((dx - leftMargin + stepX / 2) / stepX).floor();
                if (idx >= 0 && idx < maxMonthToDraw && idx < displayMonths.length) {
                  setState(() {
                    _tappedMonthIndex = (_tappedMonthIndex == idx) ? null : idx;
                  });
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => handleTouch(details.localPosition),
                onPanUpdate: (details) => handleTouch(details.localPosition),
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -150) {
                      // Swipe kiri: Beralih ke Semester 2 (Jul - Des)
                      if (_selectedSemester == 1) {
                        setState(() {
                          _selectedSemester = 2;
                          _tappedMonthIndex = null;
                        });
                      }
                    } else if (details.primaryVelocity! > 150) {
                      // Swipe kanan: Beralih ke Semester 1 (Jan - Jun)
                      if (_selectedSemester == 2) {
                        setState(() {
                          _selectedSemester = 1;
                          _tappedMonthIndex = null;
                        });
                      }
                    }
                  }
                },
                child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrenLabaBulananPainter(
                      months: displayMonths,
                      labaKotorValues: labaKotorValues,
                      monthlyKotor: monthlyKotor,
                      labaBersihValues: labaBersihValues,
                      monthlyBersih: monthlyBersih,
                      maxMonthToDraw: maxMonthToDraw,
                      tappedIndex: _tappedMonthIndex,
                      startMonthOffset: startMonth,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Legend Omzet & Keuntungan Bersih
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 14, height: 2.5, color: accentBlue),
              const SizedBox(width: 4),
              const Text(
                'Omzet',
                style: TextStyle(
                  color: accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 14, height: 2.5, color: accentGreen),
              const SizedBox(width: 4),
              const Text(
                'Keuntungan Bersih',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info Card saat titik/garis bulan ditekan
          if (_tappedMonthIndex != null && _tappedMonthIndex! < maxMonthToDraw) ...[
            Builder(
              builder: (context) {
                final int tappedRealMonth = startMonth + _tappedMonthIndex!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101928),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentBlue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: accentBlue, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${displayMonths[_tappedMonthIndex!]} $_selectedTrenYear',
                            style: const TextStyle(
                              color: textWhite,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Omzet: ${formatRupiah(monthlyKotor[tappedRealMonth] ?? 0)}',
                              style: const TextStyle(
                                color: accentBlue,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Keuntungan: ${formatRupiah(monthlyBersih[tappedRealMonth] ?? 0)}',
                              style: const TextStyle(
                                color: accentGreen,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.swipe_outlined, color: textDim, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'Geser chart atau pilih semester untuk ganti periode bulan',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Footer Rata-rata
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Rata-rata: ${formatRupiah(avgKotor)} / bln ($_selectedTrenYear)',
                style: const TextStyle(
                  color: textDim,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

/// Painter untuk Donut Chart Sumber Pendapatan
class _DonutChartPainter extends CustomPainter {
  final double servisPercent;
  final double barangPercent;

  _DonutChartPainter({
    required this.servisPercent,
    required this.barangPercent,
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

    // Jika belum ada data sama sekali di rentang tanggal ini, tampilkan ring kosong
    if (barangPercent <= 0 && servisPercent <= 0) {
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue arc (Sparepart)
    if (barangPercent > 0) {
      final paintBlue = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;

      final sweepBlue = (2 * math.pi * barangPercent).clamp(0.05, 2 * math.pi);
      canvas.drawArc(rect, -math.pi / 2, sweepBlue, false, paintBlue);
    }

    // Red arc (Servis)
    if (servisPercent > 0) {
      final paintRed = Paint()
        ..color = const Color(0xFFFF1E27)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;

      final startAngle = -math.pi / 2 + (2 * math.pi * barangPercent);
      final sweepRed = (2 * math.pi * servisPercent).clamp(0.05, 2 * math.pi);
      canvas.drawArc(rect, startAngle, sweepRed, false, paintRed);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.servisPercent != servisPercent ||
      oldDelegate.barangPercent != barangPercent;
}

/// Painter untuk Tren Laba Bulanan (Grid, Y-Axis %, Dual Lines with Values & Glow)
class _TrenLabaBulananPainter extends CustomPainter {
  final List<String> months;
  final List<double> labaKotorValues;
  final Map<int, int> monthlyKotor;
  final List<double> labaBersihValues;
  final Map<int, int> monthlyBersih;
  final int maxMonthToDraw;
  final int? tappedIndex;
  final int startMonthOffset;

  _TrenLabaBulananPainter({
    required this.months,
    required this.labaKotorValues,
    required this.monthlyKotor,
    required this.labaBersihValues,
    required this.monthlyBersih,
    required this.maxMonthToDraw,
    this.tappedIndex,
    this.startMonthOffset = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 22.0;
    const topMargin = 22.0;
    const rightMargin = 12.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    // 1. Gambar Y-Axis Labels & Horizontal Grid Lines (Bersih & Bebas Overload)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2433)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final yPercentages = ['100%', '75%', '50%', '25%', '0%'];
    for (int i = 0; i < yPercentages.length; i++) {
      final y = topMargin + (i / (yPercentages.length - 1)) * chartHeight;

      // Label teks Y
      final textSpan = TextSpan(
        text: yPercentages[i],
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 7.5,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 4, y - tp.height / 2));

      // Garis Grid
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );
    }

    // 2. Skala Maksimum Y
    // Menggunakan skala target kapasitas bulanan bengkel (default Rp 10.000.000 / 10 Juta).
    // Agar kenaikan titik garis bertahap sesuai nominal income:
    // misal 500rb = 5%, 1jt = 10%, 2jt = 20%, 5jt = 50% (tidak langsung melonjak ke 50%).
    double maxData = 0.0;
    for (int i = 0; i < maxMonthToDraw && i < labaKotorValues.length; i++) {
      if (labaKotorValues[i] > maxData) maxData = labaKotorValues[i];
      if (labaBersihValues[i] > maxData) maxData = labaBersihValues[i];
    }
    const double benchmarkCapacity = 10.0; // Kapasitas acuan Rp 10.000.000
    final double maxVal = math.max(benchmarkCapacity, maxData * 1.25);
    const double minVal = 0.0;

    final stepX = chartWidth / (months.length - 1);

    final pointsKotor = <Offset>[];
    final pointsBersih = <Offset>[];

    // Buat titik HANYA untuk bulan yang sudah berjalan (1 s/d maxMonthToDraw)
    // Bulan setelahnya dibiarkan kosong tanpa garis
    for (int i = 0; i < maxMonthToDraw && i < months.length; i++) {
      final x = leftMargin + i * stepX;

      final normYKotor = ((labaKotorValues[i] - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
      final yKotor = topMargin + chartHeight - (normYKotor * chartHeight);
      pointsKotor.add(Offset(x, yKotor));

      final normYBersih = ((labaBersihValues[i] - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
      final yBersih = topMargin + chartHeight - (normYBersih * chartHeight);
      pointsBersih.add(Offset(x, yBersih));
    }

    // 3. Gradient Fill di Bawah Garis Laba Bersih (Hanya sampai maxMonthToDraw)
    if (pointsBersih.length >= 2) {
      final fillPath = Path()
        ..moveTo(pointsBersih.first.dx, topMargin + chartHeight)
        ..lineTo(pointsBersih.first.dx, pointsBersih.first.dy);

      for (int i = 0; i < pointsBersih.length - 1; i++) {
        final p0 = pointsBersih[i];
        final p1 = pointsBersih[i + 1];
        final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
      }
      fillPath.lineTo(pointsBersih.last.dx, topMargin + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x3522C55E),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // 4. Smooth Curves untuk Laba Bersih (Green) & Laba Kotor (Cyan)
    if (pointsKotor.length >= 2) {
      final pathKotor = _createCurvedPath(pointsKotor);
      final paintKotor = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(pathKotor, paintKotor);

      final pathBersih = _createCurvedPath(pointsBersih);
      final paintBersih = Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(pathBersih, paintBersih);
    } else if (pointsKotor.length == 1) {
      canvas.drawCircle(pointsKotor.first, 3.5, Paint()..color = const Color(0xFF38BDF8));
      canvas.drawCircle(pointsBersih.first, 3.5, Paint()..color = const Color(0xFF22C55E));
    }

    // 5. Garis Indikator Vertikal & Tooltip jika ada bulan yang ditekan
    final bool hasTap = tappedIndex != null && tappedIndex! >= 0 && tappedIndex! < pointsKotor.length;
    if (hasTap) {
      final selectedX = pointsKotor[tappedIndex!].dx;

      // Garis vertikal putus-putus halus
      final guidePaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      const double dashHeight = 3.0;
      const double dashSpace = 3.0;
      double startY = topMargin;
      while (startY < topMargin + chartHeight) {
        canvas.drawLine(
          Offset(selectedX, startY),
          Offset(selectedX, math.min(startY + dashHeight, topMargin + chartHeight)),
          guidePaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Nominal bulanan terpilih
      final int realMonth = startMonthOffset + tappedIndex!;
      final int kotorRp = monthlyKotor[realMonth] ?? 0;
      final int bersihRp = monthlyBersih[realMonth] ?? 0;

      // Tooltip Card di atas garis
      final tpTooltip = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${months[tappedIndex!]}: ',
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: 'Omzet ${formatRupiah(kotorRp)} ',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: '• ',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 8.5),
            ),
            TextSpan(
              text: 'Keuntungan ${formatRupiah(bersihRp)}',
              style: const TextStyle(color: Color(0xFF22C55E), fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillW = tpTooltip.width + 14;
      final pillH = tpTooltip.height + 6;
      final pillX = (selectedX - pillW / 2).clamp(leftMargin, size.width - rightMargin - pillW);
      final pillY = 1.0;

      final pillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillW, pillH),
        const Radius.circular(5),
      );

      canvas.drawRRect(pillRRect, Paint()..color = const Color(0xFF0F172A));
      canvas.drawRRect(
        pillRRect,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      tpTooltip.paint(canvas, Offset(pillX + 7, pillY + 3));
    }

    // 6. Titik-titik Laba Kotor (Cyan)
    for (int i = 0; i < pointsKotor.length; i++) {
      final p = pointsKotor[i];
      final isTapped = hasTap && tappedIndex == i;
      final isLast = i == pointsKotor.length - 1;

      if (isTapped) {
        // Glowing halo saat ditekan
        canvas.drawCircle(p, 8.0, Paint()..color = const Color(0x4038BDF8));
        canvas.drawCircle(
          p,
          5.0,
          Paint()
            ..color = const Color(0xFF38BDF8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
      } else if (isLast && !hasTap && maxMonthToDraw > 0) {
        final ringPaint = Paint()
          ..color = const Color(0xFF38BDF8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawCircle(p, 4.5, ringPaint);
        canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF38BDF8));
      } else {
        canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF38BDF8));
      }
    }

    // 7. Titik-titik Laba Bersih (Green)
    for (int i = 0; i < pointsBersih.length; i++) {
      final p = pointsBersih[i];
      final isTapped = hasTap && tappedIndex == i;
      final isLast = i == pointsBersih.length - 1;

      if (isTapped) {
        // Glowing halo saat ditekan
        canvas.drawCircle(p, 8.0, Paint()..color = const Color(0x4022C55E));
        canvas.drawCircle(
          p,
          5.0,
          Paint()
            ..color = const Color(0xFF22C55E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
      } else if (isLast && !hasTap && maxMonthToDraw > 0) {
        final ringPaint = Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawCircle(p, 4.5, ringPaint);
        canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF22C55E));
      } else {
        canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF22C55E));
      }
    }

    // 8. X-Axis 12 Month Labels (Jan - Des)
    for (int i = 0; i < months.length; i++) {
      final isTapped = hasTap && tappedIndex == i;
      final isCurrentOrLast = (!hasTap && i == (maxMonthToDraw - 1));
      final isPastOrActive = i < maxMonthToDraw;

      final textSpan = TextSpan(
        text: months[i],
        style: TextStyle(
          color: isTapped
              ? const Color(0xFF38BDF8)
              : (isCurrentOrLast
                  ? const Color(0xFF22C55E)
                  : (isPastOrActive ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
          fontSize: isTapped ? 9.0 : 8.0,
          fontWeight: (isTapped || isCurrentOrLast) ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      final x = leftMargin + i * stepX;
      tp.paint(canvas, Offset(x - tp.width / 2, topMargin + chartHeight + 6));
    }
  }

  Path _createCurvedPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrenLabaBulananPainter oldDelegate) => true;
}
