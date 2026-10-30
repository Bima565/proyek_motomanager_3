import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'sparepart_service.dart';

class TransaksiItemModel {
  String id;
  String name;
  String category;
  String subInfo;
  int price;
  int quantity;
  bool isService;

  TransaksiItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subInfo,
    required this.price,
    this.quantity = 1,
    required this.isService,
  });

  int get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subInfo': subInfo,
      'price': price,
      'quantity': quantity,
      'isService': isService,
    };
  }

  factory TransaksiItemModel.fromMap(Map<String, dynamic> map) {
    return TransaksiItemModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      subInfo: map['subInfo']?.toString() ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isService: map['isService'] == true,
    );
  }
}

class TransaksiPenjualanModel {
  final String id;
  final String code;
  final DateTime dateTime;
  final String customerName;
  final String vehicleInfo;
  final String policeNumber;
  final String customerPhone;
  final String kasirName;
  final List<TransaksiItemModel> items;
  final int totalBayar;
  final String paymentMethod; // 'Tunai' | 'QRIS' | 'Transfer'
  final int tunaiDiterima;
  final int kembalian;
  final String status;

  TransaksiPenjualanModel({
    required this.id,
    required this.code,
    required this.dateTime,
    required this.customerName,
    required this.vehicleInfo,
    required this.policeNumber,
    this.customerPhone = '',
    required this.kasirName,
    required this.items,
    required this.totalBayar,
    required this.paymentMethod,
    required this.tunaiDiterima,
    required this.kembalian,
    this.status = 'Lunas',
  });

  String get timeFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$min $d/$m/$y';
  }

  String get dateFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    return '$d/$m/$y';
  }

  String get notaTimeFormatted {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year;
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min WIB';
  }

  String get summaryServices {
    final services = items.map((i) => i.name).toList();
    if (services.isEmpty) return 'Transaksi Penjualan';
    return services.join(' + ');
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'timestamp': Timestamp.fromDate(dateTime),
      'customerName': customerName,
      'vehicleInfo': vehicleInfo,
      'policeNumber': policeNumber,
      'customerPhone': customerPhone,
      'kasirName': kasirName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalBayar': totalBayar,
      'paymentMethod': paymentMethod,
      'tunaiDiterima': tunaiDiterima,
      'kembalian': kembalian,
      'status': status,
    };
  }

  factory TransaksiPenjualanModel.fromFirestore(DocumentSnapshot doc) {
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
        .map((i) => TransaksiItemModel.fromMap(Map<String, dynamic>.from(i as Map)))
        .toList();

    return TransaksiPenjualanModel(
      id: doc.id,
      code: data['code']?.toString() ?? doc.id,
      dateTime: dt,
      customerName: data['customerName']?.toString() ?? 'Pelanggan Umum',
      vehicleInfo: data['vehicleInfo']?.toString() ?? '',
      policeNumber: data['policeNumber']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      kasirName: data['kasirName']?.toString() ?? 'Kasir',
      items: items,
      totalBayar: (data['totalBayar'] as num?)?.toInt() ?? 0,
      paymentMethod: data['paymentMethod']?.toString() ?? 'Tunai',
      tunaiDiterima: (data['tunaiDiterima'] as num?)?.toInt() ?? 0,
      kembalian: (data['kembalian'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'Lunas',
    );
  }
}

class TransaksiService {
  static final TransaksiService _instance = TransaksiService._internal();
  factory TransaksiService() => _instance;

  TransaksiService._internal() {
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive state notifier untuk list transaksi lokal (murni bersumber dari Cloud Firestore)
  final ValueNotifier<List<TransaksiPenjualanModel>> transactionsNotifier =
      ValueNotifier<List<TransaksiPenjualanModel>>([]);

  List<TransaksiPenjualanModel> get transactions => transactionsNotifier.value;

  void _listenFirestore() {
    try {
      _firestore
          .collection('transaksi_penjualan')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final firestoreList = snapshot.docs
              .map((doc) => TransaksiPenjualanModel.fromFirestore(doc))
              .toList();

          transactionsNotifier.value = firestoreList;
        },
        onError: (err) {
          debugPrint('Firestore transaksi stream offline/error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore listen transaksi error: $e');
    }
  }

  /// Generate nomor kode transaksi baru
  String generateTrxCode() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final count = transactions.length + 1;
    final seq = count.toString().padLeft(3, '0');
    return 'TRX-$y$m$d-$seq';
  }

  /// Simpan transaksi penjualan baru
  Future<TransaksiPenjualanModel> saveTransaksi(TransaksiPenjualanModel trx) async {
    // 1. Simpan ke reactive memory state langsung (instan)
    final updatedList = [trx, ...transactionsNotifier.value];
    transactionsNotifier.value = updatedList;

    // 2. Potong stok sparepart yang terjual
    for (final item in trx.items) {
      if (!item.isService) {
        SparepartService().adjustStock(item.name, -item.quantity);
      }
    }

    // 3. Simpan secara asinkron ke Firestore
    try {
      await _firestore
          .collection('transaksi_penjualan')
          .doc(trx.code)
          .set(trx.toMap());
      return trx;
    } catch (e) {
      debugPrint('Firestore saveTransaksi failed (local saved): $e');
      return trx;
    }
  }

  /// Total omzet penjualan hari ini
  int getTodayOmzet() {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .fold(0, (total, t) => total + t.totalBayar);
  }
}
