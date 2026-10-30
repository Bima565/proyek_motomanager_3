import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class JasaModel {
  String id;
  String name;
  int price;
  String lastEdited;

  JasaModel({
    required this.id,
    required this.name,
    required this.price,
    required this.lastEdited,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'lastEdited': lastEdited,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory JasaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JasaModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      lastEdited: data['lastEdited']?.toString() ?? 'Baru saja',
    );
  }
}

class JasaService {
  static final JasaService _instance = JasaService._internal();
  factory JasaService() => _instance;

  JasaService._internal() {
    _listenFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<List<JasaModel>> servicesNotifier =
      ValueNotifier<List<JasaModel>>([]);

  List<JasaModel> get services => servicesNotifier.value;

  void _listenFirestore() {
    try {
      _firestore.collection('jasa_servis').snapshots().listen(
        (snapshot) {
          final list = snapshot.docs
              .map((doc) => JasaModel.fromFirestore(doc))
              .toList();

          servicesNotifier.value = list;
        },
        onError: (err) {
          debugPrint('Firestore jasa_servis stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore listen jasa_servis error: $e');
    }
  }

  Future<void> saveJasa(JasaModel item) async {
    final list = List<JasaModel>.from(servicesNotifier.value);
    final idx = list.indexWhere((j) => j.id == item.id || j.name.toLowerCase() == item.name.toLowerCase());
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    servicesNotifier.value = list;

    try {
      if (item.id.isNotEmpty && !item.id.startsWith('temp_')) {
        await _firestore.collection('jasa_servis').doc(item.id).set(item.toMap(), SetOptions(merge: true));
      } else {
        final ref = await _firestore.collection('jasa_servis').add(item.toMap());
        item.id = ref.id;
      }
    } catch (e) {
      debugPrint('Firestore saveJasa error: $e');
    }
  }

  Future<void> deleteJasa(String id) async {
    servicesNotifier.value =
        servicesNotifier.value.where((j) => j.id != id).toList();

    try {
      await _firestore.collection('jasa_servis').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteJasa error: $e');
    }
  }
}
