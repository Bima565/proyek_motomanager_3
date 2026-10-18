import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';
import 'data_sparepart.dart';
import 'tambah_sparepart.dart';

/// Screen 11 - (FR05, FR06) Navigasi Tambah Data Stok & Jasa
class KelolaStokJasaPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const KelolaStokJasaPage({super.key, this.userData});

  @override
  State<KelolaStokJasaPage> createState() => _KelolaStokJasaPageState();
}

class _KelolaStokJasaPageState extends State<KelolaStokJasaPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Judul
              const Text(
                'Tambah Data Stok & Jasa',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Subheader Kategori Input
              const Text(
                'PILIH KATEGORI INPUT',
                style: TextStyle(
                  color: textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              // 3. Card 1: Tambah Sparepart & Stok (FR05)
              _buildCategoryCard(
                title: 'Tambah Sparepart & Stok',
                description:
                    'Input stok baru suku cadang, oli, ban, busi, aki, kampas rem, serta atur harga modal & jual.',
                icon: Icons.all_inbox_rounded,
                iconColor: accentBlue,
                iconBg: const Color(0xFF101B2B),
                borderColor: const Color(0xFF1E3A5F),
                buttonLabel: 'Buka Data Stok ›',
                buttonBg: const Color(0xFF0F1E33),
                buttonTextColor: const Color(0xFF60A5FA),
                onCardTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TambahSparepartPage(),
                    ),
                  );
                },
                onButtonTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DataSparepartPage(userData: widget.userData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4. Card 2: Tambah Layanan Jasa (FR06)
              _buildCategoryCard(
                title: 'Tambah Layanan Jasa',
                description:
                    'Input jenis pengerjaan servis baru, tune-up, servis CVT, overhaul mesin, tambal ban, dan tarif jasa.',
                icon: Icons.construction_rounded,
                iconColor: accentRed,
                iconBg: const Color(0xFF281116),
                borderColor: const Color(0xFF4A1A22),
                buttonLabel: 'Buka Master Jasa ›',
                buttonBg: const Color(0xFF281116),
                buttonTextColor: const Color(0xFFF87171),
                onCardTap: () {
                  _showMasterJasaDialog();
                },
                onButtonTap: () {
                  _showMasterJasaDialog();
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MotoBottomNav(
        currentIndex: 2,
        userData: widget.userData,
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color borderColor,
    required String buttonLabel,
    required Color buttonBg,
    required Color buttonTextColor,
    required VoidCallback onCardTap,
    required VoidCallback onButtonTap,
  }) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Teks Judul & Deskripsi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Chevron Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tombol Pill Navigasi
            GestureDetector(
              onTap: onButtonTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: buttonTextColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMasterJasaDialog() {
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
            const Text(
              'Master Layanan Jasa (FR06)',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceItem('Servis Ringan / Tune Up', 'Rp 45.000'),
            _buildServiceItem('Servis CVT Komplit', 'Rp 65.000'),
            _buildServiceItem('Ganti Oli Mesin / Gardan', 'Rp 10.000'),
            _buildServiceItem('Tambal Ban Tubeless', 'Rp 15.000'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF143322),
                      content: Text('Form Tambah Jasa baru berhasil dibuka'),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Tarif Jasa Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentRed,
                  foregroundColor: textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: textWhite, fontSize: 13)),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
