import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'sparepart_service.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'buyPrice': buyPrice,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory RestockItemModel.fromMap(Map<String, dynamic> map) {
    return RestockItemModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      buyPrice: (map['buyPrice'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit']?.toString() ?? 'pcs',
    );
  }
}

class PembelianRecord {
  final String id;
  final String code;
  final DateTime dateTime;
  final String buyerName;
  final String supplier;
  final List<RestockItemModel> items;
  final int totalAmount;
  final String status;
  final String notes;

  PembelianRecord({
    this.id = '',
    required this.code,
    required this.dateTime,
    required this.buyerName,
    required this.supplier,
    required this.items,
    required this.totalAmount,
    this.status = 'LUNAS',
    this.notes = '',
  });

  String get dateFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    return '$d/$m/$y';
  }

  String get timeFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$min $d/$m/$y';
  }

  String get summaryItems {
    return items.map((i) => '${i.quantity}x ${i.name}').join(' + ');
  }

  int get totalQuantity => items.fold(0, (total, i) => total + i.quantity);

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'timestamp': Timestamp.fromDate(dateTime),
      'buyerName': buyerName,
      'supplier': supplier,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
    };
  }

  factory PembelianRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['timestamp'];
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((i) => RestockItemModel.fromMap(Map<String, dynamic>.from(i as Map)))
        .toList();

    return PembelianRecord(
      id: doc.id,
      code: data['code']?.toString() ?? doc.id,
      dateTime: dt,
      buyerName: data['buyerName']?.toString() ?? 'Sugeng Yulianto',
      supplier: data['supplier']?.toString() ?? 'Toko Sumber Jaya',
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'LUNAS',
      notes: data['notes']?.toString() ?? '',
    );
  }
}

class PembelianService {
  static final PembelianService _instance = PembelianService._internal();
  factory PembelianService() => _instance;

  PembelianService._internal() {
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<List<PembelianRecord>> pembelianNotifier =
      ValueNotifier<List<PembelianRecord>>([]);

  List<PembelianRecord> get pembelianList => pembelianNotifier.value;

  void _listenFirestore() {
    try {
      _firestore
          .collection('transaksi_pembelian')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final firestoreList = snapshot.docs
              .map((doc) => PembelianRecord.fromFirestore(doc))
              .toList();

          pembelianNotifier.value = firestoreList;
        },
        onError: (err) {
          debugPrint('Firestore pembelian stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore listen pembelian error: $e');
    }
  }

  String generateBeliCode() {
    final nextNumber = pembelianList.length + 1;
    final numStr = nextNumber.toString().padLeft(3, '0');
    return '#BELI-$numStr';
  }

  Future<PembelianRecord> savePembelian(PembelianRecord pembelian) async {
    // 1. Simpan ke reactive memory state langsung (instan)
    final updatedList = [pembelian, ...pembelianNotifier.value];
    pembelianNotifier.value = updatedList;

    // 2. Tambah stok sparepart yang direstock
    for (final item in pembelian.items) {
      SparepartService().adjustStock(item.name, item.quantity);
    }

    // 3. Simpan secara asinkron ke Firestore
    try {
      await _firestore
          .collection('transaksi_pembelian')
          .doc(pembelian.code)
          .set(pembelian.toMap());
      return pembelian;
    } catch (e) {
      debugPrint('Firestore savePembelian failed (local saved): $e');
      return pembelian;
    }
  }

  int getMonthlyExpense({int? year, int? month}) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    return pembelianList
        .where((p) => p.dateTime.year == y && p.dateTime.month == m)
        .fold(0, (total, p) => total + p.totalAmount);
  }
}
