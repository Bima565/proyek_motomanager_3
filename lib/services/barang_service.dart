import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BarangModel {
  String id;
  String name;
  String category;
  int buyPrice;
  int sellPrice;
  int stock;
  String unit;
  String lastUpdated;

  BarangModel({
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'unit': unit,
      'lastUpdated': lastUpdated,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BarangModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BarangModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Lainnya',
      buyPrice: (data['buyPrice'] as num?)?.toInt() ?? 0,
      sellPrice: (data['sellPrice'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      unit: data['unit']?.toString() ?? 'Pcs',
      lastUpdated: data['lastUpdated']?.toString() ?? 'Baru saja',
    );
  }
}

// Backward-compatibility alias
typedef SparepartModel = BarangModel;

class BarangService {
  static final BarangService _instance = BarangService._internal();
  factory BarangService() => _instance;

  BarangService._internal() {
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<List<BarangModel>> barangsNotifier =
      ValueNotifier<List<BarangModel>>([]);

  List<BarangModel> get barangs => barangsNotifier.value;

  // Backward compatibility getters
  ValueNotifier<List<BarangModel>> get sparepartsNotifier => barangsNotifier;
  List<BarangModel> get spareparts => barangs;

  // Riwayat Kategori Barang (Dibatasi 5 riwayat terbaru)
  final ValueNotifier<List<String>> categoriesNotifier =
      ValueNotifier<List<String>>([
    'Oli & Pelumas',
    'Pengereman',
    'Kelistrikan',
    'Ban & Roda',
    'Transmisi CVT',
  ]);

  List<String> get categories => categoriesNotifier.value;

  void _listenFirestore() {
    try {
      // Koleksi database Firestore: 'barang'
      _firestore.collection('barang').snapshots().listen(
        (snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final list = snapshot.docs
                .map((doc) => BarangModel.fromFirestore(doc))
                .toList();
            barangsNotifier.value = list;
            _populateCategoriesFromBarangs(list);
          } else {
            // Migrasi otomatis jika sebelumnya data tersimpan di koleksi lama 'spareparts'
            try {
              final oldSnap = await _firestore.collection('spareparts').get();
              if (oldSnap.docs.isNotEmpty) {
                final list = <BarangModel>[];
                for (final doc in oldSnap.docs) {
                  final item = BarangModel.fromFirestore(doc);
                  list.add(item);
                  await _firestore
                      .collection('barang')
                      .doc(doc.id)
                      .set(item.toMap(), SetOptions(merge: true));
                }
                barangsNotifier.value = list;
                _populateCategoriesFromBarangs(list);
              } else {
                barangsNotifier.value = [];
              }
            } catch (_) {
              barangsNotifier.value = [];
            }
          }
        },
        onError: (err) {
          debugPrint('Firestore barang stream error: $err');
        },
      );

      // Listen riwayat kategori yang tersimpan di Firestore settings: 'kategori_barang'
      _firestore
          .collection('settings')
          .doc('kategori_barang')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final dataList = (snapshot.data()?['categories'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
                [];
            if (dataList.isNotEmpty) {
              categoriesNotifier.value = dataList.take(5).toList();
            }
          }
        },
        onError: (err) {
          debugPrint('Firestore kategori_barang stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore listen barang error: $e');
    }
  }

  void _populateCategoriesFromBarangs(List<BarangModel> list) {
    if (categoriesNotifier.value.isNotEmpty &&
        categoriesNotifier.value.length >= 5) {
      return;
    }
    final cats = <String>[];
    for (final s in list) {
      final c = s.category.trim();
      if (c.isNotEmpty &&
          !cats.any((item) => item.toLowerCase() == c.toLowerCase())) {
        cats.add(c);
        if (cats.length == 5) break;
      }
    }
    for (final def in [
      'Oli & Pelumas',
      'Pengereman',
      'Kelistrikan',
      'Ban & Roda',
      'Transmisi CVT',
    ]) {
      if (cats.length >= 5) break;
      if (!cats.any((item) => item.toLowerCase() == def.toLowerCase())) {
        cats.add(def);
      }
    }
    categoriesNotifier.value = cats.take(5).toList();
  }

  Future<void> addCategoryHistory(String newCategory) async {
    final trimmed = newCategory.trim();
    if (trimmed.isEmpty) return;

    List<String> current = List<String>.from(categoriesNotifier.value);
    current.removeWhere((c) => c.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > 5) {
      current = current.sublist(0, 5);
    }
    categoriesNotifier.value = current;

    try {
      await _firestore.collection('settings').doc('kategori_barang').set({
        'categories': current,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore save category history error: $e');
    }
  }

  Future<void> saveBarang(BarangModel item) async {
    final list = List<BarangModel>.from(barangsNotifier.value);
    final idx = list.indexWhere((s) => s.id == item.id || s.name.toLowerCase() == item.name.toLowerCase());
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    barangsNotifier.value = list;

    try {
      if (item.id.isNotEmpty && !item.id.startsWith('temp_')) {
        await _firestore.collection('barang').doc(item.id).set(item.toMap(), SetOptions(merge: true));
      } else {
        final ref = await _firestore.collection('barang').add(item.toMap());
        item.id = ref.id;
      }
    } catch (e) {
      debugPrint('Firestore saveBarang error: $e');
    }
  }

  Future<void> deleteBarang(String id) async {
    barangsNotifier.value =
        barangsNotifier.value.where((s) => s.id != id).toList();

    try {
      await _firestore.collection('barang').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteBarang error: $e');
    }
  }

  // Backward compatibility alias methods
  Future<void> saveSparepart(BarangModel item) => saveBarang(item);
  Future<void> deleteSparepart(String id) => deleteBarang(id);

  /// Tambah atau sesuaikan stok barang (otomatis buat master data barang baru jika belum ada)
  Future<void> addOrAdjustStock({
    required String name,
    required String category,
    required int buyPrice,
    int? sellPrice,
    required int quantity,
    String unit = 'Pcs',
  }) async {
    final list = List<BarangModel>.from(barangsNotifier.value);
    final idx = list.indexWhere((s) => s.name.trim().toLowerCase() == name.trim().toLowerCase());
    if (idx >= 0) {
      final s = list[idx];
      final newStock = (s.stock + quantity).clamp(0, 99999);
      s.stock = newStock;
      s.buyPrice = buyPrice;
      if (sellPrice != null && sellPrice > 0) {
        s.sellPrice = sellPrice;
      }
      s.lastUpdated = 'Restock ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      barangsNotifier.value = list;

      try {
        final updateData = <String, dynamic>{
          'stock': newStock,
          'buyPrice': buyPrice,
          'lastUpdated': s.lastUpdated,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (sellPrice != null && sellPrice > 0) {
          updateData['sellPrice'] = sellPrice;
        }
        await _firestore.collection('barang').doc(s.id).update(updateData);
      } catch (e) {
        debugPrint('Firestore addOrAdjustStock update error: $e');
      }
    } else {
      // Buat master barang baru otomatis
      final computedSellPrice = (sellPrice != null && sellPrice > 0)
          ? sellPrice
          : (buyPrice * 1.25).round();
      final newPart = BarangModel(
        id: '',
        name: name.trim(),
        category: category.trim().isNotEmpty ? category.trim() : 'Lainnya',
        buyPrice: buyPrice,
        sellPrice: computedSellPrice,
        stock: quantity,
        unit: unit.trim().isNotEmpty ? unit.trim() : 'Pcs',
        lastUpdated: 'Restock Baru',
      );
      await saveBarang(newPart);
    }
  }

  Future<void> adjustStock(String name, int delta) async {
    final list = List<BarangModel>.from(barangsNotifier.value);
    final idx = list.indexWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    if (idx >= 0) {
      final s = list[idx];
      final newStock = (s.stock + delta).clamp(0, 99999);
      s.stock = newStock;
      s.lastUpdated = 'Diedit ${DateTime.now().hour}:${DateTime.now().minute}';
      barangsNotifier.value = list;

      try {
        await _firestore.collection('barang').doc(s.id).update({
          'stock': newStock,
          'lastUpdated': s.lastUpdated,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore adjustStock error: $e');
      }
    }
  }
}

// Backward-compatibility alias
typedef SparepartService = BarangService;
