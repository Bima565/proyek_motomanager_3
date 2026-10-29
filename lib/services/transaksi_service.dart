import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    _initSeedTransactions();
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive state notifier untuk list transaksi lokal
  final ValueNotifier<List<TransaksiPenjualanModel>> transactionsNotifier =
      ValueNotifier<List<TransaksiPenjualanModel>>([]);

  List<TransaksiPenjualanModel> get transactions => transactionsNotifier.value;

  void _initSeedTransactions() {
    // Sesuai Penpot Screen 12 & Screen 3
    final initialList = [
      TransaksiPenjualanModel(
        id: 'seed-026',
        code: 'TRX-20260929-026',
        dateTime: DateTime(2026, 9, 29, 10, 45),
        customerName: 'Bpk. Rahmat Santoso',
        vehicleInfo: 'Honda Vario 160',
        policeNumber: 'B 4921 KDF',
        customerPhone: '081234567890',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: '1',
            name: 'Jasa Servis Lengkap + Tune Up',
            category: 'Jasa Servis',
            subInfo: 'Ongkos Mekanik',
            price: 80000,
            quantity: 1,
            isService: true,
          ),
          TransaksiItemModel(
            id: '2',
            name: 'Oli Shell Advance AX7 0.8L',
            category: 'Oli & Pelumas',
            subInfo: 'Sisa: 12',
            price: 65000,
            quantity: 1,
            isService: false,
          ),
          TransaksiItemModel(
            id: '3',
            name: 'Busi NGK CPR9EA-9',
            category: 'Kelistrikan',
            subInfo: 'Sisa: 18',
            price: 30000,
            quantity: 1,
            isService: false,
          ),
        ],
        totalBayar: 175000,
        paymentMethod: 'Tunai',
        tunaiDiterima: 200000,
        kembalian: 25000,
      ),
      TransaksiPenjualanModel(
        id: 'seed-005',
        code: '#TRX-005',
        dateTime: DateTime(2026, 9, 20, 8, 30),
        customerName: 'Dian Pratama',
        vehicleInfo: 'Yamaha NMAX',
        policeNumber: 'B 3108 TFD',
        customerPhone: '081399887766',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: 's-1',
            name: 'Tambal Tubeless + Cairan Ban',
            category: 'Jasa Servis',
            subInfo: 'Ban & Velg',
            price: 40000,
            quantity: 1,
            isService: true,
          ),
        ],
        totalBayar: 40000,
        paymentMethod: 'QRIS',
        tunaiDiterima: 40000,
        kembalian: 0,
      ),
      TransaksiPenjualanModel(
        id: 'seed-004',
        code: '#TRX-004',
        dateTime: DateTime(2026, 9, 20, 10, 15),
        customerName: 'Rudi Hartono',
        vehicleInfo: 'Honda Supra X 125',
        policeNumber: 'B 5821 SKA',
        customerPhone: '081277665544',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: 's-2',
            name: 'Bersihkan Karburator + Rantai Roda',
            category: 'Jasa Servis',
            subInfo: 'Mesin & Penggerak',
            price: 95000,
            quantity: 1,
            isService: true,
          ),
        ],
        totalBayar: 95000,
        paymentMethod: 'Tunai',
        tunaiDiterima: 100000,
        kembalian: 5000,
      ),
      TransaksiPenjualanModel(
        id: 'seed-003',
        code: '#TRX-003',
        dateTime: DateTime(2026, 9, 19, 14, 20),
        customerName: 'Ibu Sri Wahyuni',
        vehicleInfo: 'Yamaha Mio M3',
        policeNumber: 'B 6940 PLM',
        customerPhone: '085711223344',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: 's-3',
            name: 'Ganti Oli Mesin & Gardan',
            category: 'Jasa Servis',
            subInfo: 'Pelumas Rutin',
            price: 80000,
            quantity: 1,
            isService: true,
          ),
        ],
        totalBayar: 80000,
        paymentMethod: 'Tunai',
        tunaiDiterima: 80000,
        kembalian: 0,
      ),
      TransaksiPenjualanModel(
        id: 'seed-002',
        code: '#TRX-002',
        dateTime: DateTime(2026, 9, 18, 11, 0),
        customerName: 'Ahmad Fauzi',
        vehicleInfo: 'Honda Vario 160',
        policeNumber: 'B 4120 JKT',
        customerPhone: '087855443322',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: 's-4',
            name: 'Servis CVT & Rem + Roller + Kampas',
            category: 'Jasa Servis',
            subInfo: 'Paket Servis',
            price: 130000,
            quantity: 1,
            isService: true,
          ),
        ],
        totalBayar: 130000,
        paymentMethod: 'QRIS',
        tunaiDiterima: 130000,
        kembalian: 0,
      ),
      TransaksiPenjualanModel(
        id: 'seed-001',
        code: '#TRX-001',
        dateTime: DateTime(2026, 9, 17, 9, 10),
        customerName: 'Budi Santoso',
        vehicleInfo: 'Honda Beat FI',
        policeNumber: 'B 3844 KTY',
        customerPhone: '081299001122',
        kasirName: 'Sri Ekowati',
        items: [
          TransaksiItemModel(
            id: 's-5',
            name: 'Servis Ringan + Oli MPX2 + Busi',
            category: 'Jasa Servis',
            subInfo: 'Servis Berkala',
            price: 105000,
            quantity: 1,
            isService: true,
          ),
        ],
        totalBayar: 105000,
        paymentMethod: 'Tunai',
        tunaiDiterima: 110000,
        kembalian: 5000,
      ),
    ];

    transactionsNotifier.value = initialList;
  }

  void _listenFirestore() {
    try {
      _firestore
          .collection('transaksi_penjualan')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;

          final firestoreList = snapshot.docs
              .map((doc) => TransaksiPenjualanModel.fromFirestore(doc))
              .toList();

          // Gabungkan data Firestore dengan seed yang belum tersimpan di Firestore
          final currentMap = <String, TransaksiPenjualanModel>{};
          for (final t in transactionsNotifier.value) {
            currentMap[t.code] = t;
          }
          for (final t in firestoreList) {
            currentMap[t.code] = t;
          }

          final combined = currentMap.values.toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          transactionsNotifier.value = combined;
        },
        onError: (err) {
          debugPrint('Firestore transaksi stream offline/fallback: $err');
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

    // 2. Simpan secara asinkron ke Firestore
    try {
      final docRef = await _firestore.collection('transaksi_penjualan').add(trx.toMap());
      final syncedTrx = TransaksiPenjualanModel(
        id: docRef.id,
        code: trx.code,
        dateTime: trx.dateTime,
        customerName: trx.customerName,
        vehicleInfo: trx.vehicleInfo,
        policeNumber: trx.policeNumber,
        customerPhone: trx.customerPhone,
        kasirName: trx.kasirName,
        items: trx.items,
        totalBayar: trx.totalBayar,
        paymentMethod: trx.paymentMethod,
        tunaiDiterima: trx.tunaiDiterima,
        kembalian: trx.kembalian,
        status: trx.status,
      );
      // Update item di memory jika ID berubah
      final mapped = transactionsNotifier.value.map((t) {
        if (t.code == trx.code) return syncedTrx;
        return t;
      }).toList();
      transactionsNotifier.value = mapped;
      return syncedTrx;
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
