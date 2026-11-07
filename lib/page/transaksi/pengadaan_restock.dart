import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/custom_calendar_dialog.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/pembelian_service.dart';
import '../../services/sparepart_service.dart';

export '../../services/pembelian_service.dart' show RestockItemModel, PembelianRecord;

/// Screen 14 - (FR10) Pengadaan & Restock Barang
class PengadaanRestockPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PengadaanRestockPage({super.key, this.userData});

  @override
  State<PengadaanRestockPage> createState() => _PengadaanRestockPageState();
}

class _PengadaanRestockPageState extends State<PengadaanRestockPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color inputBg = Color(0xFF0A0C10);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  // Input Manual Toko Pembelian (Tidak ada supplier tetap)
  final TextEditingController _tokoController = TextEditingController();

  // Tanggal Pembelian
  DateTime _selectedDate = DateTime.now();

  // Mode Input Barang: 0 = Pilih dari Stok Master Data, 1 = Input Barang Baru
  int _inputMode = 0;

  // Barang Terpilih dari Master Data (jika mode 0)
  SparepartModel? _selectedExistingItem;

  // Controller Form Barang
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: 'Pcs');
  int _currentQty = 1;

  // Daftar Pasokan Restock (Keranjang Pembelian)
  final List<RestockItemModel> _restockList = [];

  @override
  void dispose() {
    _tokoController.dispose();
    _namaBarangController.dispose();
    _kategoriController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  String _formatDateDisplay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int get _totalModal =>
      _restockList.fold(0, (sum, item) => sum + item.subtotal);

  int get _totalItemCount =>
      _restockList.fold(0, (sum, item) => sum + item.quantity);

  int _parseNominal(String text) {
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await CustomCalendarDialog.show(
      context,
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Pilih Barang dari Master Data
  void _selectItemFromMaster(SparepartModel item) {
    setState(() {
      _inputMode = 0;
      _selectedExistingItem = item;
      _namaBarangController.text = item.name;
      _kategoriController.text = item.category;
      _buyPriceController.text = item.buyPrice.toString();
      _sellPriceController.text = item.sellPrice.toString();
      _unitController.text = item.unit.isNotEmpty ? item.unit : 'Pcs';
      _currentQty = 1;
    });
  }

  // Beralih ke Mode Input Barang Baru
  void _switchToNewItemMode({String? initialName}) {
    setState(() {
      _inputMode = 1;
      _selectedExistingItem = null;
      _namaBarangController.text = initialName ?? '';
      _kategoriController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _unitController.text = 'Pcs';
      _currentQty = 1;
    });
  }

  // Buka Modal Sheet Pencarian Barang dari Master Data
  void _showPickMasterItemSheet() {
    String searchQuery = '';
    final masterList = SparepartService().spareparts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = masterList.where((p) {
            final q = searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q);
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
                      'Pilih Barang dari Master Data',
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
                      hintText: 'Cari nama atau kategori barang...',
                      hintStyle: TextStyle(color: textDim, fontSize: 11),
                      prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Shortcut: Buat Barang Baru (jika barang belum ada di master)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _switchToNewItemMode(initialName: searchQuery);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E3A8A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, color: accentBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            searchQuery.isNotEmpty
                                ? '+ Tambah Barang Baru: "$searchQuery"'
                                : '+ Tambah Barang Baru (Belum Terdaftar di Master Data)',
                            style: const TextStyle(
                              color: accentBlue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: textDim, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Barang "$searchQuery" belum ada di data stok.'
                                : 'Master data stok masih kosong.',
                            style: const TextStyle(color: textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gunakan tombol di atas untuk menambahkan barang baru.',
                            style: TextStyle(color: textDim, fontSize: 11),
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

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _selectItemFromMaster(item);
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
                                      const SizedBox(height: 2),
                                      Text(
                                        'Beli: ${_formatRupiah(item.buyPrice)} • Jual: ${_formatRupiah(item.sellPrice)}',
                                        style: const TextStyle(color: textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: textDim, size: 18),
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

  // Tambahkan Item ke Daftar Pasokan Restock
  void _addItemToRestockList() {
    final name = _namaBarangController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Pilih barang dari stok atau ketik nama barang terlebih dahulu!'),
        ),
      );
      return;
    }

    final buyPrice = _parseNominal(_buyPriceController.text);
    if (buyPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Harga modal beli harus lebih dari Rp 0!'),
        ),
      );
      return;
    }

    int sellPrice = _parseNominal(_sellPriceController.text);
    if (sellPrice <= 0) {
      // Rekomendasi margin default 25% jika tidak diisi
      sellPrice = (buyPrice * 1.25).round();
    }

    final category = _kategoriController.text.trim().isNotEmpty
        ? _kategoriController.text.trim()
        : 'Lainnya';
    final unit = _unitController.text.trim().isNotEmpty
        ? _unitController.text.trim()
        : 'Pcs';

    setState(() {
      _restockList.add(
        RestockItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: category,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          quantity: _currentQty,
          unit: unit,
        ),
      );

      // Reset form input item
      _selectedExistingItem = null;
      _namaBarangController.clear();
      _kategoriController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _currentQty = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF143322),
        duration: const Duration(seconds: 1),
        content: Text('Barang "$name" ($category) masuk ke daftar pasokan!'),
      ),
    );
  }

  // Dialog Edit Item di Daftar Pasokan
  void _showEditRestockItemDialog(RestockItemModel item) {
    final buyCtrl = TextEditingController(text: item.buyPrice.toString());
    final sellCtrl = TextEditingController(text: item.sellPrice.toString());
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
            'Edit: ${item.name}',
            style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Harga Modal Beli (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    controller: buyCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Harga Jual Toko (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    controller: sellCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: accentBlue, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Jumlah Restock (Qty)', style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (qty > 1) setDialogState(() => qty--);
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: textDim),
                    ),
                    Text('$qty ${item.unit}', style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => setDialogState(() => qty++),
                      icon: const Icon(Icons.add_circle_outline, color: accentGreen),
                    ),
                  ],
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
                backgroundColor: accentGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final b = _parseNominal(buyCtrl.text);
                final s = _parseNominal(sellCtrl.text);
                if (b > 0) {
                  setState(() {
                    item.buyPrice = b;
                    item.sellPrice = s > 0 ? s : (b * 1.25).round();
                    item.quantity = qty;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Simpan Transaksi Pembelian ke Firestore & Perbarui Master Data Stok
  void _handleSaveRestock() async {
    if (_restockList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Daftar pasokan barang restock masih kosong! Tambahkan barang terlebih dahulu.'),
        ),
      );
      return;
    }

    final buyer = widget.userData?['nama_lengkap'] ?? 'Penanggung Jawab';
    final tokoName = _tokoController.text.trim().isNotEmpty
        ? _tokoController.text.trim()
        : 'Toko Pembelian Umum';

    final newPembelian = PembelianRecord(
      code: PembelianService().generateBeliCode(),
      dateTime: _selectedDate,
      buyerName: buyer,
      supplier: tokoName,
      items: List.from(_restockList),
      totalAmount: _totalModal,
      status: 'LUNAS',
    );

    // Simpan ke service: otomatis menambahkan/memperbarui master data barang
    await PembelianService().savePembelian(newPembelian);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          content: Text(
            'Pembelian ${newPembelian.code} dari "$tokoName" berhasil disimpan! Stok & harga barang otomatis masuk ke master data.',
          ),
        ),
      );
      Navigator.pop(context, newPembelian);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyer = widget.userData?['nama_lengkap'] ?? 'Penanggung Jawab';

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Tombol Kembali & Judul)
              Row(
                children: [
                  const BackButtonCircle(),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Pengadaan & Restock',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Restock Barang Toko',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Card Penanggung Jawab & Tanggal Pembelian
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penanggung Jawab',
                          style: TextStyle(color: textMuted, fontSize: 10.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          buyer,
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _pickPurchaseDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tanggal Pembelian',
                              style: TextStyle(color: textMuted, fontSize: 9.5),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: accentGreen, size: 12),
                                const SizedBox(width: 5),
                                Text(
                                  _formatDateDisplay(_selectedDate),
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Card Input Manual Toko Pembelian (Bebas / Manual)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.storefront_rounded, color: accentOrange, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Toko Pembelian (Input Manual)',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: TextField(
                        controller: _tokoController,
                        style: const TextStyle(color: textWhite, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan nama toko pembelian (contoh: Toko Sumber Rejeki)...',
                          hintStyle: TextStyle(color: textDim, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Section Tambah Barang ke Pembelian (Bisa Pilih dari Master Data ATAU Input Manual)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tab Selector Mode: Pilih dari Stok VS Input Barang Baru
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _inputMode = 0);
                              _showPickMasterItemSheet();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _inputMode == 0 ? const Color(0xFF16253B) : inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _inputMode == 0 ? accentBlue : cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: _inputMode == 0 ? accentBlue : textDim,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pilih dari Stok',
                                    style: TextStyle(
                                      color: _inputMode == 0 ? textWhite : textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchToNewItemMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _inputMode == 1 ? const Color(0xFF281116) : inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _inputMode == 1 ? accentRed : cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: _inputMode == 1 ? accentRed : textDim,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+ Barang Baru',
                                    style: TextStyle(
                                      color: _inputMode == 1 ? textWhite : textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector Button jika mode 0 (Pilih dari Master Data)
                    if (_inputMode == 0) ...[
                      GestureDetector(
                        onTap: _showPickMasterItemSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedExistingItem != null ? accentBlue : cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedExistingItem != null
                                    ? Icons.check_circle_rounded
                                    : Icons.search_rounded,
                                color: _selectedExistingItem != null ? accentBlue : textDim,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedExistingItem != null
                                      ? '${_selectedExistingItem!.name} (${_selectedExistingItem!.category})'
                                      : 'Ketuk untuk cari & pilih barang dari master stok...',
                                  style: TextStyle(
                                    color: _selectedExistingItem != null ? textWhite : textMuted,
                                    fontSize: 12,
                                    fontWeight: _selectedExistingItem != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: textDim),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Input Nama Barang (Hanya jika mode barang baru manual)
                    if (_inputMode == 1) ...[
                      const Text('Nama Barang Baru', style: TextStyle(color: textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: TextField(
                          controller: _namaBarangController,
                          style: const TextStyle(color: textWhite, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Kampas Rem Depan Vario 160...',
                            hintStyle: TextStyle(color: textDim, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input Kategori Barang Baru
                      const Text('Kategori Barang', style: TextStyle(color: textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: TextField(
                          controller: _kategoriController,
                          style: const TextStyle(color: textWhite, fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Pengereman, Oli, Ban, Kelistrikan...',
                            hintStyle: TextStyle(color: textDim, fontSize: 11),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Row Pengaturan Harga Beli (Modal) & Harga Jual (Toko)
                    Row(
                      children: [
                        // Harga Beli (Modal)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harga Modal Beli (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Rp ',
                                      style: TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _buyPriceController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(color: textDim, fontSize: 12),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onChanged: (val) {
                                          final b = _parseNominal(val);
                                          // Otomatis rekomendasikan harga jual 25% jika harga jual belum diisi
                                          if (_sellPriceController.text.isEmpty && b > 0) {
                                            _sellPriceController.text = (b * 1.25).round().toString();
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Harga Jual Toko
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harga Jual Toko (Rp)', style: TextStyle(color: textMuted, fontSize: 11)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Rp ',
                                      style: TextStyle(color: accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _sellPriceController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: accentBlue, fontSize: 12, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(color: textDim, fontSize: 12),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row Jumlah Qty & Satuan
                    Row(
                      children: [
                        // Counter Qty
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jumlah Restock (Qty)', style: TextStyle(color: textMuted, fontSize: 11)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_currentQty > 1) {
                                          setState(() => _currentQty--);
                                        }
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.remove, color: textMuted, size: 14),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$_currentQty',
                                      style: const TextStyle(
                                        color: textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _currentQty++);
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.add, color: textWhite, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Satuan
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Satuan', style: TextStyle(color: textMuted, fontSize: 11)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: TextField(
                                  controller: _unitController,
                                  style: const TextStyle(color: textWhite, fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'Pcs',
                                    hintStyle: TextStyle(color: textDim, fontSize: 11),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol Masukkan ke Pasokan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addItemToRestockList,
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text(
                          '+ Masukkan ke Daftar Pasokan',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Section Keranjang Pasokan Restock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Pasokan Restock',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1418),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4C1D24)),
                    ),
                    child: Text(
                      '${_restockList.length} Item • $_totalItemCount Pcs',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_restockList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.inventory_2_outlined, color: textDim, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada barang di daftar pasokan',
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pilih barang dari stok atau input barang baru di atas',
                        style: TextStyle(color: textDim, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _restockList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _restockList[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF142033),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1E3A8A)),
                            ),
                            child: const Center(
                              child: Icon(Icons.token_rounded, color: accentBlue, size: 18),
                            ),
                          ),
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
                                  '${item.category} • Beli: ${_formatRupiah(item.buyPrice)} | Jual: ${_formatRupiah(item.sellPrice)}',
                                  style: const TextStyle(color: textDim, fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} ${item.unit} × ${_formatRupiah(item.buyPrice)} = ${_formatRupiah(item.subtotal)}',
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Edit
                          GestureDetector(
                            onTap: () => _showEditRestockItemDialog(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF142033),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF1E3A8A)),
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
                          // Tombol Hapus
                          GestureDetector(
                            onTap: () {
                              setState(() => _restockList.removeAt(index));
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF281116),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF5A1E24)),
                              ),
                              child: const Center(
                                child: Text('✕', style: TextStyle(color: accentRed, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),

              // 6. Ringkasan Total Modal Pembelian
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Item Pasokan', style: TextStyle(color: textMuted, fontSize: 11)),
                        Text('$_totalItemCount Barang (${_restockList.length} Jenis)', style: const TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: cardBorder),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Modal Pembelian', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          _formatRupiah(_totalModal),
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. Tombol Simpan Transaksi Pembelian Restock
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSaveRestock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    foregroundColor: textWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan Transaksi Restock (${_formatRupiah(_totalModal)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
