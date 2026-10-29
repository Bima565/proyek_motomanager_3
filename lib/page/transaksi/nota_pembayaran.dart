import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/transaksi_service.dart';

/// Screen 4 - (FR07) Nota Pembayaran & Bagikan WA
class NotaPembayaranPage extends StatelessWidget {
  final TransaksiPenjualanModel? transaksi;
  final String? noNota;
  final String? waktu;
  final String? pelanggan;
  final String? kasir;
  final List<TransaksiItemModel>? items;
  final int? totalBayar;
  final int? tunaiDiterima;
  final String? paymentMethod;
  final Map<String, dynamic>? userData;

  const NotaPembayaranPage({
    super.key,
    this.transaksi,
    this.noNota,
    this.waktu,
    this.pelanggan,
    this.kasir,
    this.items,
    this.totalBayar,
    this.tunaiDiterima,
    this.paymentMethod,
    this.userData,
  });

  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color waGreen = Color(0xFF16A34A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);

  // Getters dengan fallback
  String get effectiveNoNota =>
      transaksi?.code ?? noNota ?? 'TRX-20260929-026';
  String get effectiveWaktu =>
      transaksi?.notaTimeFormatted ?? waktu ?? '29/09/2026 • 10:45 WIB';
  String get effectivePelanggan {
    if (transaksi != null) {
      final plat = transaksi!.policeNumber.isNotEmpty
          ? ' (${transaksi!.policeNumber})'
          : '';
      return '${transaksi!.customerName}$plat';
    }
    return pelanggan ?? 'Bpk. Rahmat Santoso (B 4921 KDF)';
  }

  String get effectiveKasir =>
      transaksi?.kasirName ??
      kasir ??
      userData?['nama_lengkap'] ??
      'Sri Ekowati';

  List<TransaksiItemModel> get effectiveItems =>
      transaksi?.items ?? items ?? [];

  int get effectiveTotalBayar =>
      transaksi?.totalBayar ?? totalBayar ?? 0;

  String get effectivePaymentMethod =>
      transaksi?.paymentMethod ?? paymentMethod ?? 'Tunai';

  int get effectiveTunaiDiterima =>
      transaksi?.tunaiDiterima ??
      tunaiDiterima ??
      (effectivePaymentMethod == 'Tunai' ? effectiveTotalBayar : effectiveTotalBayar);

  int get effectiveKembalian {
    if (transaksi != null) return transaksi!.kembalian;
    if (effectivePaymentMethod == 'Tunai' &&
        effectiveTunaiDiterima > effectiveTotalBayar) {
      return effectiveTunaiDiterima - effectiveTotalBayar;
    }
    return 0;
  }

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  String _generateWhatsAppInvoiceText() {
    final buffer = StringBuffer();
    buffer.writeln('*BENGKEL ZALZABILA MOTOR*');
    buffer.writeln('Jl. Raya Industri No. 45 • Telp/WA: 0812-3456-7890');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*NOTA TRANSAKSI PEMBAYARAN*');
    buffer.writeln('No. Nota  : $effectiveNoNota');
    buffer.writeln('Waktu     : $effectiveWaktu');
    buffer.writeln('Pelanggan : $effectivePelanggan');
    buffer.writeln('Kasir     : $effectiveKasir');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*RINCIAN BARANG & JASA:*');

    for (int i = 0; i < effectiveItems.length; i++) {
      final item = effectiveItems[i];
      buffer.writeln('${i + 1}. ${item.name}');
      buffer.writeln('   ${item.quantity}x ${_formatRupiah(item.price)} = ${_formatRupiah(item.total)}');
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('*TOTAL PEMBAYARAN: ${_formatRupiah(effectiveTotalBayar)}*');
    buffer.writeln('Metode   : $effectivePaymentMethod');
    if (effectivePaymentMethod == 'Tunai') {
      buffer.writeln('Tunai    : ${_formatRupiah(effectiveTunaiDiterima)}');
      buffer.writeln('Kembalian: ${_formatRupiah(effectiveKembalian)}');
    }
    buffer.writeln('Status   : LUNAS');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Terima kasih telah mempercayakan perawatan motor Anda kepada Bengkel Zalzabila Motor!');
    buffer.writeln('Simpan nota ini sebagai bukti garansi servis.');

    return buffer.toString();
  }

  void _shareViaWhatsApp(BuildContext context) {
    final text = _generateWhatsAppInvoiceText();
    Clipboard.setData(ClipboardData(text: text));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: Row(
          children: const [
            Icon(Icons.chat_rounded, color: waGreen, size: 22),
            SizedBox(width: 10),
            Text(
              'Bagikan Nota WhatsApp',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teks nota pembayaran telah disalin ke Clipboard! Anda dapat langsung paste dan kirimkan ke chat WhatsApp pelanggan.',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: textDim)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: waGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F2B1D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF166534), width: 1),
                  ),
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: accentGreen, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Teks nota disalin! Buka WhatsApp untuk mengirim ke pelanggan.',
                          style: TextStyle(color: textWhite, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: textWhite, size: 16),
            label: const Text('Salin Ulang Teks', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  void _printReceiptPdf(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: Row(
          children: const [
            Icon(Icons.receipt_rounded, color: accentRed, size: 22),
            SizedBox(width: 10),
            Text(
              'Cetak Struk Thermal (PDF)',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'BENGKEL ZALZABILA MOTOR',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    const Text('Jl. Raya Industri No. 45'),
                    const Text('Telp/WA: 0812-3456-7890'),
                    const Text('================================='),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('No: $effectiveNoNota'),
                        Text(effectivePaymentMethod),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kasir: $effectiveKasir'),
                        Text(effectiveWaktu.split('•').first.trim()),
                      ],
                    ),
                    const Text('---------------------------------'),
                    ...effectiveItems.map((i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${i.name} (${i.quantity}x)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(_formatRupiah(i.total)),
                            ],
                          ),
                        )),
                    const Text('---------------------------------'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(effectiveTotalBayar),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (effectivePaymentMethod == 'Tunai') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BAYAR TUNAI:'),
                          Text(_formatRupiah(effectiveTunaiDiterima)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('KEMBALIAN:'),
                          Text(_formatRupiah(effectiveKembalian)),
                        ],
                      ),
                    ],
                    const Text('================================='),
                    const Text('TERIMA KASIH'),
                    const Text('GARANSI SERVIS 7 HARI'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF142033),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 1),
                  ),
                  content: Row(
                    children: const [
                      Icon(Icons.print_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Struk nota siap dicetak ke printer POS!',
                          style: TextStyle(color: textWhite, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, color: textWhite, size: 16),
            label: const Text('Cetak Sekarang', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int kembalian = effectiveKembalian;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Nota Pembayaran & Badge Sukses)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Nota Pembayaran',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Transaksi Berhasil',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Success Badge Lingkaran Hijau
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F2B1D),
                      border: Border.all(color: const Color(0xFF166534), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: accentGreen,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Receipt Thermal Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identitas Bengkel (Centered)
                    Center(
                      child: Column(
                        children: const [
                          Text(
                            'BENGKEL ZALZABILA MOTOR',
                            style: TextStyle(
                              color: textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jl. Raya Industri No. 45 • Telp/WA: 0812-3456-7890',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Divider 1
                    Container(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Metadata Transaksi
                    _buildMetaRow('No. Nota', effectiveNoNota, isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildMetaRow('Waktu', effectiveWaktu),
                    const SizedBox(height: 6),
                    _buildMetaRow('Pelanggan', effectivePelanggan),
                    const SizedBox(height: 6),
                    _buildMetaRow('Kasir', effectiveKasir),
                    const SizedBox(height: 12),

                    // Divider 2
                    Container(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Header Tabel Item
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'RINCIAN BARANG / JASA',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            color: textDim,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List Items
                    ...effectiveItems.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$idx. ${item.name}',
                                    style: const TextStyle(
                                      color: textWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(item.total),
                                  style: const TextStyle(
                                    color: textWhite,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 14),
                              child: Text(
                                '${item.quantity}x ${_formatRupiah(item.price)}',
                                style: const TextStyle(
                                  color: textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 4),
                    // Divider 3
                    Container(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Total Pembayaran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL PEMBAYARAN',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatRupiah(effectiveTotalBayar),
                          style: const TextStyle(
                            color: accentGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rincian Bayar / Tunai / QRIS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          effectivePaymentMethod == 'Tunai'
                              ? 'Tunai Diterima'
                              : 'Metode Pembayaran',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          effectivePaymentMethod == 'Tunai'
                              ? _formatRupiah(effectiveTunaiDiterima)
                              : '$effectivePaymentMethod / Non-Tunai',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (effectivePaymentMethod == 'Tunai' && kembalian >= 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatRupiah(kembalian),
                            style: const TextStyle(
                              color: accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Tombol Bagikan Nota via WhatsApp
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _shareViaWhatsApp(context),
                  icon: const Icon(Icons.chat_rounded, color: textWhite, size: 18),
                  label: const Text(
                    'Bagikan Nota via WhatsApp',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: waGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Tombol Cetak Struk (PDF)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _printReceiptPdf(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cetak Struk (PDF)',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Tombol Kembali
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F121A),
                    side: const BorderSide(color: cardBorder, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textWhite,
            fontSize: 10.5,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
