import 'package:flutter/material.dart';
import '../../services/jasa_service.dart';
import 'data_sparepart.dart';

export '../../services/jasa_service.dart' show JasaModel;

/// Screen 6 - Master Layanan Jasa Servis (FR06)
class MasterJasaPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MasterJasaPage({
    super.key,
    this.userData,
  });

  @override
  State<MasterJasaPage> createState() => _MasterJasaPageState();
}

class _MasterJasaPageState extends State<MasterJasaPage> {
  // Warna Design System Penpot MotoManage
  static const Color bgDark = Color(0xFF0E1015);
  static const Color cardBg = Color(0xFF151821);
  static const Color cardBorder = Color(0xFF222634);
  static const Color accentRed = Color(0xFFFF1E27);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) {
    final str = nominal.toString();
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

  List<JasaModel> _getFilteredServices(List<JasaModel> services) {
    if (_searchQuery.isEmpty) return services;
    return services
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showJasaModal({JasaModel? itemToEdit}) {
    final bool isEdit = itemToEdit != null;
    final nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final priceController = TextEditingController(
      text: itemToEdit != null ? _formatRupiah(itemToEdit.price) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 12,
          ),
          decoration: const BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: cardBorder, width: 1.2),
              left: BorderSide(color: cardBorder, width: 1.2),
              right: BorderSide(color: cardBorder, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis Merah Penpot Indicator
              Center(
                child: Container(
                  width: 48,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: accentRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row: Icon + Judul/Subjudul + Tombol Close 'x'
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26190B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.build_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Ubah Jasa Servis' : 'Tambah Jasa Servis',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Input jenis servis & ongkos kerja',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2330),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Field 1: Nama Layanan Servis *
              const Text(
                'Nama Layanan Servis *',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(color: textWhite, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Servis Throttle Body / Injeksi',
                    hintStyle: TextStyle(color: textDim, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Field 2: Tarif Jasa (Border Hijau)
              const Text(
                'Tarif Jasa',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentGreen, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Text(
                      'Rp  ',
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: '45.000',
                          hintStyle: TextStyle(color: textDim, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Tombol Simpan Layanan Jasa (Merah Solid)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final priceRaw = priceController.text.replaceAll('.', '').trim();
                    final price = int.tryParse(priceRaw) ?? 0;

                    if (name.isNotEmpty && price > 0) {
                      final now = DateTime.now();
                      final timeStr =
                          'Diedit ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}';
                      final item = JasaModel(
                        id: isEdit ? itemToEdit.id : 'js-${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        price: price,
                        lastEdited: timeStr,
                      );
                      Navigator.pop(ctx);
                      await JasaService().saveJasa(item);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF143322),
                            content: Text('Layanan "$name" berhasil disimpan ke Firestore!'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Simpan Layanan Jasa',
                    style: const TextStyle(
                      color: textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (isEdit) ...[
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: accentRed,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Hapus Layanan Jasa', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await JasaService().deleteJasa(itemToEdit.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF3B1517),
                            content: Text('Layanan "${itemToEdit.name}" berhasil dihapus dari Firestore'),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JasaModel>>(
      valueListenable: JasaService().servicesNotifier,
      builder: (context, services, _) {
        final filtered = _getFilteredServices(services);

        return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Header + Search + Segmented Tab)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textWhite,
                            size: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Layanan Jasa Servis',
                              style: TextStyle(
                                color: textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${services.length} Jenis Layanan Aktif',
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: textWhite, fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari jenis layanan jasa...',
                        hintStyle: const TextStyle(color: textDim, fontSize: 12),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: textDim,
                          size: 18,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: textDim,
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Switcher Tab (Sparepart | Jasa)
                  Row(
                    children: [
                      // Tab Sparepart (Inactive)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DataSparepartPage(
                                userData: widget.userData,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131722),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: const Text(
                            'Sparepart',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tab Jasa (Active Red)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accentRed,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accentRed.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Jasa',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Services List Section
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.build_circle_outlined,
                            color: textDim,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada jasa cocok dengan "$_searchQuery"'
                                : 'Belum ada data jasa',
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildJasaCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),

      // Floating Action Button (+ Tambah Jasa) Sesuai Penpot
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 6),
        child: GestureDetector(
          onTap: () => _showJasaModal(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: accentRed,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentRed.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: textWhite, size: 16),
                SizedBox(width: 4),
                Text(
                  'Tambah Jasa',
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
      ),
    );
      },
    );
  }

  Widget _buildJasaCard(JasaModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Icon Tool Box dengan Border Kuning/Amber
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF26190B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706), width: 1.2),
            ),
            child: const Center(
              child: Icon(
                Icons.build_rounded,
                color: Color(0xFFFBBF24),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Nama Jasa, Harga Hijau & Tanggal Edit
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rp ${_formatRupiah(item.price)}',
                      style: const TextStyle(
                        color: accentGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '• ${item.lastEdited}',
                        style: const TextStyle(
                          color: textDim,
                          fontSize: 9.5,
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

          // Tombol Ubah (Pill Abu Gelap)
          GestureDetector(
            onTap: () => _showJasaModal(itemToEdit: item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2332),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF293042)),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
