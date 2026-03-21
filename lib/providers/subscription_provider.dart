import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../services/subscription_service.dart';
import 'user_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) => SubscriptionService());

final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return SubscriptionStatus.free;
  return ref.read(subscriptionServiceProvider).getStatus(uid);
});
