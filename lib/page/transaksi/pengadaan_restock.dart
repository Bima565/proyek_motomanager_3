import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/custom_calendar_dialog.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/pembelian_service.dart';
import '../../services/sparepart_service.dart';

export '../../services/pembelian_service.dart' show RestockItemModel, PembelianRecord;

/// Screen 14 - (FR10) Pengadaan & Restock Stok Baru
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
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  // Koleksi Sparepart untuk dipilih di Dropdown Restock (Terkoneksi langsung ke Firestore SparepartService)
  List<Map<String, dynamic>> get _sparepartCatalog {
    final liveSpareparts = SparepartService().spareparts;
    return liveSpareparts.map((s) => {
      'name': s.name,
      'category': s.category,
      'buyPrice': s.buyPrice,
      'unit': s.unit.toLowerCase(),
    }).toList();
  }

  String? _selectedSparepart;
  String _currentCategory = '-';
  int _currentBuyPrice = 0;
  String _currentUnit = 'pcs';
  int _currentQty = 1;

  final TextEditingController _priceController = TextEditingController();

  // Pemasok / Supplier
  final List<String> _supplierList = [
    'Toko Sumber Jaya',
    'PT Astra Motor Parts',
    'Distributor Ban FDR',
    'PT Yamalube Indonesia',
    'Grosir Jaya Part',
    'Lainnya (Ketik Manual)',
  ];
  String _selectedSupplier = 'Toko Sumber Jaya';
  final TextEditingController _customSupplierController = TextEditingController();

  // Tanggal Pembelian
  DateTime _selectedDate = DateTime.now();

  // Daftar Pasokan Restock (Keranjang Restock)
  final List<RestockItemModel> _restockList = [];

  @override
  void initState() {
    super.initState();
    if (_sparepartCatalog.isNotEmpty) {
      final first = _sparepartCatalog.first;
      _selectedSparepart = first['name'] as String;
      _currentCategory = first['category'] as String;
      _currentBuyPrice = first['buyPrice'] as int;
      _currentUnit = first['unit'] as String;
      _priceController.text = _currentBuyPrice.toString();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _customSupplierController.dispose();
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

  void _onSelectSparepart(String name) {
    final matches = _sparepartCatalog.where((e) => e['name'] == name);
    if (matches.isEmpty) return;
    final item = matches.first;
    setState(() {
      _selectedSparepart = name;
      _currentCategory = item['category'] as String;
      _currentBuyPrice = item['buyPrice'] as int;
      _currentUnit = item['unit'] as String;
      _priceController.text = _currentBuyPrice.toString();
    });
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

  void _addItemToRestockList() {
    final selected = _selectedSparepart;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Pilih sparepart terlebih dahulu!'),
        ),
      );
      return;
    }

    final priceParsed = int.tryParse(
          _priceController.text.replaceAll('.', '').trim(),
        ) ??
        _currentBuyPrice;

    setState(() {
      _restockList.add(
        RestockItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: selected,
          category: _currentCategory,
          buyPrice: priceParsed,
          quantity: _currentQty,
          unit: _currentUnit,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF143322),
        content: Text('$selected ($_currentQty $_currentUnit) masuk ke daftar restock!'),
      ),
    );
  }

  void _handleSaveRestock() async {
    if (_restockList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3B1517),
          content: Text('Daftar pasokan restock masih kosong!'),
        ),
      );
      return;
    }

    final buyer = widget.userData?['nama_lengkap'] ?? 'Sugeng Yulianto';
    final supplierName = _selectedSupplier == 'Lainnya (Ketik Manual)'
        ? (_customSupplierController.text.trim().isEmpty
            ? 'Supplier Umum'
            : _customSupplierController.text.trim())
        : _selectedSupplier;

    final newPembelian = PembelianRecord(
      code: PembelianService().generateBeliCode(),
      dateTime: _selectedDate,
      buyerName: buyer,
      supplier: supplierName,
      items: List.from(_restockList),
      totalAmount: _totalModal,
      status: 'LUNAS',
    );

    await PembelianService().savePembelian(newPembelian);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          content: Text('Pengadaan ${newPembelian.code} berhasil disimpan!'),
        ),
      );
      Navigator.pop(context, newPembelian);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyer = widget.userData?['nama_lengkap'] ?? 'Sugeng Yulianto';

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Tombol Kembali, Judul, Subtitle)
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
                        'Restock Stok',
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
              const SizedBox(height: 20),

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
                          'Penanggung Jawab (Pembeli)',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          buyer,
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 14,
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
                              style: TextStyle(color: textMuted, fontSize: 10),
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
                                    fontSize: 12.5,
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
              const SizedBox(height: 14),

              // 2b. Card Pilih Supplier / Pemasok
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
                    const Text(
                      'Pemasok / Toko Supplier',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSupplier,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: textDim,
                          ),
                          items: _supplierList.map((sup) {
                            return DropdownMenuItem<String>(
                              value: sup,
                              child: Text(
                                sup,
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 12.5,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSupplier = val);
                          },
                        ),
                      ),
                    ),
                    if (_selectedSupplier == 'Lainnya (Ketik Manual)') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: TextField(
                          controller: _customSupplierController,
                          style: const TextStyle(color: textWhite, fontSize: 12.5),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama supplier...',
                            hintStyle: TextStyle(color: textDim, fontSize: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Card Input Barang/Item
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
                    const Text(
                      'Input barang/item',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pilih Sparepart
                    const Text(
                      'Pilih Sparepart (Koleksi barang)',
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (_sparepartCatalog.any((i) => i['name'] == _selectedSparepart))
                              ? _selectedSparepart
                              : null,
                          hint: const Text(
                            'Pilih sparepart',
                            style: TextStyle(color: textDim, fontSize: 12),
                          ),
                          isExpanded: true,
                          dropdownColor: cardBg,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: textDim,
                          ),
                          items: _sparepartCatalog.map((item) {
                            final name = item['name'] as String;
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 12.5,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _onSelectSparepart(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row Kategori & Harga Modal Beli (Rp)
                    Row(
                      children: [
                        // Kategori (Read-only box)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kategori',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  _currentCategory,
                                  style: const TextStyle(
                                    color: textWhite,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Harga Modal Beli
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga Modal Beli (Rp)',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
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
                                      style: TextStyle(
                                        color: accentGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _priceController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: accentGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onChanged: (val) {
                                          final p = int.tryParse(val.replaceAll('.', '').trim());
                                          if (p != null) setState(() => _currentBuyPrice = p);
                                        },
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
                    const SizedBox(height: 14),

                    // Row Jumlah Restock (Qty) & Subtotal Modal
                    Row(
                      children: [
                        // Counter Qty Restock (Pengisian Pcs)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jumlah Restock (Qty)',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '−',
                                            style: TextStyle(
                                              color: textWhite,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$_currentQty $_currentUnit',
                                      style: const TextStyle(
                                        color: textWhite,
                                        fontSize: 13,
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
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '+',
                                            style: TextStyle(
                                              color: textWhite,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Subtotal Modal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subtotal Modal',
                                style: TextStyle(color: textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Text(
                                  _formatRupiah(_currentBuyPrice * _currentQty),
                                  style: const TextStyle(
                                    color: accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol + Tambah ke Daftar Item
                    GestureDetector(
                      onTap: _addItemToRestockList,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF221115),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF5A1E24)),
                        ),
                        child: const Center(
                          child: Text(
                            '+ Tambah ke Daftar Item',
                            style: TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Daftar Pasokan Restock (List Card)
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
                    Text(
                      'Daftar Pasokan Restock (${_restockList.length} Item)',
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_restockList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Belum ada item ditambahkan ke pasokan',
                            style: TextStyle(color: textDim, fontSize: 11),
                          ),
                        ),
                      )
                    else
                      ..._restockList.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: textWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.quantity} ${item.unit} × ${_formatRupiah(item.buyPrice)} • ${item.category}',
                                      style: const TextStyle(
                                        color: textMuted,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRupiah(item.subtotal),
                                style: const TextStyle(
                                  color: accentGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _restockList.remove(item));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Text(
                                    '✕',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Total Modal Pembelian & Tombol SIMPAN PEMBELIAN & RESTOCK
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Modal Pembelian',
                              style: TextStyle(color: textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(_totalModal),
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '($_totalItemCount item)',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol SIMPAN PEMBELIAN & RESTOCK (Merah Solid)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _handleSaveRestock,
                        child: const Text(
                          'SIMPAN PEMBELIAN & RESTOCK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
