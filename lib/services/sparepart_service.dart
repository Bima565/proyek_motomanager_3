import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  factory SparepartModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SparepartModel(
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

class SparepartService {
  static final SparepartService _instance = SparepartService._internal();
  factory SparepartService() => _instance;

  SparepartService._internal() {
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<List<SparepartModel>> sparepartsNotifier =
      ValueNotifier<List<SparepartModel>>([]);

  List<SparepartModel> get spareparts => sparepartsNotifier.value;

  // Riwayat Kategori Sparepart (Dibatasi 5 riwayat terbaru)
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
      _firestore.collection('spareparts').snapshots().listen(
        (snapshot) {
          final list = snapshot.docs
              .map((doc) => SparepartModel.fromFirestore(doc))
              .toList();

          sparepartsNotifier.value = list;
          _populateCategoriesFromSpareparts(list);
        },
        onError: (err) {
          debugPrint('Firestore spareparts stream error: $err');
        },
      );

      // Listen riwayat kategori yang tersimpan di Firestore settings
      _firestore
          .collection('settings')
          .doc('kategori_sparepart')
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
          debugPrint('Firestore kategori_sparepart stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore listen spareparts error: $e');
    }
  }

  void _populateCategoriesFromSpareparts(List<SparepartModel> list) {
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
    // Hapus jika sudah pernah ada sebelumnya agar berpindah ke paling baru (paling atas)
    current.removeWhere((c) => c.toLowerCase() == trimmed.toLowerCase());
    // Masukkan kategori baru di posisi teratas
    current.insert(0, trimmed);
    // Batasi cuman 5 riwayat saja (jika jadi 6, hapus yang terakhir / tertimbun)
    if (current.length > 5) {
      current = current.sublist(0, 5);
    }
    categoriesNotifier.value = current;

    try {
      await _firestore.collection('settings').doc('kategori_sparepart').set({
        'categories': current,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore save category history error: $e');
    }
  }

  Future<void> saveSparepart(SparepartModel item) async {
    final list = List<SparepartModel>.from(sparepartsNotifier.value);
    final idx = list.indexWhere((s) => s.id == item.id || s.name.toLowerCase() == item.name.toLowerCase());
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    sparepartsNotifier.value = list;

    try {
      if (item.id.isNotEmpty && !item.id.startsWith('temp_')) {
        await _firestore.collection('spareparts').doc(item.id).set(item.toMap(), SetOptions(merge: true));
      } else {
        final ref = await _firestore.collection('spareparts').add(item.toMap());
        item.id = ref.id;
      }
    } catch (e) {
      debugPrint('Firestore saveSparepart error: $e');
    }
  }

  Future<void> deleteSparepart(String id) async {
    sparepartsNotifier.value =
        sparepartsNotifier.value.where((s) => s.id != id).toList();

    try {
      await _firestore.collection('spareparts').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteSparepart error: $e');
    }
  }

  Future<void> adjustStock(String name, int delta) async {
    final list = List<SparepartModel>.from(sparepartsNotifier.value);
    final idx = list.indexWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    if (idx >= 0) {
      final s = list[idx];
      final newStock = (s.stock + delta).clamp(0, 99999);
      s.stock = newStock;
      s.lastUpdated = 'Diedit ${DateTime.now().hour}:${DateTime.now().minute}';
      sparepartsNotifier.value = list;

      try {
        await _firestore.collection('spareparts').doc(s.id).update({
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
