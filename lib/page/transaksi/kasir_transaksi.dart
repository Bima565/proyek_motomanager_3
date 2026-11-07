import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/jasa_service.dart';
import '../../services/sparepart_service.dart';
import '../../services/transaksi_service.dart';
import '../stok/tambah_jasa.dart';
import '../stok/tambah_sparepart.dart';
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

  // 1. Data Pelanggan & Motor (Tanpa Dummy - Murni Input Manual)
  String _customerName = '';
  String _vehicleInfo = '';
  String _customerPhone = '';
  late String _trxCode;

  // Metode Pembayaran ('Tunai' atau 'QRIS')
  String _paymentMethod = 'Tunai';

  // Layanan Jasa Terpilih di bar atas
  TransaksiItemModel? _selectedServiceItem;

  // 1 & 7. Daftar Item Transaksi (Mulai Kosong / Tanpa Dummy)
  late List<TransaksiItemModel> _items;

  // 8. Draf Transaksi Tersimpan
  Map<String, dynamic>? _existingDraft;

  @override
  void initState() {
    super.initState();
    _trxCode = TransaksiService().generateTrxCode();
    _items = [];
    _checkExistingDraft();
  }

  Future<void> _checkExistingDraft() async {
    final draft = await TransaksiService().getDraft();
    if (draft != null && mounted) {
      final rawItems = draft['items'] as List<dynamic>? ?? [];
      final hasCustomer = (draft['customerName']?.toString().trim().isNotEmpty ?? false);
      if (rawItems.isNotEmpty || hasCustomer) {
        setState(() {
          _existingDraft = draft;
        });
      }
    }
  }

  void _restoreDraft() {
    if (_existingDraft == null) return;
    setState(() {
      _trxCode = _existingDraft!['code']?.toString() ?? _trxCode;
      _customerName = _existingDraft!['customerName']?.toString() ?? '';
      _vehicleInfo = _existingDraft!['vehicleInfo']?.toString() ?? '';
      _customerPhone = _existingDraft!['customerPhone']?.toString() ?? '';
      _paymentMethod = _existingDraft!['paymentMethod']?.toString() ?? 'Tunai';

      final rawItems = _existingDraft!['items'] as List<dynamic>? ?? [];
      _items = rawItems
          .map((i) => TransaksiItemModel.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList();
      _existingDraft = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF143322),
        content: Text('Draf transaksi berhasil dipulihkan!'),
      ),
    );
  }

  void _discardDraft() async {
    await TransaksiService().clearDraft();
    if (!mounted) return;
    setState(() {
      _existingDraft = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF281116),
        content: Text('Draf transaksi telah dibuang.'),
      ),
    );
  }

  Future<void> _autoSaveDraft() async {
    if (_items.isEmpty && _customerName.isEmpty && _vehicleInfo.isEmpty) return;
    await TransaksiService().saveDraft(
      code: _trxCode,
      customerName: _customerName,
      vehicleInfo: _vehicleInfo,
      customerPhone: _customerPhone,
      items: _items,
      paymentMethod: _paymentMethod,
    );
  }

  // 3. Total Bayar Otomatis dari Checkout Item
  int get _totalBayar =>
      _items.fold(0, (total, item) => total + item.total);

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  // 6. Cek Stok Barang dari SparepartService
  int _getItemStock(String name) {
    final parts = SparepartService().spareparts;
    final match = parts.where(
      (p) => p.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (match.isNotEmpty) {
      return match.first.stock;
    }
    return 0; // Jika barang tidak ditemukan di stok
  }

  // 2. Edit Data Pelanggan & Motor (Tanpa Plat Nomor)
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

  // 6. Tambah Item dengan Validasi Keterikatan Stok Barang
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
              content: Text(
                'Batas stok "$name" tercapai! Stok hanya tersedia $availableStock Pcs.',
              ),
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

  void _handleTambahServiceButton() {
    if (_selectedServiceItem != null) {
      _addItemToTransaction(
        name: _selectedServiceItem!.name,
        category: _selectedServiceItem!.category,
        subInfo: _selectedServiceItem!.subInfo,
        price: _selectedServiceItem!.price,
        isService: true,
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
                child: Text('1x "${_selectedServiceItem!.name}" ditambahkan ke transaksi!'),
              ),
            ],
          ),
        ),
      );
    } else {
      _showPickFromHistorySheet(initialCategory: 'Jasa Servis');
    }
  }

  // 7. Pilih dari Katalog / History: Tampilkan Semua Tanpa Filter Default
  void _showPickFromHistorySheet({String initialCategory = 'Semua'}) {
    String selectedCategory = initialCategory;
    String searchQuery = '';

    final services = JasaService().services;
    final spareparts = SparepartService().spareparts;

    final jasaItems = services.map((j) => {
      'name': j.name,
      'category': 'Jasa Servis',
      'price': j.price,
      'isService': true,
      'subInfo': j.category ?? 'Layanan Servis',
      'stock': null,
    }).toList();

    // 4. Sparepart diganti istilah Barang
    final barangItems = spareparts.map((s) => {
      'name': s.name,
      'category': s.category,
      'price': s.sellPrice,
      'isService': false,
      'subInfo': 'Stok: ${s.stock} ${s.unit}',
      'stock': s.stock,
    }).toList();

    final allCatalogItems = [...jasaItems, ...barangItems];

    final availableCategories = <String>['Semua', 'Jasa Servis', 'Barang'];
    for (final s in barangItems) {
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
          final filtered = allCatalogItems.where((h) {
            final cat = (h['category'] as String).toLowerCase();
            final name = (h['name'] as String).toLowerCase();
            final isService = h['isService'] as bool;

            bool matchesCat = true;
            if (selectedCategory == 'Semua') {
              matchesCat = true;
            } else if (selectedCategory == 'Jasa Servis') {
              matchesCat = isService;
            } else if (selectedCategory == 'Barang') {
              matchesCat = !isService;
            } else {
              matchesCat = cat == selectedCategory.toLowerCase();
            }

            final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery.toLowerCase());
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
                      'Pilih Layanan / Stok Barang',
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

                // Search Bar
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
                      hintText: 'Cari layanan servis atau nama barang...',
                      hintStyle: TextStyle(color: textDim, fontSize: 11),
                      prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bubble filter kategori (Default: Semua)
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Item tidak ditemukan di master data',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TambahSparepartPage()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161A24),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: const Text(
                                    '+ Stok Barang Baru',
                                    style: TextStyle(color: accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TambahJasaPage()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161A24),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: const Text(
                                    '+ Jasa Baru',
                                    style: TextStyle(color: accentOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
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

                        final isOutOfStock = !isService && (stock == null || stock <= 0);

                        return InkWell(
                          onTap: () {
                            if (isOutOfStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF3B1517),
                                  content: Text('Barang "$name" stoknya habis (0 Pcs)! Tidak dapat dipilih.'),
                                ),
                              );
                              return;
                            }

                            _addItemToTransaction(
                              name: name,
                              category: category,
                              subInfo: subInfo,
                              price: price,
                              isService: isService,
                            );

                            if (isService) {
                              setState(() {
                                _selectedServiceItem = TransaksiItemModel(
                                  id: '',
                                  name: name,
                                  category: category,
                                  subInfo: subInfo,
                                  price: price,
                                  isService: true,
                                );
                              });
                            }

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

  // 5. Tambah Item Transaksi Barang Langsung dari Stok Barang
  void _showAddBarangSheet() {
    _showPickFromHistorySheet(initialCategory: 'Barang');
  }

  // 7. Tombol Edit Item Transaksi (Qty terbatas oleh stok barang)
  void _showEditItemDialog(TransaksiItemModel item) {
    final priceCtrl = TextEditingController(text: item.price.toString());
    int qty = item.quantity;
    final maxStock = !item.isService ? _getItemStock(item.name) : 99999;

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
            'Edit Item: ${item.name}',
            style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.isService) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A8A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: accentBlue, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Stok Barang Tersedia: $maxStock Pcs',
                        style: const TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
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
                    onPressed: () {
                      if (!item.isService && qty >= maxStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF3B1517),
                            content: Text('Batas stok barang tercapai ($maxStock Pcs)!'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => qty++);
                    },
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

  // 3 & 6. Proses Pembayaran (Tanpa Kembalian / Kelebihan, Validasi Stok Barang)
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

    // 6. Validasi Stok Barang: cegah checkout jika stok habis atau qty melebihi stok
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
              content: Text(
                'Jumlah "${item.name}" (${item.quantity} pcs) melebihi stok tersedia ($currentStock pcs)!',
              ),
            ),
          );
          return;
        }
      }
    }

    final kasirName = widget.userData?['nama_lengkap'] ?? 'Kasir';

    // 2 & 3. Simpan transaksi (Plat dihapus, Kembalian dihapus, Total murni auto dari items)
    final newTransaction = TransaksiPenjualanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    // Simpan ke TransaksiService (Cloud Firestore + Local state)
    final savedTrx = await TransaksiService().saveTransaksi(newTransaction);

    // 8. Hapus draf transaksi setelah pembayaran sukses
    await TransaksiService().clearDraft();

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
    final kasirName = widget.userData?['nama_lengkap'] ?? 'Kasir';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _autoSaveDraft();
        }
      },
      child: AnimatedBuilder(
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
                    // 1. Header (Tombol Kembali, Judul, Draf Button & Kasir)
                    _buildHeader(kasirName),
                    const SizedBox(height: 16),

                    // 8. Draf Recovery Alert jika ada transaksi tersimpan sebelumnya
                    if (_existingDraft != null) ...[
                      _buildDraftRecoveryBanner(),
                      const SizedBox(height: 16),
                    ],

                    // 2. Card Data Pelanggan & Motor (Tanpa Plat)
                    _buildDataPelangganCard(),
                    const SizedBox(height: 16),

                    // 7. Section Layanan Jasa Servis Saja (Panjang Full Width)
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

                    // Daftar Item Cards (Tanpa Dummy Awal)
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
                            const Icon(Icons.shopping_basket_outlined, color: textDim, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada item ditambahkan',
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _showPickFromHistorySheet(initialCategory: 'Semua'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161A24),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: const Text(
                                  '+ Pilih dari Katalog & Stok',
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

                    // 5 & 7. Tombol Tambah Item Transaksi Barang
                    GestureDetector(
                      onTap: _showAddBarangSheet,
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

                    // 3. Card Summary & Metode Pembayaran (Tanpa Kembalian / Kelebihan)
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
      ),
    );
  }

  Widget _buildHeader(String kasirName) {
    return Row(
      children: [
        BackButtonCircle(
          onTap: () async {
            await _autoSaveDraft();
            if (mounted) Navigator.maybePop(context);
          },
        ),
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
        // 8. Tombol Manual Simpan Draf
        GestureDetector(
          onTap: () async {
            await _autoSaveDraft();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF142C1B),
                  content: Text('Draf transaksi berhasil disimpan!'),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.save_as_outlined, color: textMuted, size: 14),
                SizedBox(width: 4),
                Text(
                  'Draf',
                  style: TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 8. Widget Notifikasi Draf Ditemukan
  Widget _buildDraftRecoveryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBlue.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off_rounded, color: accentBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Draf Transaksi Ditemukan',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Ada transaksi yang belum selesai disimpan sebelumnya.',
                  style: const TextStyle(color: textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _restoreDraft,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _discardDraft,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close_rounded, color: textDim, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // 1 & 2. Card Data Pelanggan (Tanpa Dummy dan Tanpa Plat Nomor)
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

  // 7. Menu Jasa Servis Panjang (Tab Sparepart Dihapus)
  Widget _buildServiceSelectorSection() {
    return Column(
      children: [
        // Bar Panjang Penuh Jasa Servis
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF191D2B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentRed.withValues(alpha: 0.8), width: 1.2),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_rounded, size: 14, color: accentRed),
                SizedBox(width: 8),
                Text(
                  'Layanan Jasa Servis',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Baris "Pilih Jasa Servis" & Tombol "+ Tambah"
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showPickFromHistorySheet(initialCategory: 'Jasa Servis'),
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
              onTap: _handleTambahServiceButton,
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

  // 6 & 7. Card Item Transaksi dengan Pengaitan Stok Barang Real
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
                    // Tombol Kontrol Qty (+) dengan link batas stok
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

          // 7. Tombol Edit
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

  // 3. Card Summary (Hapus Kelebihan, Hapus Kembalian, Hapus Input Manual Tunai)
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
