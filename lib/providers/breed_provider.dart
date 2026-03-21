import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/breed_repository.dart';
import '../models/breed_model.dart';

final breedRepositoryProvider = Provider<BreedRepository>((ref) => BreedRepository());

final breedsFutureProvider = FutureProvider<List<BreedModel>>((ref) async {
  return ref.read(breedRepositoryProvider).getBreeds();
});

