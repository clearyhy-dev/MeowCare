import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';
import 'user_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// 来自 `users/{uid}.notificationUnreadCount` 的实时未读数（仅服务端写入）。
final notificationUnreadCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .snapshots()
      .map((s) {
        final n = (s.data()?['notificationUnreadCount'] as num?)?.toInt() ?? 0;
        return n < 0 ? 0 : n;
      });
});

final notificationsListStreamProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});
