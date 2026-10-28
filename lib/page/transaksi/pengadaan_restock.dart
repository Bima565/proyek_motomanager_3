import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';

class RestockItemModel {
  String id;
  String name;
  String category;
  int buyPrice;
  int quantity;
  String unit;

  RestockItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.quantity,
    this.unit = 'pcs',
  });

  int get subtotal => buyPrice * quantity;
}

class PembelianRecord {
  final String code;
  final DateTime dateTime;
  final String buyerName;
  final String supplier;
  final List<RestockItemModel> items;
  final int totalAmount;
  final String status; // 'LUNAS'

  PembelianRecord({
    required this.code,
    required this.dateTime,
    required this.buyerName,
    required this.supplier,
    required this.items,
    required this.totalAmount,
    this.status = 'LUNAS',
  });

  String get dateFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    return '$d/$m/$y';
  }

  String get summaryItems {
    return items.map((i) => '${i.quantity}x ${i.name}').join(' + ');
  }
}

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

  // Koleksi Sparepart untuk dipilih di Dropdown Restock
  final List<Map<String, dynamic>> _sparepartCatalog = [
    {
      'name': 'velg jari-jari supra 125',
      'category': 'velg',
      'buyPrice': 90000,
      'unit': 'pcs',
    },
    {
      'name': 'oli mpx2',
      'category': 'oli',
      'buyPrice': 60000,
      'unit': 'pcs',
    },
    {
      'name': 'Oli Yamalube Silver 0.8L',
      'category': 'oli',
      'buyPrice': 35000,
      'unit': 'pcs',
    },
    {
      'name': 'Kampas Rem Depan Vario/Beat',
      'category': 'rem',
      'buyPrice': 40000,
      'unit': 'pcs',
    },
    {
      'name': 'Busi NGK CPR9EA-9',
      'category': 'kelistrikan',
      'buyPrice': 20000,
      'unit': 'pcs',
    },
    {
      'name': 'Ban Luar Tubeless FDR 90/90-14',
      'category': 'ban',
      'buyPrice': 150000,
      'unit': 'pcs',
    },
    {
      'name': 'Roller Set Honda Beat FI (11g)',
      'category': 'cvt',
      'buyPrice': 28000,
      'unit': 'set',
    },
  ];

  late String _selectedSparepart;
  late String _currentCategory;
  late int _currentBuyPrice;
  late String _currentUnit;
  int _currentQty = 10;

  final TextEditingController _priceController = TextEditingController();

  // Daftar Pasokan Restock (Keranjang Restock)
  final List<RestockItemModel> _restockList = [];

  @override
  void initState() {
    super.initState();
    final first = _sparepartCatalog.first;
    _selectedSparepart = first['name'] as String;
    _currentCategory = first['category'] as String;
    _currentBuyPrice = first['buyPrice'] as int;
    _currentUnit = first['unit'] as String;
    _priceController.text = _formatNumber(_currentBuyPrice);

    // Initial dummy data sesuai Penpot Screen 14
    _restockList.add(
      RestockItemModel(
        id: '1',
        name: 'velg jari-jari supra 125',
        category: 'velg',
        buyPrice: 90000,
        quantity: 10,
        unit: 'pcs',
      ),
    );
    _restockList.add(
      RestockItemModel(
        id: '2',
        name: 'oli mpx2',
        category: 'oli',
        buyPrice: 60000,
        quantity: 20,
        unit: 'pcs',
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatNumber(int val) {
    final str = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  int get _totalModal =>
      _restockList.fold(0, (sum, item) => sum + item.subtotal);

  int get _totalItemCount =>
      _restockList.fold(0, (sum, item) => sum + item.quantity);

  void _onSelectSparepart(String name) {
    final item = _sparepartCatalog.firstWhere((e) => e['name'] == name);
    setState(() {
      _selectedSparepart = name;
      _currentCategory = item['category'] as String;
      _currentBuyPrice = item['buyPrice'] as int;
      _currentUnit = item['unit'] as String;
      _priceController.text = _formatNumber(_currentBuyPrice);
    });
  }

  void _addItemToRestockList() {
    final priceParsed = int.tryParse(
          _priceController.text.replaceAll('.', '').trim(),
        ) ??
        _currentBuyPrice;

    setState(() {
      _restockList.add(
        RestockItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _selectedSparepart,
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
        content: Text('$_selectedSparepart ($_currentQty $_currentUnit) masuk ke daftar restock!'),
      ),
    );
  }

  void _handleSaveRestock() {
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
    final newPembelian = PembelianRecord(
      code: '#BELI-00${DateTime.now().second % 90 + 10}',
      dateTime: DateTime.now(),
      buyerName: buyer,
      supplier: 'Toko Sumber Jaya',
      items: List.from(_restockList),
      totalAmount: _totalModal,
      status: 'LUNAS',
    );

    Navigator.pop(context, newPembelian);
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          'Tanggal Pembelian',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '12 Okt 2026',
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

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
                          value: _selectedSparepart,
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
                                  'Rp ${_formatNumber(_currentBuyPrice * _currentQty)}',
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
                                      '${item.quantity} ${item.unit} × Rp ${_formatNumber(item.buyPrice)} • ${item.category}',
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
                                'Rp ${_formatNumber(item.subtotal)}',
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
                              'Rp ${_formatNumber(_totalModal)}',
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
