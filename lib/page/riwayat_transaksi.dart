import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/custom_calendar_dialog.dart';
import '../components/moto_bottom_nav.dart';
import '../components/rupiah_formatter.dart';
import '../services/pembelian_service.dart';
import '../services/transaksi_service.dart';
import 'transaksi/kasir_transaksi.dart';
import 'transaksi/nota_pembayaran.dart';
import 'transaksi/pengadaan_restock.dart';

// Alias backward compatibility jika ada file lain yang mengacu pada TransaksiRecord
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
  DateTime _startDate = DateTime(2026, 9, 1);
  DateTime _endDate = DateTime(2026, 10, 31);

  // Quick Period Pill (1 Hari | 7 Hari | 30 Hari | Semua)
  String _selectedQuickPeriod = 'Semua';

  // Filter Metode Pembayaran (khusus penjualan): 'Semua' | 'QRIS' | 'TUNAI'
  String _selectedPayment = 'Semua';

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  String _formatDateIso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // --- POPUP DATE PICKER DIALOG (Reusable Component) ---
  Future<void> _openDatePickerPopup({required bool isStart}) async {
    final selected = await CustomCalendarDialog.show(
      context,
      initialDate: isStart ? _startDate : _endDate,
    );
    if (selected != null) {
      setState(() {
        _selectedQuickPeriod = 'Kustom';
        if (isStart) {
          _startDate = selected;
        } else {
          _endDate = selected;
        }
      });
    }
  }

  void _applyQuickPeriod(String period) {
    setState(() {
      _selectedQuickPeriod = period;
      final now = DateTime.now();
      if (period == '1 Hari') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (period == '7 Hari') {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (period == '30 Hari') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      } else {
        _startDate = DateTime(2020, 1, 1);
        _endDate = DateTime(2030, 12, 31);
      }
    });
  }

  List<TransaksiPenjualanModel> _filterSales(List<TransaksiPenjualanModel> allList) {
    return allList.where((t) {
      if (_selectedPayment != 'Semua' &&
          t.paymentMethod.toUpperCase() != _selectedPayment.toUpperCase()) {
        return false;
      }
      if (_selectedQuickPeriod == 'Semua') {
        return true;
      }
      final dateOnly = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
      final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);

      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
          (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }).toList();
  }

  List<PembelianRecord> _filterPurchases(List<PembelianRecord> allList) {
    return allList.where((p) {
      if (_selectedQuickPeriod == 'Semua') {
        return true;
      }
      final dateOnly = DateTime(p.dateTime.year, p.dateTime.month, p.dateTime.day);
      final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);

      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
          (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }).toList();
  }

  void _openTambahPembelian() async {
    await Navigator.push<PembelianRecord>(
      context,
      MaterialPageRoute(
        builder: (context) => PengadaanRestockPage(userData: widget.userData),
      ),
    );
  }

  void _sharePurchaseWhatsApp(BuildContext context, PembelianRecord item) {
    final buffer = StringBuffer();
    buffer.writeln('*BENGKEL ZALZABILA MOTOR*');
    buffer.writeln('Jl. Raya Industri No. 45 • Telp/WA: 0812-3456-7890');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*BUKTI PENGADAAN & RESTOCK BARANG*');
    buffer.writeln('No. Bukti : ${item.code}');
    buffer.writeln('Tanggal   : ${item.dateFormatted}');
    buffer.writeln('Supplier  : ${item.supplier}');
    buffer.writeln('PIC       : ${item.buyerName}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*RINCIAN PASOKAN BARANG:*');
    for (int i = 0; i < item.items.length; i++) {
      final it = item.items[i];
      buffer.writeln('${i + 1}. ${it.name}');
      buffer.writeln('   ${it.quantity} ${it.unit} x ${_formatRupiah(it.buyPrice)} = ${_formatRupiah(it.subtotal)}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('*TOTAL MODAL: ${_formatRupiah(item.totalAmount)}*');
    buffer.writeln('Status    : ${item.status}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF143322),
        content: Text('Rincian pembelian disalin ke clipboard! Siap dibagikan ke WhatsApp.'),
      ),
    );
  }

  void _showPurchaseDetailSheet(BuildContext context, PembelianRecord item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: cardBorder, width: 1.5)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: textDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header: No Bukti, Tanggal & Jam, Badge LUNAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.code,
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.timeFormatted,
                          style: const TextStyle(color: textDim, fontSize: 11),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Info Supplier & PIC Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Supplier / Toko', style: TextStyle(color: textDim, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              item.supplier,
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: cardBorder),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Penanggung Jawab', style: TextStyle(color: textDim, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              item.buyerName,
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Rincian Pasokan Restock
                Text(
                  'Rincian Pasokan (${item.items.length} Barang)',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Item List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: item.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final it = item.items[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.name,
                                  style: const TextStyle(
                                    color: textWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${it.quantity} ${it.unit} × ${_formatRupiah(it.buyPrice)} • ${it.category}',
                                  style: const TextStyle(color: textDim, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(it.subtotal),
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Total Modal Pengadaan Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1418),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4C1D24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Modal Pembelian',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        Text(
                          '${item.totalQuantity} total item',
                          style: const TextStyle(color: textDim, fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      _formatRupiah(item.totalAmount),
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons: Bagikan Rincian (WA) & Tutup
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _sharePurchaseWhatsApp(context, item);
                      },
                      icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF22C55E)),
                      label: const Text(
                        'Bagikan (WA)',
                        style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF166534)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardBorder,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        TransaksiService().transactionsNotifier,
        PembelianService().pembelianNotifier,
      ]),
      builder: (context, child) {
        final allSalesList = TransaksiService().transactions;
        final allPurchasesList = PembelianService().pembelianList;

        final filteredSales = _filterSales(allSalesList);
        final filteredPurchases = _filterPurchases(allPurchasesList);

        final int totalPenjualan =
            filteredSales.fold(0, (total, t) => total + t.totalBayar);
        final int totalPembelian =
            filteredPurchases.fold(0, (total, p) => total + p.totalAmount);

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

                // 4. Quick Duration Pills: 1 Hari | 7 Hari | 30 Hari | Filter Metode
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _activeTab == 0
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickPill('Semua'),
                              const SizedBox(width: 6),
                              _buildQuickPill('1 Hari'),
                              const SizedBox(width: 6),
                              _buildQuickPill('7 Hari'),
                              const SizedBox(width: 6),
                              _buildQuickPill('30 Hari'),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 16, color: cardBorder),
                              const SizedBox(width: 12),
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
                            _buildQuickPill('Semua', isExpanded: true),
                            const SizedBox(width: 6),
                            _buildQuickPill('1 Hari', isExpanded: true),
                            const SizedBox(width: 6),
                            _buildQuickPill('7 Hari', isExpanded: true),
                            const SizedBox(width: 6),
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
      },
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
  Widget _buildSalesList(List<TransaksiPenjualanModel> list) {
    if (list.isEmpty) return _buildEmptyState('Tidak ada transaksi penjualan pada periode ini.');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trx = list[index];
        final isQris = trx.paymentMethod.toUpperCase() == 'QRIS';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotaPembayaranPage(
                  transaksi: trx,
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
                        trx.paymentMethod,
                        style: TextStyle(
                          color: isQris ? accentBlue : accentGreen,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRupiah(trx.totalBayar),
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
                  '${trx.customerName} • ${trx.vehicleInfo}',
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
                        trx.summaryServices,
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

        return InkWell(
          onTap: () => _showPurchaseDetailSheet(context, item),
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
                      '${item.code} • ${item.dateFormatted}',
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF334155), width: 1),
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRupiah(item.totalAmount),
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.buyerName} • ${item.supplier}',
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
                        item.summaryItems,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: textDim.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: textDim, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
