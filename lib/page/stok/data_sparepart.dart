import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/moto_bottom_nav.dart';
import '../../components/rupiah_formatter.dart';
import '../../services/sparepart_service.dart';
import '../beranda.dart';
import 'tambah_sparepart.dart';

export '../../services/sparepart_service.dart' show SparepartModel;

/// Screen Data Sparepart & Stok (FR05)
class DataSparepartPage extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final Map<String, dynamic>? userData;

  const DataSparepartPage({
    super.key,
    this.onNavigateTab,
    this.userData,
  });

  @override
  State<DataSparepartPage> createState() => _DataSparepartPageState();
}

class _DataSparepartPageState extends State<DataSparepartPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Oli & Pelumas',
    'Pengereman',
    'Kelistrikan',
    'Ban & Roda',
    'Transmisi CVT',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) => formatRupiah(nominal);

  void _openTambahSparepart() async {
    final result = await Navigator.push<SparepartModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const TambahSparepartPage(),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF143322),
          content: Text('Sparepart "${result.name}" berhasil disimpan ke Firestore!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SparepartModel>>(
      valueListenable: SparepartService().sparepartsNotifier,
      builder: (context, spareparts, _) {
        final filtered = spareparts.where((item) {
          final matchCategory = _selectedCategory == 'Semua' ||
              item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
          final matchQuery = _searchController.text.isEmpty ||
              item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              item.category.toLowerCase().contains(_searchController.text.toLowerCase());
          return matchCategory && matchQuery;
        }).toList();

        final totalKritis = spareparts.where((s) => s.isCritical || s.isWarning).length;

        return Scaffold(
          backgroundColor: bgDark,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header (Tombol Kembali, Judul, Subjudul)
                _buildHeader(spareparts.length, totalKritis),

                // 2. Search Bar
                _buildSearchBar(),

                // 3. Filter Kategori Chips
                _buildCategoryFilter(),

                // 4. Daftar Sparepart Cards
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada sparepart yang sesuai.',
                            style: TextStyle(color: textDim, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildSparepartCard(filtered[index]);
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
                'Data Sparepart',
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
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: textWhite, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Cari nama sparepart atau kode...',
            hintStyle: TextStyle(color: textDim, fontSize: 12),
            prefixIcon: Icon(Icons.search_rounded, color: textDim, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontSize: 11,
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

  Widget _buildSparepartCard(SparepartModel item) {
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
                const SizedBox(height: 3),
                Text(
                  'Kategori: ${item.category}',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '• ${item.lastUpdated}',
                        style: TextStyle(
                          color: item.lastUpdated.startsWith('Diedit')
                              ? accentCyan
                              : textMuted,
                          fontSize: 9,
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
          const SizedBox(width: 8),

          // 3. Badge Stok & Tombol Kebab Action Sesuai Penpot Screen 5
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Stok
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: stockBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: stockBadgeColor,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${item.stock} ${item.unit}',
                  style: TextStyle(
                    color: stockBadgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Tombol Kebab Action [ ⋮ ]
              GestureDetector(
                onTap: () => _showItemActions(item),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2333),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF2D3548),
                      width: 0.8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF94A3B8),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditSparepartModal(SparepartModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final buyPriceCtrl = TextEditingController(text: item.buyPrice.toString());
    final sellPriceCtrl = TextEditingController(text: item.sellPrice.toString());
    final stockCtrl = TextEditingController(text: item.stock.toString());
    String selectedCat = item.category;

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
                'Edit Data Sparepart',
                style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              const Text('Nama Sparepart', style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: textWhite, fontSize: 13),
                decoration: _buildInputDeco('Nama sparepart'),
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
                          style: const TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: _buildInputDeco('0', prefix: 'Rp '),
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
                          style: const TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: _buildInputDeco('0', prefix: 'Rp '),
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
                        const Text('Stok Saat Ini', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textWhite, fontSize: 13),
                          decoration: _buildInputDeco('0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kategori', style: TextStyle(color: textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: DropdownButton<String>(
                            value: _categories.skip(1).contains(selectedCat) ? selectedCat : _categories[1],
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: cardBg,
                            style: const TextStyle(color: textWhite, fontSize: 12),
                            items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedCat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final bp = int.tryParse(buyPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.buyPrice;
                    final sp = int.tryParse(sellPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.sellPrice;
                    final st = int.tryParse(stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.stock;

                    if (name.isNotEmpty) {
                      final now = DateTime.now();
                      final updated = SparepartModel(
                        id: item.id,
                        name: name,
                        category: selectedCat,
                        buyPrice: bp,
                        sellPrice: sp,
                        stock: st,
                        unit: item.unit,
                        lastUpdated:
                            'Diedit ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}',
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      await SparepartService().saveSparepart(updated);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF143322),
                          content: Text('${updated.name} berhasil diperbarui di Firestore!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: textDim, fontSize: 12),
      filled: true,
      fillColor: bgDark,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accentRed)),
    );
  }

  void _showItemActions(SparepartModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: cardBorder),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textDim.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                color: textWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF60A5FA)),
              title: const Text('Edit Sparepart', style: TextStyle(color: textWhite, fontSize: 13.5)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditSparepartModal(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: accentRed),
              title: const Text('Hapus Sparepart',
                  style: TextStyle(color: accentRed, fontSize: 13.5, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                await SparepartService().deleteSparepart(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF3B1517),
                      content: Text('${item.name} berhasil dihapus dari Firestore'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton.extended(
        onPressed: _openTambahSparepart,
        backgroundColor: accentRed,
        foregroundColor: textWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Tambah Part',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
