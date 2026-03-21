import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/cat_model.dart';

class CatRepository {
  CatRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<({List<CatModel> list, DocumentSnapshot? lastDoc})> getMyCats({
    required String uid,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.catsCollection)
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => CatModel.fromMap(d.data(), d.id)).toList();
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: list, lastDoc: lastDoc);
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
}
