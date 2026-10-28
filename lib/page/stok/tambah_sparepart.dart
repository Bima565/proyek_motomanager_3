import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import 'data_sparepart.dart';

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
  final TextEditingController _nameController =
      TextEditingController(text: 'Oli Yamalube Silver 0.8L');
  final TextEditingController _buyPriceController =
      TextEditingController(text: '35000');
  final TextEditingController _sellPriceController =
      TextEditingController(text: '45000');

  String _selectedCategory = 'Oli & Pelumas Mesin';

  final List<String> _categoryOptions = [
    'Oli & Pelumas Mesin',
    'Pengereman',
    'Kelistrikan',
    'Ban & Roda',
    'Transmisi CVT',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final buyPrice = int.tryParse(_buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final sellPrice = int.tryParse(_sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final now = DateTime.now();
      final dateStr = 'Diedit ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}';

      final newSparepart = SparepartModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: _selectedCategory.replaceAll(' Mesin', ''),
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: 0,
        unit: 'Pcs',
        lastUpdated: dateStr,
      );

      Navigator.pop(context, newSparepart);
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
                        validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                        decoration: _buildInputDecoration('Nama sparepart'),
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Kategori Dropdown
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: cardBg,
                        style: const TextStyle(color: textWhite, fontSize: 13),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textDim),
                        decoration: _buildInputDecoration('Pilih kategori'),
                        items: _categoryOptions.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
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
                        decoration: _buildInputDecoration('Rp 0', prefix: 'Rp '),
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
                        decoration: _buildInputDecoration('Rp 0', prefix: 'Rp '),
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
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      foregroundColor: textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
                    onPressed: () => Navigator.pop(context),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
