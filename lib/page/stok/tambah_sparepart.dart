import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../services/sparepart_service.dart';

class TambahSparepartPage extends StatefulWidget {
  const TambahSparepartPage({super.key});

  @override
  State<TambahSparepartPage> createState() => _TambahSparepartPageState();
}

class _TambahSparepartPageState extends State<TambahSparepartPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
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
    final categories = SparepartService().categoriesNotifier.value;
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

      final newSparepart = SparepartModel(
        id: 'sp-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: category,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: 0,
        unit: 'Pcs',
        lastUpdated: dateStr,
      );

      // Simpan riwayat kategori terbaru (maksimal 5, riwayat lama ke-6 otomatis dihapus)
      await SparepartService().addCategoryHistory(category);

      // Simpan data sparepart ke Firestore
      await SparepartService().saveSparepart(newSparepart);

      if (mounted) {
        Navigator.pop(context, newSparepart);
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
                          'Tambah Sparepart',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Input data & stok sparepart baru',
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
                      // Field 1: Nama Sparepart
                      const Text(
                        'Nama Sparepart',
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
                            ? 'Nama wajib diisi'
                            : null,
                        decoration: _buildInputDecoration('Nama sparepart'),
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Kategori (Satu Textbox terpadu dengan Dropdown 5 Riwayat)
                      const Text(
                        'Kategori Sparepart',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<String>>(
                        valueListenable:
                            SparepartService().categoriesNotifier,
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
                                    ? 'Kategori sparepart wajib diisi'
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
                                              '5 RIWAYAT TERBARU',
                                              style: TextStyle(
                                                color: textDim,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const PopupMenuDivider(height: 1),
                                          ...recent5.map(
                                            (cat) {
                                              final isSelected =
                                                  _categoryController.text
                                                          .trim()
                                                          .toLowerCase() ==
                                                      cat.toLowerCase();
                                              return PopupMenuItem<String>(
                                                value: cat,
                                                height: 40,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.history_rounded,
                                                      color: isSelected
                                                          ? const Color(0xFF60A5FA)
                                                          : textDim,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        cat,
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? const Color(
                                                                  0xFF60A5FA)
                                                              : textWhite,
                                                          fontSize: 12.5,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(
                                                        Icons.check_rounded,
                                                        color:
                                                            Color(0xFF60A5FA),
                                                        size: 16,
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ];
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '*Ketik kategori baru atau tekan tombol panah di ujung untuk memilih riwayat',
                        style: TextStyle(
                          color: textDim,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Field 3: Harga beli
                      const Text(
                        'Harga beli',
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
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration:
                            _buildInputDecoration('Rp 0', prefix: 'Rp '),
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
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration:
                            _buildInputDecoration('Rp 0', prefix: 'Rp '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Tombol Simpan Sparepart
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      foregroundColor: textWhite,
                      disabledBackgroundColor: accentRed.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: textWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan Sparepart',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Tombol Batal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cardBg,
                      side: const BorderSide(color: cardBorder, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint, {
    String? prefix,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon: prefixIcon,
      prefixStyle:
          const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
