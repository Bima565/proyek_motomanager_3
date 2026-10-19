import 'package:flutter/material.dart';
import '../components/moto_bottom_nav.dart';
import 'kasir_transaksi.dart';
import 'nota_pembayaran.dart';

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
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  String _selectedFilter = 'Semua';

  final List<Map<String, dynamic>> _transactions = [
    {
      'code': '#TRX-005',
      'time': '08:30 20/9/2026',
      'payment': 'QRIS',
      'amount': 'Rp 40.000',
      'customer': 'Dian Pratama',
      'vehicle': 'Yamaha NMAX',
      'service': 'Tambal Tubeless + Cairan Ban',
    },
    {
      'code': '#TRX-004',
      'time': '08:30 20/9/2026',
      'payment': 'TUNAI',
      'amount': 'Rp 95.000',
      'customer': 'Rudi Hartono',
      'vehicle': 'Honda Supra X 125',
      'service': 'Bersihkan Karburator + Rantai Roda',
    },
    {
      'code': '#TRX-003',
      'time': '08:30 20/9/2026',
      'payment': 'TUNAI',
      'amount': 'Rp 80.000',
      'customer': 'Ibu Sri Wahyuni',
      'vehicle': 'Yamaha Mio M3',
      'service': 'Ganti Oli Mesin & Gardan',
    },
    {
      'code': '#TRX-002',
      'time': '08:30 20/9/2026',
      'payment': 'QRIS',
      'amount': 'Rp 130.000',
      'customer': 'Ahmad Fauzi',
      'vehicle': 'Honda Vario 160',
      'service': 'Servis CVT & Rem + Roller + Kampas',
    },
    {
      'code': '#TRX-001',
      'time': '08:30 20/9/2026',
      'payment': 'TUNAI',
      'amount': 'Rp 105.000',
      'customer': 'Budi Santoso',
      'vehicle': 'Honda Beat FI',
      'service': 'Servis Ringan + Oli MPX2 + Busi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'Semua'
        ? _transactions
        : _transactions
            .where((t) =>
                t['payment'].toString().toUpperCase() ==
                _selectedFilter.toUpperCase())
            .toList();

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // Filter Pill Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        dropdownColor: cardBg,
                        icon: const Icon(Icons.arrow_drop_down, color: textDim, size: 16),
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Semua', 'QRIS', 'TUNAI']
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text('Filter: $f'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFilter = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Daftar Transaksi List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final trx = filtered[index];
                  final isQris = trx['payment'] == 'QRIS';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotaPembayaranPage(
                            noNota: trx['code'],
                            waktu: trx['time'],
                            pelanggan: '${trx['customer']} (${trx['vehicle']})',
                            kasir: widget.userData?['nama_lengkap'] ?? 'Sri Ekowati',
                            items: [
                              KasirItemModel(
                                id: '1',
                                name: trx['service'],
                                category: 'Layanan Servis',
                                subInfo: 'Transaksi Kasir',
                                price: int.tryParse(trx['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                                quantity: 1,
                                isService: true,
                              ),
                            ],
                            totalBayar: int.tryParse(trx['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                            tunaiDiterima: int.tryParse(trx['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                            paymentMethod: trx['payment'] == 'QRIS' ? 'QRIS' : 'Tunai',
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
                          // Baris 1: Kode TRX, Badge Payment, Nominal Hijau
                          Row(
                            children: [
                              Text(
                                '${trx['code']} • ${trx['time']}',
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
                                  color: isQris
                                      ? const Color(0xFF0C243B)
                                      : const Color(0xFF0F2E1E),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isQris ? const Color(0xFF1E40AF) : const Color(0xFF166534),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  trx['payment'],
                                  style: TextStyle(
                                    color: isQris ? accentBlue : accentGreen,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                trx['amount'],
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
                            '${trx['customer']} • ${trx['vehicle']}',
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
                                  trx['service'],
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

            // 3. Tombol Tambah Transaksi Baru (Sticky Red Button di atas Bottom Nav)
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
}
