import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_model.dart';
import '../services/family_service.dart';
import 'user_provider.dart';

final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService());

final currentFamilyIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserAsyncProvider).valueOrNull?.familyId;
});

final currentFamilyProvider = FutureProvider<FamilyModel?>((ref) async {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null || familyId.isEmpty) return null;
  return ref.read(familyServiceProvider).getFamily(familyId);
});

final familyMembersProvider = FutureProvider.family<List<FamilyMemberModel>, String>((ref, familyId) async {
  return ref.read(familyServiceProvider).getMembers(familyId);
});
