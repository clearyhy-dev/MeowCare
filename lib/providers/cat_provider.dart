import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cat_model.dart';
import '../services/cat_service.dart';
import 'user_provider.dart';

final catServiceProvider = Provider<CatService>((ref) => CatService());

final currentFamilyCatsFutureProvider = FutureProvider<List<CatModel>>((ref) async {

  final familyId = ref.watch(currentUserAsyncProvider).valueOrNull?.familyId;
  if (familyId == null || familyId.isEmpty) return [];
  return ref.read(catServiceProvider).getCatsByFamilyId(familyId);
});

final singleCatProvider = FutureProvider.family<CatModel?, String>((ref, catId) async {
  return ref.read(catServiceProvider).getCat(catId);
});

