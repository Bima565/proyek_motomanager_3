import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/barang_service.dart';

class TambahBarangPage extends StatefulWidget {
  const TambahBarangPage({super.key});

  @override
  State<TambahBarangPage> createState() => _TambahBarangPageState();
}

class _TambahBarangPageState extends State<TambahBarangPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final categories = BarangService().categoriesNotifier.value;
    if (categories.isNotEmpty) {
      _categoryController.text = categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final buyPrice = int.tryParse(
            _buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final sellPrice = int.tryParse(
            _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      final now = DateTime.now();
      final dateStr =
          'Diedit ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}';

      final newBarang = BarangModel(
        id: 'brg-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: category,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: 0,
        unit: 'Pcs',
        lastUpdated: dateStr,
      );

      // Simpan riwayat kategori terbaru (maksimal 5, riwayat lama ke-6 otomatis dihapus)
      await BarangService().addCategoryHistory(category);

      // Simpan data barang ke Firestore
      await BarangService().saveBarang(newBarang);

      if (mounted) {
        Navigator.pop(context, newBarang);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Tombol Kembali, Judul, Subjudul)
                Row(
                  children: [
                    const BackButtonCircle(),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tambah Barang',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Input data & stok barang baru',
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
                const SizedBox(height: 24),

                // 2. Container Form Card Utama
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Nama Barang
                      const Text(
                        'Nama Barang',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: textWhite, fontSize: 13),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nama barang wajib diisi'
                            : null,
                        decoration: _buildInputDecoration('Nama barang'),
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Kategori (Satu Textbox terpadu dengan Dropdown 5 Riwayat)
                      const Text(
                        'Kategori Barang',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: BarangService().categoriesNotifier,
                        builder: (context, categories, _) {
                          final recent5 = categories.take(5).toList();

                          return TextFormField(
                            controller: _categoryController,
                            style: const TextStyle(
                              color: textWhite,
                              fontSize: 13,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Kategori barang wajib diisi'
                                    : null,
                            decoration: InputDecoration(
                              hintText: 'Ketik atau pilih riwayat kategori...',
                              hintStyle: const TextStyle(
                                color: textDim,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: bgDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: accentRed),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              suffixIcon: recent5.isEmpty
                                  ? null
                                  : PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: textMuted,
                                        size: 22,
                                      ),
                                      color: cardBg,
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: cardBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      tooltip:
                                          'Pilih dari 5 riwayat kategori',
                                      onSelected: (cat) {
                                        setState(() {
                                          _categoryController.text = cat;
                                        });
                                      },
                                      itemBuilder: (context) {
                                        return [
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 28,
                                            child: Text(
                                              'RIWAYAT KATEGORI TERAKHIR',
                                              style: TextStyle(
                                                color: textDim,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const PopupMenuDivider(height: 1),
                                          ...recent5.map(
                                            (cat) => PopupMenuItem<String>(
                                              value: cat,
                                              height: 38,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.history_rounded,
                                                    color: textDim,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    cat,
                                                    style: const TextStyle(
                                                      color: textWhite,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field 3: Harga Beli
                      const Text(
                        'Harga Beli',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _buyPriceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: textWhite, fontSize: 13),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga beli wajib diisi';
                          }
                          final parsed = int.tryParse(
                            val.replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Harga beli harus lebih dari 0';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.isNotEmpty) {
                            final formatted = formatRibuan(int.parse(clean));
                            if (formatted != val) {
                              _buyPriceController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          }
                        },
                        decoration: _buildInputDecoration(
                          '0',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Field 4: Harga Jual
                      const Text(
                        'Harga Jual',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sellPriceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: textWhite, fontSize: 13),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga jual wajib diisi';
                          }
                          final parsed = int.tryParse(
                            val.replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Harga jual harus lebih dari 0';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.isNotEmpty) {
                            final formatted = formatRibuan(int.parse(clean));
                            if (formatted != val) {
                              _sellPriceController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          }
                        },
                        decoration: _buildInputDecoration(
                          '0',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Info text
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: textDim,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Stok awal otomatis bernilai 0 Pcs. Silakan lakukan Pengadaan & Restock untuk menambah jumlah stok fisik.',
                              style: TextStyle(color: textDim, fontSize: 10.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Tombol Simpan Barang
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      foregroundColor: textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: textWhite,
                            ),
                          )
                        : const Text(
                            'Simpan Barang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: textWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// Backward compatibility alias
typedef TambahSparepartPage = TambahBarangPage;
