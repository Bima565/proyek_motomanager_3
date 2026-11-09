import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/moto_bottom_nav.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/barang_service.dart';
import '../beranda.dart';
import 'tambah_barang.dart';

export '../../services/barang_service.dart' show BarangModel;

/// Screen Data Barang & Stok (FR05)
class DataBarangPage extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final Map<String, dynamic>? userData;

  const DataBarangPage({
    super.key,
    this.onNavigateTab,
    this.userData,
  });

  @override
  State<DataBarangPage> createState() => _DataBarangPageState();
}

class _DataBarangPageState extends State<DataBarangPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  void _confirmDeleteBarang(BarangModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: accentRed, size: 22),
            SizedBox(width: 8),
            Text(
              'Hapus Barang',
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus barang "${item.name}"? Data yang dihapus tidak dapat dikembalikan.',
          style: const TextStyle(color: textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await BarangService().deleteBarang(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF3B1517),
                    content: Text('Barang "${item.name}" berhasil dihapus'),
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTambahBarang() async {
    final result = await Navigator.push<BarangModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const TambahBarangPage(),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          content: Text('Barang "${result.name}" berhasil disimpan ke Firestore!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BarangModel>>(
      valueListenable: BarangService().barangsNotifier,
      builder: (context, barangs, _) {
        // Ambil kategori unik HANYA dari barang yang sudah ditambahkan
        final activeCategories = <String>['Semua'];
        for (final item in barangs) {
          final cat = item.category.trim();
          if (cat.isNotEmpty &&
              !activeCategories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
            activeCategories.add(cat);
          }
        }

        // Sinkronisasi kategori terpilih: jika kategori yang dipilih tidak ada di barang, fallback ke 'Semua'
        final effectiveCategory = activeCategories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
            ? _selectedCategory
            : 'Semua';

        final filtered = barangs.where((item) {
          final matchCategory = effectiveCategory == 'Semua' ||
              item.category.trim().toLowerCase() == effectiveCategory.toLowerCase();
          final matchQuery = _searchController.text.isEmpty ||
              item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              item.category.toLowerCase().contains(_searchController.text.toLowerCase());
          return matchCategory && matchQuery;
        }).toList();

        final totalKritis = barangs.where((s) => s.isCritical || s.isWarning).length;

        return Scaffold(
          backgroundColor: bgDark,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header (Tombol Kembali, Judul, Subjudul)
                _buildHeader(barangs.length, totalKritis),

                // 2. Search Bar
                _buildSearchBar(),

                // 3. Filter Kategori Chips
                _buildCategoryFilter(activeCategories, effectiveCategory),

                // 4. Daftar Barang Cards
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada barang yang sesuai.',
                            style: TextStyle(color: textDim, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildBarangCard(filtered[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFab(),
          bottomNavigationBar: MotoBottomNav(
            currentIndex: 2,
            userData: widget.userData,
          ),
        );
      },
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildHeader(int totalProduk, int totalKritis) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Tombol Kembali
          BackButtonCircle(
            onTap: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(0);
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BerandaPage(userData: widget.userData),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 14),

          // Judul & Keterangan Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Barang',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalProduk Total Produk • $totalKritis Kritis',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: textWhite, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari nama barang atau kode...',
            hintStyle: const TextStyle(color: textDim, fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: textDim, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 44),
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: textDim,
                        size: 18,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories, String effectiveCategory) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.toLowerCase() == effectiveCategory.toLowerCase();

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentRed : cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accentRed : cardBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? textWhite : textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarangCard(BarangModel item) {
    Color iconBorderColor;
    Color stockBadgeColor;
    Color stockBadgeBg;
    if (item.isCritical) {
      iconBorderColor = accentRed;
      stockBadgeColor = accentRed;
      stockBadgeBg = const Color(0xFF3A161B);
    } else if (item.isWarning) {
      iconBorderColor = accentYellow;
      stockBadgeColor = accentYellow;
      stockBadgeBg = const Color(0xFF3A2F16);
    } else {
      iconBorderColor = accentGreen;
      stockBadgeColor = accentGreen;
      stockBadgeBg = const Color(0xFF132F1F);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCritical ? accentRed.withValues(alpha: 0.3) : cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon Heksagonal Berwarna
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF191D2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBorderColor.withValues(alpha: 0.7), width: 1.5),
            ),
            child: Center(
              child: Icon(
                Icons.token_rounded,
                color: iconBorderColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Info Nama, Kategori, Harga & Tanggal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
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
                  item.category,
                  style: const TextStyle(
                    color: textDim,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatRupiah(item.sellPrice),
                      style: const TextStyle(
                        color: accentGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.lastUpdated,
                        style: const TextStyle(
                          color: textDim,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Kolom Kanan: Stock Badge & Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge Stok
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stockBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stockBadgeColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${item.stock} ${item.unit}',
                  style: TextStyle(
                    color: stockBadgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Action Buttons Row (Edit & Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Edit
                  GestureDetector(
                    onTap: () => _showEditBarangModal(item),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF142033),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E3A8A)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF60A5FA),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tombol Delete
                  GestureDetector(
                    onTap: () => _confirmDeleteBarang(item),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF281116),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF5A1E24)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: accentRed,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditBarangModal(BarangModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final buyPriceCtrl = TextEditingController(text: formatRibuan(item.buyPrice));
    final sellPriceCtrl = TextEditingController(text: formatRibuan(item.sellPrice));
    final stockCtrl = TextEditingController(text: item.stock.toString());
    String selectedCat = item.category;

    final barangs = BarangService().barangsNotifier.value;
    final availableCats = <String>{
      if (item.category.trim().isNotEmpty) item.category.trim(),
      ...barangs.map((s) => s.category.trim()).where((c) => c.isNotEmpty),
      ...BarangService().categoriesNotifier.value,
    }.toList();
    if (availableCats.isEmpty) {
      availableCats.add('Lainnya');
    }
    if (!availableCats.contains(selectedCat)) {
      selectedCat = availableCats.first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: cardBorder),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                    color: textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Edit Data Barang',
                style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              const Text('Nama Barang', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDeco('Nama barang'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harga Beli', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: buyPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textWhite, fontSize: 13),
                          decoration: _buildInputDeco('Harga Beli', prefix: 'Rp '),
                          onChanged: (val) {
                            final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                            if (clean.isNotEmpty) {
                              final formatted = formatRibuan(int.parse(clean));
                              if (formatted != val) {
                                buyPriceCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harga Jual', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: sellPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textWhite, fontSize: 13),
                          decoration: _buildInputDeco('Harga Jual', prefix: 'Rp '),
                          onChanged: (val) {
                            final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                            if (clean.isNotEmpty) {
                              final formatted = formatRibuan(int.parse(clean));
                              if (formatted != val) {
                                sellPriceCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kategori Barang', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCat,
                              isExpanded: true,
                              dropdownColor: cardBg,
                              icon: const Icon(Icons.keyboard_arrow_down, color: textDim, size: 18),
                              style: const TextStyle(color: textWhite, fontSize: 12),
                              items: availableCats
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedCat = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jumlah Stok', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textWhite, fontSize: 13),
                          decoration: _buildInputDeco('0', suffix: item.unit),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal', style: TextStyle(color: textDim)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final n = nameCtrl.text.trim();
                        if (n.isEmpty) return;
                        final buy = int.tryParse(buyPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.buyPrice;
                        final sell = int.tryParse(sellPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.sellPrice;
                        final st = int.tryParse(stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.stock;

                        final updated = BarangModel(
                          id: item.id,
                          name: n,
                          category: selectedCat,
                          buyPrice: buy,
                          sellPrice: sell,
                          stock: st,
                          unit: item.unit,
                          lastUpdated: 'Diedit ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        );

                        Navigator.pop(ctx);
                        await BarangService().saveBarang(updated);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF143322),
                              content: Text('Barang "$n" berhasil diperbarui!'),
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan Perubahan', style: TextStyle(color: textWhite, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco(String hint, {String? prefix, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(color: textWhite, fontSize: 13),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: textDim, fontSize: 11),
      hintStyle: const TextStyle(color: textDim, fontSize: 12),
      filled: true,
      fillColor: bgDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _openTambahBarang,
      backgroundColor: accentRed,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: textWhite, size: 20),
      label: const Text(
        'Tambah Barang',
        style: TextStyle(
          color: textWhite,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Backward compatibility alias
typedef DataSparepartPage = DataBarangPage;
