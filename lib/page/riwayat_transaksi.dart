import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';
import 'transaksi/kasir_transaksi.dart';
import 'transaksi/nota_pembayaran.dart';

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

  String get monthName {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.year}';
  }
}

/// Screen 12 - (FR07) Riwayat Transaksi & Kasir
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

  // Filter Modes: '1 Hari' | 'Rentang' | 'Bulanan'
  String _periodMode = '1 Hari';

  // State DateTime filter
  DateTime? _selectedDate; // Untuk mode '1 Hari' (null = Semua Hari)
  DateTimeRange? _selectedDateRange; // Untuk mode 'Rentang'
  DateTime? _selectedMonth; // Untuk mode 'Bulanan' (null = Semua Bulan)

  // Filter Metode Pembayaran: 'Semua' | 'QRIS' | 'TUNAI'
  String _selectedPayment = 'Semua';

  // Seed Data Transaksi menggunakan objek DateTime presisi
  final List<TransaksiRecord> _transactions = [
    TransaksiRecord(
      code: '#TRX-005',
      dateTime: DateTime(2026, 9, 20, 8, 30), // Sabtu
      payment: 'QRIS',
      amount: 40000,
      customer: 'Dian Pratama',
      vehicle: 'Yamaha NMAX',
      service: 'Tambal Tubeless + Cairan Ban',
    ),
    TransaksiRecord(
      code: '#TRX-004',
      dateTime: DateTime(2026, 9, 20, 10, 15), // Sabtu
      payment: 'TUNAI',
      amount: 95000,
      customer: 'Rudi Hartono',
      vehicle: 'Honda Supra X 125',
      service: 'Bersihkan Karburator + Rantai Roda',
    ),
    TransaksiRecord(
      code: '#TRX-003',
      dateTime: DateTime(2026, 9, 19, 14, 20), // Jumat
      payment: 'TUNAI',
      amount: 80000,
      customer: 'Ibu Sri Wahyuni',
      vehicle: 'Yamaha Mio M3',
      service: 'Ganti Oli Mesin & Gardan',
    ),
    TransaksiRecord(
      code: '#TRX-002',
      dateTime: DateTime(2026, 9, 18, 11, 0), // Kamis
      payment: 'QRIS',
      amount: 130000,
      customer: 'Ahmad Fauzi',
      vehicle: 'Honda Vario 160',
      service: 'Servis CVT & Rem + Roller + Kampas',
    ),
    TransaksiRecord(
      code: '#TRX-001',
      dateTime: DateTime(2026, 9, 17, 9, 10), // Rabu
      payment: 'TUNAI',
      amount: 105000,
      customer: 'Budi Santoso',
      vehicle: 'Honda Beat FI',
      service: 'Servis Ringan + Oli MPX2 + Busi',
    ),
    TransaksiRecord(
      code: '#TRX-006',
      dateTime: DateTime(2026, 9, 16, 16, 0), // Selasa
      payment: 'QRIS',
      amount: 65000,
      customer: 'Agus Wahyudi',
      vehicle: 'Yamaha Aerox 155',
      service: 'Ganti Oli Gardan + Busi',
    ),
    TransaksiRecord(
      code: '#TRX-007',
      dateTime: DateTime(2026, 9, 15, 13, 45), // Senin
      payment: 'TUNAI',
      amount: 50000,
      customer: 'Dewi Lestari',
      vehicle: 'Honda Scoopy',
      service: 'Stel Klep & Servis Karburator',
    ),
    TransaksiRecord(
      code: '#TRX-008',
      dateTime: DateTime(2026, 8, 28, 15, 20), // Jumat, Agustus 2026
      payment: 'QRIS',
      amount: 85000,
      customer: 'Hendro Gunawan',
      vehicle: 'Suzuki Satria F150',
      service: 'Ganti Kampas Rem Depan Belakang',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default: Mode '1 Hari' menunjuk ke tanggal transaksi terbaru (20 Sept 2026)
    _selectedDate = DateTime(2026, 9, 20);
    _selectedDateRange = DateTimeRange(
      start: DateTime(2026, 9, 15),
      end: DateTime(2026, 9, 20),
    );
    _selectedMonth = DateTime(2026, 9, 1);
  }

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

  String _formatDateShort(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _getDayName(DateTime d) {
    switch (d.weekday) {
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

  // --- HTML-like Native DatePicker Dialog Helpers ---
  Future<void> _openDatePicker() async {
    final initial = _selectedDate ?? DateTime(2026, 9, 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentRed,
              onPrimary: textWhite,
              surface: cardBg,
              onSurface: textWhite,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: bgDark),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openDateRangePicker() async {
    final initial = _selectedDateRange ??
        DateTimeRange(
          start: DateTime(2026, 9, 15),
          end: DateTime(2026, 9, 20),
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accentRed,
              onPrimary: textWhite,
              surface: cardBg,
              onSurface: textWhite,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: bgDark),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // --- FILTER ENGINE BERBASIS DATETIME ---
  List<TransaksiRecord> _getFilteredTransactions() {
    return _transactions.where((t) {
      // 1. Filter Pembayaran
      if (_selectedPayment != 'Semua' &&
          t.payment.toUpperCase() != _selectedPayment.toUpperCase()) {
        return false;
      }

      // 2. Filter Berdasarkan Mode DateTime
      if (_periodMode == '1 Hari') {
        if (_selectedDate != null) {
          final isSameDay = t.dateTime.year == _selectedDate!.year &&
              t.dateTime.month == _selectedDate!.month &&
              t.dateTime.day == _selectedDate!.day;
          if (!isSameDay) return false;
        }
      } else if (_periodMode == 'Rentang') {
        if (_selectedDateRange != null) {
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
            0,
            0,
            0,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
          );
          if (t.dateTime.isBefore(start) || t.dateTime.isAfter(end)) {
            return false;
          }
        }
      } else if (_periodMode == 'Bulanan') {
        if (_selectedMonth != null) {
          final isSameMonth = t.dateTime.year == _selectedMonth!.year &&
              t.dateTime.month == _selectedMonth!.month;
          if (!isSameMonth) return false;
        }
      }

      return true;
    }).toList();
  }

  // Counter helper untuk bubble chips
  int _countForDate(DateTime d) {
    return _transactions.where((t) {
      if (_selectedPayment != 'Semua' &&
          t.payment.toUpperCase() != _selectedPayment.toUpperCase()) {
        return false;
      }
      return t.dateTime.year == d.year &&
          t.dateTime.month == d.month &&
          t.dateTime.day == d.day;
    }).length;
  }

  int _countForMonth(DateTime m) {
    return _transactions.where((t) {
      if (_selectedPayment != 'Semua' &&
          t.payment.toUpperCase() != _selectedPayment.toUpperCase()) {
        return false;
      }
      return t.dateTime.year == m.year && t.dateTime.month == m.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    final int totalAmount = filtered.fold<int>(
      0,
      (sum, t) => sum + t.amount,
    );

    final bool isFilterActive = (_periodMode == '1 Hari' &&
            _selectedDate != null) ||
        (_periodMode == 'Rentang' && _selectedDateRange != null) ||
        (_periodMode == 'Bulanan' && _selectedMonth != null) ||
        _selectedPayment != 'Semua';

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Section
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
                        '${filtered.length} Transaksi • ${_formatRupiah(totalAmount)}',
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (isFilterActive)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedDateRange = null;
                          _selectedMonth = null;
                          _selectedPayment = 'Semua';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B1519),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: accentRed.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Reset Semua',
                          style: TextStyle(
                            color: accentRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Tab Segment Switcher (1 Hari | Rentang | Bulanan)
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
                    _buildModeSegment('1 Hari', ' 1 Hari'),
                    const SizedBox(width: 4),
                    _buildModeSegment('Rentang', ' Rentang'),
                    const SizedBox(width: 4),
                    _buildModeSegment('Bulanan', ' Bulanan'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. HTML-like DateTime Control Box (<input type="date|month"> style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHtmlTimeControl(),
            ),
            const SizedBox(height: 8),

            // 4. Quick Bubble Chips Filter
            SizedBox(
              height: 34,
              child: _buildQuickBubbleBar(),
            ),
            const SizedBox(height: 8),

            // 5. Bubble Filter Metode Pembayaran
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Metode:',
                    style: TextStyle(
                      color: textDim,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentChip('Semua'),
                  const SizedBox(width: 6),
                  _buildPaymentChip('QRIS'),
                  const SizedBox(width: 6),
                  _buildPaymentChip('TUNAI'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 6. Daftar Transaksi List / Empty State
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final trx = filtered[index];
                        final isQris = trx.payment == 'QRIS';

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotaPembayaranPage(
                                  noNota: trx.code,
                                  waktu: trx.timeFormatted,
                                  pelanggan:
                                      '${trx.customer} (${trx.vehicle})',
                                  kasir: widget.userData?['nama_lengkap'] ??
                                      'Sri Ekowati',
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
                                  paymentMethod:
                                      isQris ? 'QRIS' : 'Tunai',
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
                                // Baris 1: Kode TRX, Hari & Waktu, Badge Payment, Nominal Hijau
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2433),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        trx.dayName,
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isQris
                                            ? const Color(0xFF0C243B)
                                            : const Color(0xFF0F2E1E),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isQris
                                              ? const Color(0xFF1E40AF)
                                              : const Color(0xFF166534),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        trx.payment,
                                        style: TextStyle(
                                          color: isQris
                                              ? accentBlue
                                              : accentGreen,
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

                                // Baris 2: Pelanggan & Motor
                                Text(
                                  '${trx.customer} • ${trx.vehicle}',
                                  style: const TextStyle(
                                    color: textWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Baris 3: Layanan Servis & Tombol Lingkaran Chevron
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trx.service,
                                        style: const TextStyle(
                                          color: textMuted,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1D2333),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: textMuted,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 7. Tombol Tambah Transaksi Baru (Sticky Red Button di atas Bottom Nav)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KasirTransaksiPage(
                          userData: widget.userData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: textWhite, size: 20),
                  label: const Text(
                    'Tambah Transaksi Baru',
                    style: TextStyle(
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

  // --- SUB-WIDGET KOMPONEN ---

  Widget _buildModeSegment(String modeKey, String label) {
    final isSelected = _periodMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _periodMode = modeKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentRed : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? textWhite : textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kontrol DateTime bergaya HTML Input `<input type="date">` / `<input type="month">`
  Widget _buildHtmlTimeControl() {
    if (_periodMode == '1 Hari') {
      final hasDate = _selectedDate != null;
      final dayStr = hasDate ? _getDayName(_selectedDate!) : '';
      final dateStr = hasDate
          ? '$dayStr, ${_formatDateShort(_selectedDate!)}'
          : 'Semua Hari (Pilih Tanggal)';

      return GestureDetector(
        onTap: _openDatePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDate ? accentRed.withValues(alpha: 0.6) : cardBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x22FF1E27),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: accentRed,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PILIH TANGGAL (HTML DATETIME)',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: hasDate ? textWhite : textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDate)
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded, color: textDim, size: 16),
                  ),
                ),
              const Icon(Icons.edit_calendar_rounded,
                  color: textDim, size: 18),
            ],
          ),
        ),
      );
    } else if (_periodMode == 'Rentang') {
      final hasRange = _selectedDateRange != null;
      final rangeStr = hasRange
          ? '${_formatDateShort(_selectedDateRange!.start)} ➔ ${_formatDateShort(_selectedDateRange!.end)}'
          : 'Semua Rentang Waktu';

      return GestureDetector(
        onTap: _openDateRangePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasRange ? accentBlue.withValues(alpha: 0.6) : cardBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x2238BDF8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: accentBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RENTANG TANGGAL (RANGE PICKER)',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 9,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rangeStr,
                      style: TextStyle(
                        color: hasRange ? textWhite : textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRange)
                GestureDetector(
                  onTap: () => setState(() => _selectedDateRange = null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded, color: textDim, size: 16),
                  ),
                ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: textDim, size: 20),
            ],
          ),
        ),
      );
    } else {
      // Mode 'Bulanan' (<input type="month"> style dengan tombol Prev & Next)
      final hasMonth = _selectedMonth != null;
      final monthStr = hasMonth
          ? _formatMonthYear(_selectedMonth!)
          : 'Semua Bulan (Semua Transaksi)';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMonth ? accentGreen.withValues(alpha: 0.5) : cardBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded,
                  color: textWhite, size: 22),
              onPressed: () {
                final curr = _selectedMonth ?? DateTime(2026, 9, 1);
                setState(() {
                  _selectedMonth = DateTime(curr.year, curr.month - 1, 1);
                });
              },
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BULAN TRANSAKSI (<input type="month">)',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 8.5,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthStr,
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded,
                  color: textWhite, size: 22),
              onPressed: () {
                final curr = _selectedMonth ?? DateTime(2026, 9, 1);
                setState(() {
                  _selectedMonth = DateTime(curr.year, curr.month + 1, 1);
                });
              },
            ),
          ],
        ),
      );
    }
  }

  /// Quick Bubble Bar untuk akses cepat hari / rentang / bulan
  Widget _buildQuickBubbleBar() {
    if (_periodMode == '1 Hari') {
      final quickDays = [
        {'label': 'Semua Hari', 'date': null},
        {'label': 'Sabtu (20/9)', 'date': DateTime(2026, 9, 20)},
        {'label': 'Jumat (19/9)', 'date': DateTime(2026, 9, 19)},
        {'label': 'Kamis (18/9)', 'date': DateTime(2026, 9, 18)},
        {'label': 'Rabu (17/9)', 'date': DateTime(2026, 9, 17)},
        {'label': 'Selasa (16/9)', 'date': DateTime(2026, 9, 16)},
        {'label': 'Senin (15/9)', 'date': DateTime(2026, 9, 15)},
      ];

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: quickDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = quickDays[index];
          final date = item['date'] as DateTime?;
          final label = item['label'] as String;

          final isSelected = (date == null && _selectedDate == null) ||
              (date != null &&
                  _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day);

          final count = date != null ? _countForDate(date) : null;

          return _buildBubbleChip(
            label: label,
            isSelected: isSelected,
            count: count,
            onTap: () => setState(() => _selectedDate = date),
          );
        },
      );
    } else if (_periodMode == 'Rentang') {
      final quickRanges = [
        {'label': 'Semua Rentang', 'range': null},
        {
          'label': '7 Hari Terakhir',
          'range': DateTimeRange(
            start: DateTime(2026, 9, 14),
            end: DateTime(2026, 9, 20),
          )
        },
        {
          'label': 'September 2026',
          'range': DateTimeRange(
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 30),
          )
        },
        {
          'label': 'Agustus 2026',
          'range': DateTimeRange(
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 8, 31),
          )
        },
      ];

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: quickRanges.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = quickRanges[index];
          final range = item['range'] as DateTimeRange?;
          final label = item['label'] as String;

          final isSelected = (range == null && _selectedDateRange == null) ||
              (range != null &&
                  _selectedDateRange != null &&
                  _selectedDateRange!.start.day == range.start.day &&
                  _selectedDateRange!.end.day == range.end.day &&
                  _selectedDateRange!.start.month == range.start.month);

          return _buildBubbleChip(
            label: label,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedDateRange = range),
          );
        },
      );
    } else {
      // Bulanan
      final quickMonths = [
        {'label': 'Semua Bulan', 'month': null},
        {'label': 'September 2026', 'month': DateTime(2026, 9, 1)},
        {'label': 'Agustus 2026', 'month': DateTime(2026, 8, 1)},
        {'label': 'Juli 2026', 'month': DateTime(2026, 7, 1)},
      ];

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: quickMonths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = quickMonths[index];
          final m = item['month'] as DateTime?;
          final label = item['label'] as String;

          final isSelected = (m == null && _selectedMonth == null) ||
              (m != null &&
                  _selectedMonth != null &&
                  _selectedMonth!.year == m.year &&
                  _selectedMonth!.month == m.month);

          final count = m != null ? _countForMonth(m) : null;

          return _buildBubbleChip(
            label: label,
            isSelected: isSelected,
            count: count,
            onTap: () => setState(() => _selectedMonth = m),
          );
        },
      );
    }
  }

  Widget _buildBubbleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentRed : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentRed : cardBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentRed.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? textWhite : textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFF1D2333),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? textWhite : textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String payment) {
    final isSelected = _selectedPayment == payment;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = payment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16253B) : const Color(0xFF10131B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentBlue : cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          payment,
          style: TextStyle(
            color: isSelected ? accentBlue : textDim,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.calendar_month_outlined,
              color: textDim,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada transaksi pada tanggal / periode ini.',
            style: TextStyle(
              color: textWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ganti tanggal kalender atau setel filter ke Semua Hari.',
            style: TextStyle(color: textDim, fontSize: 11),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedDateRange = null;
                _selectedMonth = null;
                _selectedPayment = 'Semua';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: textWhite,
              side: const BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reset Filter & Tampilkan Semua',
                style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
