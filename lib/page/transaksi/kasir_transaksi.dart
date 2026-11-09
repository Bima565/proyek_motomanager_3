import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/jasa_service.dart';
import '../../services/barang_service.dart';
import '../../services/transaksi_service.dart';
import '../kelola_stok_jasa.dart';

// Alias backward compatibility
typedef KasirItemModel = TransaksiItemModel;

/// Screen 3 - (FR07) Kasir & Transaksi
class KasirTransaksiPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final TransaksiPenjualanModel? initialTransaksi;

  const KasirTransaksiPage({
    super.key,
    this.userData,
    this.initialTransaksi,
  });

  @override
  State<KasirTransaksiPage> createState() => _KasirTransaksiPageState();
}

class _KasirTransaksiPageState extends State<KasirTransaksiPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  // 1. Data Pelanggan & Motor (Tanpa Dummy - Murni Input Manual)
  String _customerName = '';
  String _vehicleInfo = '';
  String _customerPhone = '';
  late String _trxCode;

  // Metode Pembayaran ('Tunai' atau 'QRIS')
  String _paymentMethod = 'Tunai';

  // Layanan Jasa Terpilih di bar atas
  TransaksiItemModel? _selectedServiceItem;

  // Daftar Item Transaksi
  late List<TransaksiItemModel> _items;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaksi != null) {
      final t = widget.initialTransaksi!;
      _trxCode = t.code;
      _customerName = t.customerName == 'Pelanggan Umum' ? '' : t.customerName;
      _vehicleInfo = t.vehicleInfo;
      _customerPhone = t.customerPhone;
      _paymentMethod = t.paymentMethod;
      _items = List.from(t.items);
    } else {
      _trxCode = TransaksiService().generateTrxCode();
      _items = [];
    }
  }

  // Total Bayar Otomatis dari Checkout Item
  int get _totalBayar =>
      _items.fold(0, (total, item) => total + item.total);

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  // Cek Stok Barang dari BarangService
  int _getItemStock(String name) {
    final parts = BarangService().barangs;
    final match = parts.where(
      (p) => p.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (match.isNotEmpty) {
      return match.first.stock;
    }
    return 0;
  }

  // Edit Data Pelanggan & Motor (Tanpa Plat Nomor)
  void _showEditCustomerDialog() {
    final nameCtrl = TextEditingController(text: _customerName);
    final vehicleCtrl = TextEditingController(text: _vehicleInfo);
    final phoneCtrl = TextEditingController(text: _customerPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Text(
          'Edit Data Pelanggan & Motor',
          style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Pelanggan', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDecoration('Contoh: Bpk. Budi'),
              ),
              const SizedBox(height: 12),
              const Text('Motor / Kendaraan', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: vehicleCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDecoration('Contoh: Honda Vario 160'),
              ),
              const SizedBox(height: 12),
              const Text('No. WhatsApp / HP', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDecoration('Contoh: 081234567890'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _customerName = nameCtrl.text.trim();
                _vehicleInfo = vehicleCtrl.text.trim();
                _customerPhone = phoneCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: textWhite)),
          ),
        ],
      ),
    );
  }

  // Tambah Item ke Transaksi
  void _addItemToTransaction({
    required String name,
    required String category,
    required String subInfo,
    required int price,
    required bool isService,
  }) {
    if (!isService) {
      final availableStock = _getItemStock(name);
      if (availableStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF3B1517),
            content: Text('Stok barang "$name" habis (0 Pcs)! Tidak dapat ditambahkan.'),
          ),
        );
        return;
      }

      final existingIndex = _items.indexWhere(
        (i) => i.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
      if (existingIndex >= 0) {
        if (_items[existingIndex].quantity + 1 > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF3B1517),
              content: Text('Batas stok "$name" tercapai! Stok hanya tersedia $availableStock Pcs.'),
            ),
          );
          return;
        }
        setState(() {
          _items[existingIndex].quantity += 1;
        });
        return;
      }
    }

    setState(() {
      final existingIndex = _items.indexWhere(
        (i) => i.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
      if (existingIndex >= 0) {
        _items[existingIndex].quantity += 1;
      } else {
        _items.add(
          TransaksiItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            category: category,
            subInfo: subInfo,
            price: price,
            quantity: 1,
            isService: isService,
          ),
        );
      }
    });
  }

  // Modal Sheet: Khusus Layanan Jasa Servis Saja (Tanpa Barang)
  void _showPickJasaSheet() {
    String searchQuery = '';
    final liveServices = JasaService().services;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = liveServices.where((j) {
            final q = searchQuery.toLowerCase();
            return j.name.toLowerCase().contains(q) ||
                (j.category?.toLowerCase().contains(q) ?? false);
          }).toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Layanan Jasa Servis',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1C14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${filtered.length} Jasa',
                        style: const TextStyle(
                          color: accentOrange,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar Khusus Jasa
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    onChanged: (val) => setSheetState(() => searchQuery = val.trim()),
                    style: const TextStyle(color: textWhite, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Cari layanan jasa servis...',
                      hintStyle: TextStyle(color: textDim, fontSize: 11),
                      prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.build_circle_outlined, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Layanan jasa servis tidak ditemukan',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KelolaStokJasaPage(
                                    showBottomNav: false,
                                    userData: widget.userData,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Text(
                                '+ Buka Tambah Data Stok & Jasa',
                                style: TextStyle(color: accentOrange, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final j = filtered[index];
                        return InkWell(
                          onTap: () {
                            _addItemToTransaction(
                              name: j.name,
                              category: 'Jasa Servis',
                              subInfo: j.category ?? 'Servis Motor',
                              price: j.price,
                              isService: true,
                            );

                            setState(() {
                              _selectedServiceItem = TransaksiItemModel(
                                id: j.id,
                                name: j.name,
                                category: 'Jasa Servis',
                                subInfo: j.category ?? 'Servis Motor',
                                price: j.price,
                                isService: true,
                              );
                            });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF143322),
                                duration: const Duration(seconds: 1),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Jasa "${j.name}" ditambahkan ke transaksi!')),
                                  ],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10131B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.build_rounded, color: accentOrange, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j.name,
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        j.category ?? 'Layanan Servis',
                                        style: const TextStyle(color: textDim, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatRupiah(j.price),
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Modal Sheet: Khusus Barang Saja dari Data Stok (Tanpa Jasa Servis)
  void _showPickBarangSheet() {
    String searchQuery = '';
    final liveBarang = BarangService().barangs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = liveBarang.where((b) {
            final q = searchQuery.toLowerCase();
            return b.name.toLowerCase().contains(q) || b.category.toLowerCase().contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Barang dari Stok',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF142C1B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${filtered.length} Barang',
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar Khusus Barang
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    onChanged: (val) => setSheetState(() => searchQuery = val.trim()),
                    style: const TextStyle(color: textWhite, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama barang...',
                      hintStyle: TextStyle(color: textDim, fontSize: 11),
                      prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Barang tidak ditemukan di data stok',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KelolaStokJasaPage(
                                    showBottomNav: false,
                                    userData: widget.userData,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Text(
                                '+ Buka Tambah Data Stok & Jasa',
                                style: TextStyle(color: accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isOutOfStock = item.stock <= 0;

                        return InkWell(
                          onTap: () {
                            if (isOutOfStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF3B1517),
                                  content: Text('Barang "${item.name}" stoknya habis (0 Pcs)! Tidak dapat dipilih.'),
                                ),
                              );
                              return;
                            }

                            _addItemToTransaction(
                              name: item.name,
                              category: item.category,
                              subInfo: 'Stok: ${item.stock} ${item.unit}',
                              price: item.sellPrice,
                              isService: false,
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF143322),
                                duration: const Duration(seconds: 1),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Barang "${item.name}" ditambahkan ke transaksi!')),
                                  ],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10131B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.token_rounded, color: accentBlue, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.category} • Stok: ${item.stock} ${item.unit}',
                                        style: const TextStyle(color: textDim, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOutOfStock)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A1014),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: accentRed.withValues(alpha: 0.5)),
                                    ),
                                    child: const Text(
                                      'Habis',
                                      style: TextStyle(color: accentRed, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Text(
                                  _formatRupiah(item.sellPrice),
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Tombol + Tambah Merah: Buka Halaman Tambah Data Stok & Jasa
  void _openTambahDataStokDanJasa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KelolaStokJasaPage(
          showBottomNav: false,
          userData: widget.userData,
        ),
      ),
    );
  }

  // Tombol Save: Simpan Sebagai Belum Selesai & Kembali ke Menu Awal Transaksi
  void _handleSaveBelumSelesai() async {
    final kasirName = widget.userData?['nama_lengkap'] ?? 'Kasir';

    final savedTrx = TransaksiPenjualanModel(
      id: widget.initialTransaksi?.id.isNotEmpty == true
          ? widget.initialTransaksi!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      code: _trxCode,
      dateTime: widget.initialTransaksi?.dateTime ?? DateTime.now(),
      customerName: _customerName.isNotEmpty ? _customerName : 'Pelanggan Umum',
      vehicleInfo: _vehicleInfo,
      customerPhone: _customerPhone,
      kasirName: kasirName,
      items: List.from(_items),
      totalBayar: _totalBayar,
      paymentMethod: _paymentMethod,
      tunaiDiterima: _totalBayar,
      kembalian: 0,
      status: 'Belum Selesai',
    );

    await TransaksiService().saveTransaksi(savedTrx);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF142033),
        content: Text('Transaksi $_trxCode berhasil disimpan (Belum Selesai).'),
      ),
    );
    Navigator.pop(context);
  }

  // Proses Pembayaran: Simpan Lunas & Langsung Kembali ke Menu Awal Transaksi
  void _handleProcessPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Daftar item transaksi masih kosong! Tambahkan item terlebih dahulu.'),
        ),
      );
      return;
    }

    // Validasi stok barang sebelum checkout
    for (final item in _items) {
      if (!item.isService) {
        final currentStock = _getItemStock(item.name);
        if (currentStock <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF3B1517),
              content: Text('Barang "${item.name}" stoknya habis! Hapus dari transaksi untuk melanjutkan.'),
            ),
          );
          return;
        }
        if (item.quantity > currentStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF3B1517),
              content: Text('Jumlah "${item.name}" (${item.quantity} pcs) melebihi stok tersedia ($currentStock pcs)!'),
            ),
          );
          return;
        }
      }
    }

    final kasirName = widget.userData?['nama_lengkap'] ?? 'Kasir';

    final completedTrx = TransaksiPenjualanModel(
      id: widget.initialTransaksi?.id.isNotEmpty == true
          ? widget.initialTransaksi!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      code: _trxCode,
      dateTime: DateTime.now(),
      customerName: _customerName.isNotEmpty ? _customerName : 'Pelanggan Umum',
      vehicleInfo: _vehicleInfo,
      customerPhone: _customerPhone,
      kasirName: kasirName,
      items: List.from(_items),
      totalBayar: _totalBayar,
      paymentMethod: _paymentMethod,
      tunaiDiterima: _totalBayar,
      kembalian: 0,
      status: 'Lunas',
    );

    // Simpan ke TransaksiService (Cloud Firestore + Local state) & potong stok barang
    await TransaksiService().saveTransaksi(completedTrx);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF143322),
        content: Text('Transaksi ${completedTrx.code} berhasil diselesaikan & tersimpan!'),
      ),
    );

    // Langsung kembali ke tampilan awal menu transaksi
    Navigator.pop(context);
  }

  InputDecoration _buildInputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: textDim, fontSize: 12),
      filled: true,
      fillColor: bgDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasirName = widget.userData?['nama_lengkap'] ?? 'Kasir';

    return AnimatedBuilder(
      animation: Listenable.merge([
        JasaService().servicesNotifier,
        BarangService().barangsNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgDark,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Tombol Kembali, Judul, Tombol Save & Kasir)
                  _buildHeader(kasirName),
                  const SizedBox(height: 16),

                  // 2. Card Data Pelanggan & Motor (Tanpa Plat)
                  _buildDataPelangganCard(),
                  const SizedBox(height: 16),

                  // 3. Dropdown Pilih Jasa Servis Saja + Tombol Merah + Tambah
                  _buildServiceSelectorSection(),
                  const SizedBox(height: 20),

                  // 4. Section Daftar Item Transaksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Item Transaksi',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191D2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder, width: 1),
                        ),
                        child: Text(
                          '${_items.length} Item',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kotak Daftar Item Transaksi (Murni UI saat kosong, tombol input ada di bawah)
                  if (_items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.shopping_basket_outlined, color: textDim, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada item ditambahkan',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildItemCard(item),
                        )),

                  // 5. Tombol Tambah Item Transaksi Barang (Khusus Barang Saja)
                  GestureDetector(
                    onTap: _showPickBarangSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11141E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, color: accentBlue, size: 16),
                            SizedBox(width: 8),
                            Text(
                              '+ Tambah Item Transaksi Barang',
                              style: TextStyle(
                                color: textWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Card Summary & Metode Pembayaran (Tanpa Kembalian / Kelebihan)
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // 7. Tombol Besar Proses Pembayaran
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleProcessPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentRed,
                        foregroundColor: textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proses Pembayaran (${_formatRupiah(_totalBayar)})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String kasirName) {
    return Row(
      children: [
        const BackButtonCircle(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kasir & Transaksi',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_trxCode • Kasir: $kasirName',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Tombol SAVE: Simpan Transaksi Belum Selesai & Kembali ke Menu Awal
        GestureDetector(
          onTap: _handleSaveBelumSelesai,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.save_outlined, color: accentGreen, size: 14),
                SizedBox(width: 5),
                Text(
                  'Save',
                  style: TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Card Data Pelanggan & Motor (Tanpa Plat Nomor)
  Widget _buildDataPelangganCard() {
    final hasCustomer = _customerName.isNotEmpty;
    final hasDetails = _vehicleInfo.isNotEmpty || _customerPhone.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA PELANGGAN & MOTOR',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCustomer ? _customerName : 'Pelanggan Umum (Belum diisi)',
                  style: TextStyle(
                    color: hasCustomer ? textWhite : textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasDetails
                      ? '$_vehicleInfo${_vehicleInfo.isNotEmpty && _customerPhone.isNotEmpty ? ' • ' : ''}$_customerPhone'
                      : 'Ketuk EDIT untuk mengisi info motor & kontak',
                  style: const TextStyle(
                    color: textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showEditCustomerDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF142033),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A8A), width: 1),
              ),
              child: const Text(
                'EDIT',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Baris Pilih Jasa Servis Saja + Tombol + Tambah Merah
  Widget _buildServiceSelectorSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showPickJasaSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedServiceItem != null ? Icons.build_rounded : Icons.search_rounded,
                    color: _selectedServiceItem != null ? accentOrange : textDim,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedServiceItem != null
                          ? '${_selectedServiceItem!.name} (${_formatRupiah(_selectedServiceItem!.price)})'
                          : 'Pilih layanan jasa servis...',
                      style: TextStyle(
                        color: _selectedServiceItem != null ? textWhite : textMuted,
                        fontSize: 11.5,
                        fontWeight: _selectedServiceItem != null ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: textDim, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openTambahDataStokDanJasa,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '+ Tambah',
              style: TextStyle(
                color: textWhite,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card Item Transaksi
  Widget _buildItemCard(TransaksiItemModel item) {
    final availableStock = !item.isService ? _getItemStock(item.name) : null;
    final isMaxReached = !item.isService && availableStock != null && item.quantity >= availableStock;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Icon Box / Wrench
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isService
                    ? accentOrange.withValues(alpha: 0.7)
                    : accentBlue.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                item.isService ? Icons.build_rounded : Icons.token_rounded,
                color: item.isService ? accentOrange : accentBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Info Item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.isService
                      ? '${item.category} • ${item.quantity}x'
                      : 'Barang • Stok: $availableStock • ${item.quantity}x',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatRupiah(item.total),
                      style: const TextStyle(
                        color: accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    // Tombol Kontrol Qty (-)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (item.quantity > 1) {
                            item.quantity--;
                          } else {
                            _items.remove(item);
                          }
                        });
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161A24),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Center(
                          child: Icon(Icons.remove, color: textMuted, size: 12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Tombol Kontrol Qty (+)
                    GestureDetector(
                      onTap: () {
                        if (!item.isService) {
                          final stock = _getItemStock(item.name);
                          if (item.quantity + 1 > stock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF3B1517),
                                content: Text('Batas stok barang tercapai ($stock Pcs)!'),
                              ),
                            );
                            return;
                          }
                        }
                        setState(() {
                          item.quantity++;
                        });
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isMaxReached ? const Color(0xFF161820) : const Color(0xFF161A24),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isMaxReached ? textDim : cardBorder),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: isMaxReached ? textDim : textWhite,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Hapus (✕)
          GestureDetector(
            onTap: () {
              setState(() => _items.remove(item));
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF281116),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5A1E24), width: 1),
              ),
              child: const Center(
                child: Text(
                  '✕',
                  style: TextStyle(color: accentRed, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Summary
  Widget _buildSummaryCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${_items.length} item)',
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
              Text(
                _formatRupiah(_totalBayar),
                style: const TextStyle(color: textWhite, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bayar',
                style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatRupiah(_totalBayar),
                style: const TextStyle(
                  color: accentGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Toggle Metode Pembayaran
          Row(
            children: [
              // Tunai (Cash)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'Tunai'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'Tunai' ? accentRed : const Color(0xFF101420),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _paymentMethod == 'Tunai' ? accentRed : cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tunai (Cash)',
                        style: TextStyle(
                          color: _paymentMethod == 'Tunai' ? textWhite : textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // QRIS / Transfer
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 'QRIS'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'QRIS' ? accentRed : const Color(0xFF101420),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _paymentMethod == 'QRIS' ? accentRed : cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'QRIS / Transfer',
                        style: TextStyle(
                          color: _paymentMethod == 'QRIS' ? textWhite : textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_paymentMethod == 'QRIS') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E3A8A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: accentBlue, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tunjukkan QRIS Bengkel kepada pelanggan untuk pembayaran digital langsung.',
                      style: TextStyle(color: textWhite, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
