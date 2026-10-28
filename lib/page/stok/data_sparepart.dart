import 'package:flutter/material.dart';
import '../../components/back_button_circle.dart';
import '../../components/moto_bottom_nav.dart';
import '../../components/rupiah_formatter.dart';
import '../beranda.dart';
import 'tambah_sparepart.dart';

class SparepartModel {
  String id;
  String name;
  String category;
  int buyPrice;
  int sellPrice;
  int stock;
  String unit;
  String lastUpdated;

  SparepartModel({
    required this.id,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    this.unit = 'Pcs',
    required this.lastUpdated,
  });

  bool get isCritical => stock <= 2;
  bool get isWarning => stock > 2 && stock <= 5;
}

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

  late List<SparepartModel> _spareparts;

  @override
  void initState() {
    super.initState();
    _spareparts = [
      SparepartModel(
        id: '1',
        name: 'Oli Yamalube Silver 0.8L',
        category: 'Oli & Pelumas',
        buyPrice: 35000,
        sellPrice: 45000,
        stock: 2,
        unit: 'Pcs',
        lastUpdated: 'Diedit 14:15 28/9/2026',
      ),
      SparepartModel(
        id: '2',
        name: 'Kampas Rem Depan Vario/Beat',
        category: 'Pengereman',
        buyPrice: 40000,
        sellPrice: 55000,
        stock: 3,
        unit: 'Pcs',
        lastUpdated: '09:30 25/9/2026',
      ),
      SparepartModel(
        id: '3',
        name: 'Busi NGK CPR9EA-9',
        category: 'Kelistrikan',
        buyPrice: 20000,
        sellPrice: 30000,
        stock: 14,
        unit: 'Pcs',
        lastUpdated: 'Diedit 16:45 27/9/2026',
      ),
      SparepartModel(
        id: '4',
        name: 'Ban Luar Tubeless FDR 90/90-14',
        category: 'Ban & Roda',
        buyPrice: 150000,
        sellPrice: 185000,
        stock: 18,
        unit: 'Pcs',
        lastUpdated: '11:20 18/9/2026',
      ),
      SparepartModel(
        id: '5',
        name: 'Roller Set Honda Beat FI (11g)',
        category: 'Transmisi CVT',
        buyPrice: 28000,
        sellPrice: 40000,
        stock: 8,
        unit: 'Set',
        lastUpdated: 'Diedit 10:10 29/9/2026',
      ),
    ];
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

    if (result != null) {
      setState(() {
        _spareparts.insert(0, result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF143322),
            content: Text('Sparepart "${result.name}" berhasil ditambahkan!'),
          ),
        );
      }
    }
  }

  List<SparepartModel> get _filteredSpareparts {
    return _spareparts.where((item) {
      final matchCategory = _selectedCategory == 'Semua' ||
          item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchQuery = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchCategory && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSpareparts;
    final totalKritis = _spareparts.where((s) => s.isCritical || s.isWarning).length;

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Tombol Kembali, Judul, Subjudul)
            _buildHeader(totalKritis),

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
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildHeader(int totalKritis) {
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
                '${_spareparts.length} Total Produk • $totalKritis Kritis',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: cardBg,
                    content: Text('Edit data ${item.name}'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: accentRed),
              title: const Text('Hapus Sparepart',
                  style: TextStyle(color: accentRed, fontSize: 13.5, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _spareparts.remove(item));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF3B1517),
                    content: Text('${item.name} berhasil dihapus'),
                  ),
                );
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
