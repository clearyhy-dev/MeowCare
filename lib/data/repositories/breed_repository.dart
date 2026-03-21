import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/breed_model.dart';

class BreedRepository {
  BreedRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<BreedModel>> getBreeds() async {
    final snap = await _firestore
        .collection(AppConstants.breedsCollection)
        .where('enabled', isEqualTo: true)
        .get();
    final list = snap.docs.map((d) => BreedModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}
