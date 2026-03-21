import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/cat_model.dart';


class CatService {
  CatService._();
  static final CatService _instance = CatService._();
  factory CatService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CatModel>> getCatsByFamilyId(String familyId) async {
    final snap = await _firestore
        .collection(AppConstants.catsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => CatModel.fromMap(d.data(), d.id)).toList();
  }

  Stream<List<CatModel>> watchCatsByFamilyId(String familyId) {
    return _firestore
        .collection(AppConstants.catsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CatModel.fromMap(d.data(), d.id)).toList());
  }

  Future<CatModel?> getCat(String catId) async {
    final doc = await _firestore.collection(AppConstants.catsCollection).doc(catId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CatModel.fromMap(doc.data()!, doc.id);
  }

  Future<CatModel> createCat(CatModel cat) async {
    final ref = _firestore.collection(AppConstants.catsCollection).doc(cat.catId);
    await ref.set(cat.toMap());
    return cat;
  }

  Future<void> updateCat(CatModel cat) async {
    await _firestore.collection(AppConstants.catsCollection).doc(cat.catId).update(cat.toMap());
  }

  Future<void> deleteCat(String catId) async {
    await _firestore.collection(AppConstants.catsCollection).doc(catId).delete();
  }

  Future<int> countCatsInFamily(String familyId) async {
    final snap = await _firestore
        .collection(AppConstants.catsCollection)
        .where('familyId', isEqualTo: familyId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Returns true if user can add another cat (Pro or free with < 1 cat).
  Future<bool> canAddCat(String familyId, bool isPro) async {
    if (isPro) return true;
    final count = await countCatsInFamily(familyId);
    return count < AppConstants.freeMaxCats;
  }
}

