import 'package:flutter/material.dart';
import 'kasir_transaksi.dart';

/// Screen 4 - (FR07) Nota Pembayaran & Bagikan WA
class NotaPembayaranPage extends StatelessWidget {
  final String noNota;
  final String waktu;
  final String pelanggan;
  final String kasir;
  final List<KasirItemModel> items;
  final int totalBayar;
  final int tunaiDiterima;
  final String paymentMethod;
  final Map<String, dynamic>? userData;

  const NotaPembayaranPage({
    super.key,
    required this.noNota,
    required this.waktu,
    required this.pelanggan,
    required this.kasir,
    required this.items,
    required this.totalBayar,
    required this.tunaiDiterima,
    this.paymentMethod = 'Tunai',
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

  void _shareViaWhatsApp(BuildContext context) {
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
                'Nota transaksi berhasil dibagikan ke WhatsApp pelanggan!',
                style: TextStyle(color: textWhite, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printReceiptPdf(BuildContext context) {
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
            Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Struk transaksi (PDF) sedang dicetak / disimpan...',
                style: TextStyle(color: textWhite, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int kembalian = tunaiDiterima > totalBayar ? tunaiDiterima - totalBayar : 0;

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
                    _buildMetaRow('No. Nota', noNota, isBoldValue: true),
                    const SizedBox(height: 6),
                    _buildMetaRow('Waktu', waktu),
                    const SizedBox(height: 6),
                    _buildMetaRow('Pelanggan', pelanggan),
                    const SizedBox(height: 6),
                    _buildMetaRow('Kasir', kasir),
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
                    ...items.asMap().entries.map((entry) {
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
                          _formatRupiah(totalBayar),
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
                          paymentMethod == 'Tunai' ? 'Tunai Diterima' : 'Metode Pembayaran',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          paymentMethod == 'Tunai'
                              ? _formatRupiah(tunaiDiterima)
                              : 'QRIS / Non-Tunai',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (paymentMethod == 'Tunai' && kembalian > 0) ...[
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
                    // Kembali ke layar sebelumnya (atau 2 layar sebelumnya)
                    Navigator.pop(context);
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
            color: textDim,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBoldValue ? textWhite : const Color(0xFFE5E7EB),
            fontSize: 10,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
