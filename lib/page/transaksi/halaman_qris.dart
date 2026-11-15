import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/transaksi_service.dart';
import 'nota_pembayaran.dart';

/// Halaman Pembayaran QRIS MotoManage
/// Menampilkan QR code statis bengkel dari assets/qrris/qris_pembayaran.jpg
/// dengan verifikasi/konfirmasi sebelum lanjut ke Nota Pembayaran.
class HalamanQrisPage extends StatefulWidget {
  final TransaksiPenjualanModel transaksi;
  final Map<String, dynamic>? userData;

  const HalamanQrisPage({
    super.key,
    required this.transaksi,
    this.userData,
  });

  @override
  State<HalamanQrisPage> createState() => _HalamanQrisPageState();
}

class _HalamanQrisPageState extends State<HalamanQrisPage> {
  // Palet Warna Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  bool _isProcessing = false;

  /// Menampilkan dialog konfirmasi pembayaran sebelum menyimpan transaksi & membuka nota
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: accentGreen, size: 24),
              SizedBox(width: 10),
              Text(
                'Konfirmasi QRIS',
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
                'Pastikan dana pembayaran telah berhasil masuk ke mutasi/notifikasi bengkel:',
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PEMBAYARAN',
                      style: const TextStyle(
                        color: textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(widget.transaksi.totalBayar),
                      style: const TextStyle(
                        color: accentGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pelanggan: ${widget.transaksi.customerName}',
                      style: const TextStyle(color: textWhite, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: textDim)),
            ),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pop(dialogCtx);
                      _confirmAndCompleteTransaction();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, Pembayaran Lunas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Eksekusi simpan transaksi & alihkan ke Nota Pembayaran
  Future<void> _confirmAndCompleteTransaction() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Simpan transaksi ke Firestore & local state via TransaksiService
      await TransaksiService().saveTransaksi(widget.transaksi);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          content: Text(
            'Pembayaran QRIS ${widget.transaksi.code} berhasil diverifikasi!',
            style: const TextStyle(color: textWhite),
          ),
        ),
      );

      // 2. Langsung menuju halaman Nota Pembayaran
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotaPembayaranPage(
            transaksi: widget.transaksi,
            userData: widget.userData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3B1517),
          content: Text('Gagal memproses transaksi: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Halaman
            _buildHeader(),

            // 2. Konten Utama (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Card Ringkasan Tagihan
                    _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // Card QRIS Display
                    _buildQrisCard(),
                    const SizedBox(height: 16),

                    // Panduan Pelanggan
                    _buildInstructionCard(),
                  ],
                ),
              ),
            ),

            // 3. Tombol Lanjut / Konfirmasi di Bagian Bawah
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: bgDark,
        border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          const BackButtonCircle(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran QRIS',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.transaksi.code,
                  style: const TextStyle(
                    color: accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2_rounded, color: accentBlue, size: 16),
                SizedBox(width: 5),
                Text(
                  'QRIS',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL YANG HARUS DIBAYAR',
            style: TextStyle(
              color: textDim,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatRupiah(widget.transaksi.totalBayar),
            style: const TextStyle(
              color: textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaItem('Pelanggan', widget.transaksi.customerName),
              _buildMetaItem('Kendaraan', widget.transaksi.vehicleInfo.isNotEmpty ? widget.transaksi.vehicleInfo : '-'),
              _buildMetaItem('Kasir', widget.transaksi.kasirName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: textDim, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQrisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Frame Putih untuk Kontras Scan QRIS yang Optimal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/qrris/qris_pembayaran.jpg',
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 240,
                    height: 240,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Gambar QRIS tidak ditemukan\n(assets/qrris/qris_pembayaran.jpg)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'MotoManage Workshop Digital Pay',
            style: TextStyle(
              color: textWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mendukung GoPay, OVO, DANA, BCA, Mandiri, BRI, & Semua Bank/e-Wallet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: accentBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Instruksi Pembayaran Pelanggan:',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Buka aplikasi e-Wallet atau m-Banking.\n2. Arahkan scanner ke kode QR di atas.\n3. Masukkan / cek nominal sesuai total bayar.\n4. Kasir klik tombol di bawah setelah dana masuk.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: bgDark,
        border: Border(top: BorderSide(color: cardBorder, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _showConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentRed,
            foregroundColor: textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: textWhite,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Konfirmasi Pembayaran Selesai',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
