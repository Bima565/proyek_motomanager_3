import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/jasa_service.dart';
import '../../services/sparepart_service.dart';
import '../../services/transaksi_service.dart';
import 'nota_pembayaran.dart';

// Alias backward compatibility
typedef KasirItemModel = TransaksiItemModel;

/// Screen 3 - (FR07) Kasir & Transaksi
class KasirTransaksiPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const KasirTransaksiPage({super.key, this.userData});

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

  // Data Pelanggan & Motor
  String _customerName = 'Pelanggan Umum';
  String _vehicleInfo = 'Honda Vario 160';
  String _policeNumber = 'B 4921 KDF';
  String _customerPhone = '0812-9834-2109';
  late String _trxCode;

  // Metode Pembayaran ('Tunai' atau 'QRIS')
  String _paymentMethod = 'Tunai';

  // Controller Uang Tunai Diterima
  final TextEditingController _cashReceivedController =
      TextEditingController();

  // Mode pemilihan katalog aktif ('Jasa Servis' atau 'Sparepart')
  String _selectedCatalogType = 'Jasa Servis';
  TransaksiItemModel? _selectedCatalogItem;

  // Daftar Item Transaksi
  late List<TransaksiItemModel> _items;

  @override
  void initState() {
    super.initState();
    _trxCode = TransaksiService().generateTrxCode();
    _items = [
      TransaksiItemModel(
        id: 'init_1',
        name: 'Servis Rutin Ringan',
        category: 'Jasa Servis',
        subInfo: 'Tune-up & Injeksi',
        price: 75000,
        quantity: 1,
        isService: true,
      ),
      TransaksiItemModel(
        id: 'init_2',
        name: 'Oli Mesin MPX2 Matic',
        category: 'Sparepart',
        subInfo: 'Oli & Pelumas',
        price: 54000,
        quantity: 1,
        isService: false,
      ),
    ];
    _cashReceivedController.text = '150000';
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  int get _totalBayar =>
      _items.fold(0, (total, item) => total + item.total);

  int get _tunaiDiterima {
    if (_paymentMethod != 'Tunai') return _totalBayar;
    final parsed = int.tryParse(
        _cashReceivedController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    return parsed ?? 0;
  }

  int get _kembalian =>
      _paymentMethod == 'Tunai' && _tunaiDiterima >= _totalBayar
          ? _tunaiDiterima - _totalBayar
          : 0;

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  void _showEditCustomerDialog() {
    final nameCtrl = TextEditingController(text: _customerName);
    final vehicleCtrl = TextEditingController(text: _vehicleInfo);
    final platCtrl = TextEditingController(text: _policeNumber);
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
                decoration: _buildInputDecoration('Nama pelanggan'),
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
              const Text('Nomor Plat', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: platCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDecoration('Contoh: B 4921 KDF'),
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
                _policeNumber = platCtrl.text.trim();
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

  void _addItemToTransaction({
    required String name,
    required String category,
    required String subInfo,
    required int price,
    required bool isService,
  }) {
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

  void _handleTambahButton() {
    if (_selectedCatalogItem != null) {
      _addItemToTransaction(
        name: _selectedCatalogItem!.name,
        category: _selectedCatalogItem!.category,
        subInfo: _selectedCatalogItem!.subInfo,
        price: _selectedCatalogItem!.price,
        isService: _selectedCatalogItem!.isService,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          duration: const Duration(seconds: 1),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('1x "${_selectedCatalogItem!.name}" ditambahkan ke transaksi!'),
              ),
            ],
          ),
        ),
      );
    } else {
      _showPickFromHistorySheet(initialCategory: _selectedCatalogType);
    }
  }

  void _showPickFromHistorySheet({String? initialCategory}) {
    String selectedCategory = initialCategory ?? _selectedCatalogType;
    String searchQuery = '';

    final services = JasaService().services;
    final spareparts = SparepartService().spareparts;

    // Fallback default jika data Firestore belum sinkron atau offline
    final defaultServices = [
      {'name': 'Servis Rutin Ringan', 'category': 'Jasa Servis', 'price': 75000, 'isService': true, 'subInfo': 'Tune-up & Injeksi'},
      {'name': 'Servis CVT Matic Lengkap', 'category': 'Jasa Servis', 'price': 65000, 'isService': true, 'subInfo': 'Pembersihan & Pelumasan CVT'},
      {'name': 'Ganti Oli & Cek Ringan', 'category': 'Jasa Servis', 'price': 25000, 'isService': true, 'subInfo': 'Ongkos Ganti Oli & Cek Baut'},
      {'name': 'Overhaul / Turun Mesin', 'category': 'Jasa Servis', 'price': 250000, 'isService': true, 'subInfo': 'Bongkar & Rakit Mesin Total'},
      {'name': 'Tune Up Injeksi', 'category': 'Jasa Servis', 'price': 85000, 'isService': true, 'subInfo': 'Reset ECU & Injektor'},
    ];

    final defaultSpareparts = [
      {'name': 'Oli Mesin MPX2 Matic', 'category': 'Oli & Pelumas', 'price': 54000, 'isService': false, 'subInfo': 'Stok: 12 Pcs', 'stock': 12},
      {'name': 'Kampas Rem Depan Vario', 'category': 'Pengereman', 'price': 45000, 'isService': false, 'subInfo': 'Stok: 8 Pcs', 'stock': 8},
      {'name': 'Busi Denso U24EPR9', 'category': 'Kelistrikan', 'price': 25000, 'isService': false, 'subInfo': 'Stok: 15 Pcs', 'stock': 15},
      {'name': 'Vanbelt / V-Belt Kit', 'category': 'Transmisi CVT', 'price': 135000, 'isService': false, 'subInfo': 'Stok: 5 Pcs', 'stock': 5},
      {'name': 'Ban Tubeless IRC 90/90-14', 'category': 'Ban & Roda', 'price': 185000, 'isService': false, 'subInfo': 'Stok: 4 Pcs', 'stock': 4},
    ];

    final jasaItems = services.isNotEmpty
        ? services.map((j) => {
            'name': j.name,
            'category': 'Jasa Servis',
            'price': j.price,
            'isService': true,
            'subInfo': j.category ?? 'Layanan Servis',
            'stock': null,
          }).toList()
        : defaultServices;

    final sparepartItems = spareparts.isNotEmpty
        ? spareparts.map((s) => {
            'name': s.name,
            'category': s.category,
            'price': s.sellPrice,
            'isService': false,
            'subInfo': 'Stok: ${s.stock} ${s.unit}',
            'stock': s.stock,
          }).toList()
        : defaultSpareparts;

    final historyItems = [...jasaItems, ...sparepartItems];

    final availableCategories = <String>['Semua', 'Jasa Servis'];
    for (final s in sparepartItems) {
      final cat = (s['category'] as String?)?.trim() ?? '';
      if (cat.isNotEmpty && !availableCategories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        availableCategories.add(cat);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = historyItems.where((h) {
            final cat = h['category'] as String;
            final name = (h['name'] as String).toLowerCase();
            final matchesCat = selectedCategory == 'Semua' ||
                cat.toLowerCase() == selectedCategory.toLowerCase();
            final matchesSearch = searchQuery.isEmpty ||
                name.contains(searchQuery.toLowerCase());
            return matchesCat && matchesSearch;
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
                      'Pilih Layanan / Item dari Katalog',
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
                        '${filtered.length} Item',
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

                // Search Bar dalam Katalog
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
                      hintText: 'Cari layanan servis atau sparepart...',
                      hintStyle: TextStyle(color: textDim, fontSize: 11),
                      prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bubble filter kategori
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = availableCategories[index];
                      final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accentRed : const Color(0xFF10131B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? accentRed : cardBorder,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? textWhite : textMuted,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Daftar Item Hasil Filter
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Item tidak ditemukan di katalog',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddItemDialog();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Text(
                                '+ Input Manual Item Ini',
                                style: TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.bold),
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
                        final name = item['name'] as String;
                        final category = item['category'] as String;
                        final subInfo = item['subInfo'] as String;
                        final price = item['price'] as int;
                        final isService = item['isService'] as bool;
                        final stock = item['stock'] as int?;

                        return InkWell(
                          onTap: () {
                            _addItemToTransaction(
                              name: name,
                              category: category,
                              subInfo: subInfo,
                              price: price,
                              isService: isService,
                            );
                            setState(() {
                              _selectedCatalogItem = TransaksiItemModel(
                                id: '',
                                name: name,
                                category: category,
                                subInfo: subInfo,
                                price: price,
                                isService: isService,
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
                                    Expanded(child: Text('"$name" ditambahkan ke transaksi!')),
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
                                Icon(
                                  isService ? Icons.build_rounded : Icons.token_rounded,
                                  color: isService ? accentOrange : accentBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$category • $subInfo',
                                        style: const TextStyle(color: textDim, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isService && stock != null && stock <= 0)
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
                                  _formatRupiah(price),
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

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool isJasa = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: const Text(
            'Tambah Item Transaksi',
            style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Jasa Servis')),
                      selected: isJasa,
                      selectedColor: accentRed,
                      backgroundColor: bgDark,
                      labelStyle: TextStyle(
                        color: isJasa ? textWhite : textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDialogState(() => isJasa = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Sparepart')),
                      selected: !isJasa,
                      selectedColor: accentRed,
                      backgroundColor: bgDark,
                      labelStyle: TextStyle(
                        color: !isJasa ? textWhite : textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setDialogState(() => isJasa = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Pilihan Cepat dari Katalog Firestore
              Builder(
                builder: (context) {
                  final services = JasaService().services;
                  final parts = SparepartService().spareparts;
                  final suggestions = isJasa
                      ? services.map((s) => {'name': s.name, 'price': s.price}).toList()
                      : parts.map((p) => {'name': p.name, 'price': p.sellPrice}).toList();

                  if (suggestions.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih Cepat dari Katalog:', style: TextStyle(color: textDim, fontSize: 10)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestions.length.clamp(0, 6),
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final sug = suggestions[idx];
                            final sName = sug['name'] as String;
                            final sPrice = sug['price'] as int;
                            return ActionChip(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: bgDark,
                              side: const BorderSide(color: cardBorder),
                              label: Text(
                                sName,
                                style: const TextStyle(color: textMuted, fontSize: 10),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  nameCtrl.text = sName;
                                  priceCtrl.text = sPrice.toString();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
              Text(isJasa ? 'Nama Jasa Servis' : 'Nama Sparepart',
                  style: const TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDecoration(
                    isJasa ? 'Contoh: Bersihkan Injektor' : 'Contoh: Kampas Rem Depan'),
              ),
              const SizedBox(height: 12),
              const Text('Harga / Tarif (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: _buildInputDecoration('Contoh: 35000', prefix: 'Rp '),
              ),
            ],
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
                final name = nameCtrl.text.trim();
                final price = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  _addItemToTransaction(
                    name: name,
                    category: isJasa ? 'Jasa Servis' : 'Sparepart',
                    subInfo: isJasa ? 'Ongkos Mekanik' : 'Stok Baru',
                    price: price,
                    isService: isJasa,
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
                          Expanded(child: Text('"$name" ditambahkan ke transaksi!')),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: const Text('Tambahkan', style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(TransaksiItemModel item) {
    final priceCtrl = TextEditingController(text: item.price.toString());
    int qty = item.quantity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cardBorder),
          ),
          title: Text(
            'Edit ${item.name}',
            style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Harga Satuan (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: _buildInputDecoration('', prefix: 'Rp '),
              ),
              const SizedBox(height: 14),
              const Text('Jumlah (Qty)', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (qty > 1) setDialogState(() => qty--);
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: textDim),
                  ),
                  Text('$qty', style: const TextStyle(color: textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setDialogState(() => qty++),
                    icon: const Icon(Icons.add_circle_outline, color: accentRed),
                  ),
                ],
              ),
            ],
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
                final p = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.price;
                setState(() {
                  item.price = p;
                  item.quantity = qty;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(color: textWhite)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProcessPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Daftar item transaksi masih kosong!'),
        ),
      );
      return;
    }

    if (_paymentMethod == 'Tunai' && _tunaiDiterima < _totalBayar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3B1517),
          content: Text(
            'Uang tunai diterima (${_formatRupiah(_tunaiDiterima)}) kurang dari total pembayaran (${_formatRupiah(_totalBayar)})!',
          ),
        ),
      );
      return;
    }

    final kasirName = widget.userData?['nama_lengkap'] ?? 'Sri Ekowati';

    // Buat model transaksi lengkap
    final newTransaction = TransaksiPenjualanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _trxCode,
      dateTime: DateTime.now(),
      customerName: _customerName,
      vehicleInfo: _vehicleInfo,
      policeNumber: _policeNumber,
      customerPhone: _customerPhone,
      kasirName: kasirName,
      items: List.from(_items),
      totalBayar: _totalBayar,
      paymentMethod: _paymentMethod,
      tunaiDiterima: _tunaiDiterima,
      kembalian: _kembalian,
      status: 'Lunas',
    );

    // Simpan ke TransaksiService (Cloud Firestore + Local state)
    final savedTrx = await TransaksiService().saveTransaksi(newTransaction);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotaPembayaranPage(
          transaksi: savedTrx,
          userData: widget.userData,
        ),
      ),
    );
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
    final kasirName = widget.userData?['nama_lengkap'] ?? 'Sri Ekowati';

    return AnimatedBuilder(
      animation: Listenable.merge([
        JasaService().servicesNotifier,
        SparepartService().sparepartsNotifier,
        SparepartService().categoriesNotifier,
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
                  // 1. Header (Tombol Kembali, Judul, No TRX & Kasir)
                  _buildHeader(kasirName),
                  const SizedBox(height: 16),

                  // 2. Card Data Pelanggan & Motor
                  _buildDataPelangganCard(),
                  const SizedBox(height: 16),

                  // 3. Tab Jasa Servis / Sparepart & Pilih Dari History
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

                  // Daftar Item Cards
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
                        children: [
                          const Icon(Icons.remove_shopping_cart_outlined, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada item ditambahkan',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showPickFromHistorySheet(initialCategory: _selectedCatalogType),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A24),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Text(
                                '+ Pilih dari Katalog',
                                style: TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildItemCard(item),
                        )),

                  // Tombol Tambah Item Transaksi Lainnya
                  GestureDetector(
                    onTap: _showAddItemDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11141E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          '+ Tambah Item Transaksi Lainnya',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Card Summary & Metode Pembayaran
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // 6. Tombol Besar Proses Pembayaran
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
        Column(
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
      ],
    );
  }

  Widget _buildDataPelangganCard() {
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
                  _customerName,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_vehicleInfo ($_policeNumber) • $_customerPhone',
                  style: const TextStyle(
                    color: textMuted,
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

  Widget _buildServiceSelectorSection() {
    return Column(
      children: [
        // Tab Segmented (Jasa Servis & Sparepart)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCatalogType = 'Jasa Servis';
                    _selectedCatalogItem = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _selectedCatalogType == 'Jasa Servis' ? accentRed : const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCatalogType == 'Jasa Servis' ? accentRed : cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_rounded,
                          size: 14,
                          color: _selectedCatalogType == 'Jasa Servis' ? textWhite : textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Jasa Servis',
                          style: TextStyle(
                            color: _selectedCatalogType == 'Jasa Servis' ? textWhite : textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCatalogType = 'Sparepart';
                    _selectedCatalogItem = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _selectedCatalogType == 'Sparepart' ? accentRed : const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCatalogType == 'Sparepart' ? accentRed : cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.token_rounded,
                          size: 14,
                          color: _selectedCatalogType == 'Sparepart' ? textWhite : textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sparepart',
                          style: TextStyle(
                            color: _selectedCatalogType == 'Sparepart' ? textWhite : textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Baris "Pilih dari history / katalog" & Tombol "+ Tambah"
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showPickFromHistorySheet(initialCategory: _selectedCatalogType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedCatalogItem != null
                            ? (_selectedCatalogItem!.isService ? Icons.build_rounded : Icons.token_rounded)
                            : Icons.search_rounded,
                        color: _selectedCatalogItem != null
                            ? (_selectedCatalogItem!.isService ? accentOrange : accentBlue)
                            : textDim,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCatalogItem != null
                              ? '${_selectedCatalogItem!.name} (${_formatRupiah(_selectedCatalogItem!.price)})'
                              : 'Pilih dari history / katalog ($_selectedCatalogType)',
                          style: TextStyle(
                            color: _selectedCatalogItem != null ? textWhite : textMuted,
                            fontSize: 11.5,
                            fontWeight: _selectedCatalogItem != null ? FontWeight.bold : FontWeight.w500,
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
              onTap: _handleTambahButton,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
        ),
      ],
    );
  }

  Widget _buildItemCard(TransaksiItemModel item) {
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
                  '${item.category} • ${item.subInfo} • ${item.quantity}x',
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
                    // Tombol Kontrol Qty Langsung (-)
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
                    // Tombol Kontrol Qty Langsung (+)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item.quantity++;
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
                          child: Icon(Icons.add, color: textWhite, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Edit
          GestureDetector(
            onTap: () => _showEditItemDialog(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF142033),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A8A), width: 1),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

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

          if (_paymentMethod == 'Tunai') ...[
            const SizedBox(height: 14),
            const Text(
              'Uang Tunai Diterima',
              style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cashReceivedController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: _buildInputDecoration('Nominal tunai', prefix: 'Rp '),
            ),
            const SizedBox(height: 8),
            // Quick Amount Buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickCashPill('Uang Pas', _totalBayar),
                _buildQuickCashPill('50rb', 50000),
                _buildQuickCashPill('100rb', 100000),
                _buildQuickCashPill('200rb', 200000),
                _buildQuickCashPill('500rb', 500000),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian', style: TextStyle(color: textMuted, fontSize: 11)),
                  Text(
                    _tunaiDiterima >= _totalBayar
                        ? _formatRupiah(_kembalian)
                        : 'Kurang ${_formatRupiah(_totalBayar - _tunaiDiterima)}',
                    style: TextStyle(
                      color: _tunaiDiterima >= _totalBayar ? accentGreen : accentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E3A8A)),
              ),
              child: Row(
                children: const [
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

  Widget _buildQuickCashPill(String label, int amount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cashReceivedController.text = amount.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF101420),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
