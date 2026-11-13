import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/transaksi_service.dart';

/// Screen 4 - (FR07) Nota Pembayaran & Bagikan WA (Gambar PNG + Chat Langsung)
class NotaPembayaranPage extends StatefulWidget {
  final TransaksiPenjualanModel? transaksi;
  final String? noNota;
  final String? waktu;
  final String? pelanggan;
  final String? kasir;
  final String? customerPhone;
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
    this.customerPhone,
    this.items,
    this.totalBayar,
    this.tunaiDiterima,
    this.paymentMethod,
    this.userData,
  });

  @override
  State<NotaPembayaranPage> createState() => _NotaPembayaranPageState();
}

class _NotaPembayaranPageState extends State<NotaPembayaranPage> {
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

  final GlobalKey _receiptKey = GlobalKey();
  bool _isGeneratingImage = false;

  // Getters dengan fallback
  String get effectiveNoNota =>
      widget.transaksi?.code ?? widget.noNota ?? 'TRX-20260929-026';
  String get effectiveWaktu =>
      widget.transaksi?.notaTimeFormatted ?? widget.waktu ?? '29/09/2026 • 10:45 WIB';
  String get effectivePelanggan {
    if (widget.transaksi != null) {
      return widget.transaksi!.customerName.isNotEmpty
          ? widget.transaksi!.customerName
          : 'Pelanggan Umum';
    }
    return widget.pelanggan ?? 'Pelanggan Umum';
  }

  String get effectivePhone {
    if (widget.transaksi != null && widget.transaksi!.customerPhone.isNotEmpty) {
      return widget.transaksi!.customerPhone.trim();
    }
    return widget.customerPhone?.trim() ?? '';
  }

  String get effectiveKasir =>
      widget.transaksi?.kasirName ??
      widget.kasir ??
      widget.userData?['nama_lengkap'] ??
      'Kasir';

  List<TransaksiItemModel> get effectiveItems =>
      widget.transaksi?.items ?? widget.items ?? [];

  int get effectiveTotalBayar =>
      widget.transaksi?.totalBayar ?? widget.totalBayar ?? 0;

  String get effectivePaymentMethod =>
      widget.transaksi?.paymentMethod ?? widget.paymentMethod ?? 'Tunai';

  int get effectiveTunaiDiterima =>
      widget.transaksi?.tunaiDiterima ??
      widget.tunaiDiterima ??
      (effectivePaymentMethod == 'Tunai' ? effectiveTotalBayar : effectiveTotalBayar);

  int get effectiveKembalian {
    if (widget.transaksi != null) return widget.transaksi!.kembalian;
    if (effectivePaymentMethod == 'Tunai' &&
        effectiveTunaiDiterima > effectiveTotalBayar) {
      return effectiveTunaiDiterima - effectiveTotalBayar;
    }
    return 0;
  }

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  // Helper pemformat nomor WhatsApp (contoh: 08123... -> 628123...)
  String _formatWhatsAppPhone(String rawPhone) {
    String clean = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      clean = '62$clean';
    } else if (!clean.startsWith('62')) {
      clean = '62$clean';
    }
    return clean;
  }

  String _generateWhatsAppInvoiceText() {
    final buffer = StringBuffer();
    buffer.writeln('*BENGKEL ZALZABILA MOTOR*');
    buffer.writeln('Jl. Raya Industri No. 45 • Telp/WA: 0812-3456-7890');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*NOTA TRANSAKSI PEMBAYARAN*');
    buffer.writeln('No. Nota  : $effectiveNoNota');
    buffer.writeln('Waktu     : $effectiveWaktu');
    buffer.writeln('Pelanggan : $effectivePelanggan');
    if (effectivePhone.isNotEmpty) {
      buffer.writeln('No. HP    : $effectivePhone');
    }
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
    buffer.writeln('Status   : LUNAS');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Terima kasih telah mempercayakan motor Anda kepada Bengkel Zalzabila Motor!');
    buffer.writeln('Simpan nota digital ini sebagai bukti transaksi & garansi servis.');

    return buffer.toString();
  }

  // Render & Simpan Widget Struk menjadi File Gambar PNG
  Future<File?> _captureReceiptPng() async {
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Pixel ratio 3.0 menghasilkan gambar PNG tajam dan jernih
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final safeNota = effectiveNoNota.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${tempDir.path}/nota_$safeNota.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error export receipt PNG: $e');
      return null;
    }
  }

  // Kirim Nota via WhatsApp (PNG + Teks / Chat Langsung)
  void _handleShareWhatsApp() async {
    setState(() => _isGeneratingImage = true);

    final pngFile = await _captureReceiptPng();

    setState(() => _isGeneratingImage = false);

    if (!mounted) return;

    final invoiceText = _generateWhatsAppInvoiceText();
    final hasPhone = effectivePhone.isNotEmpty;
    final cleanPhone = hasPhone ? _formatWhatsAppPhone(effectivePhone) : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: cardBorder),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2B1D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF166534)),
                  ),
                  child: const Icon(Icons.chat_rounded, color: waGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kirim Nota ke WhatsApp',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPhone
                            ? 'Pelanggan: $effectivePelanggan (+$cleanPhone)'
                            : 'Pelanggan: $effectivePelanggan',
                        style: TextStyle(
                          color: hasPhone ? accentGreen : textMuted,
                          fontSize: 11,
                          fontWeight: hasPhone ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Opsi 1: Kirim Gambar PNG Nota + Rincian via WhatsApp
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              tileColor: const Color(0xFF10131B),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F2B1D),
                child: Icon(Icons.image_rounded, color: accentGreen, size: 20),
              ),
              title: const Text(
                'Kirim Gambar Nota (PNG) ke WA',
                style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Bagikan foto struk digital PNG resmi + caption teks',
                style: TextStyle(color: textDim, fontSize: 10.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: textDim),
              onTap: () async {
                Navigator.pop(ctx);
                if (pngFile != null) {
                  // ignore: deprecated_member_use
                  await Share.shareXFiles(
                    [XFile(pngFile.path)],
                    text: invoiceText,
                    subject: 'Nota Pembayaran $effectiveNoNota',
                  );
                } else {
                  // ignore: deprecated_member_use
                  await Share.share(
                    invoiceText,
                    subject: 'Nota Pembayaran $effectiveNoNota',
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Opsi 2: Buka Chat Langsung ke Nomor WhatsApp Pelanggan
            if (hasPhone) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: cardBorder),
                ),
                tileColor: const Color(0xFF10131B),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF102A1E),
                  child: Icon(Icons.send_rounded, color: waGreen, size: 20),
                ),
                title: Text(
                  'Chat WhatsApp (+$cleanPhone)',
                  style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Buka chat langsung dengan teks rincian nota siap kirim',
                  style: TextStyle(color: textDim, fontSize: 10.5),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: textDim),
                onTap: () async {
                  Navigator.pop(ctx);
                  final waUri = Uri.parse(
                    'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(invoiceText)}',
                  );
                  if (await canLaunchUrl(waUri)) {
                    await launchUrl(waUri, mode: LaunchMode.externalApplication);
                  } else {
                    Clipboard.setData(ClipboardData(text: invoiceText));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF142033),
                        content: Text('Teks disalin ke Clipboard! Silakan buka WhatsApp pelanggan.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            // Opsi 3: Salin Teks Nota
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              tileColor: const Color(0xFF10131B),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1E2330),
                child: Icon(Icons.copy_rounded, color: textMuted, size: 18),
              ),
              title: const Text(
                'Salin Teks Nota Lengkap',
                style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Salin rincian format teks ke clipboard HP',
                style: TextStyle(color: textDim, fontSize: 10.5),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: invoiceText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF0F2B1D),
                    content: Text('Teks nota berhasil disalin ke Clipboard!'),
                  ),
                );
              },
            ),
          ],
        ),
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

              // 2. Receipt Thermal Card (Dibungkus RepaintBoundary untuk Export Gambar PNG)
              RepaintBoundary(
                key: _receiptKey,
                child: Container(
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
                      if (effectivePhone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildMetaRow('No. WhatsApp', effectivePhone),
                      ],
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
              ),
              const SizedBox(height: 24),

              // 3. Tombol Bagikan Nota via WhatsApp (PNG + Teks)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingImage ? null : _handleShareWhatsApp,
                  icon: _isGeneratingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: textWhite, strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_rounded, color: textWhite, size: 18),
                  label: Text(
                    _isGeneratingImage
                        ? 'Membuat Gambar Nota PNG...'
                        : (effectivePhone.isNotEmpty
                            ? 'Kirim Nota ke WA ($effectivePhone)'
                            : 'Bagikan Nota via WhatsApp'),
                    style: const TextStyle(
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
