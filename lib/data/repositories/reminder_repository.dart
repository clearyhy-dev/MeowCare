import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/reminder_model.dart';

class ReminderRepository {
  ReminderRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ReminderModel?> getReminder(String catId) async {
    final doc = await _firestore.collection(AppConstants.remindersCollection).doc(catId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReminderModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> setReminder(ReminderModel reminder) async {
    await _firestore.collection(AppConstants.remindersCollection).doc(reminder.catId).set(reminder.toMap());
  }

  /// Fetch reminders whose nextReminderDate is today (for "today's todos").
  Future<List<ReminderModel>> getRemindersDueToday(String ownerId) async {
    final catsSnap = await _firestore
        .collection(AppConstants.catsCollection)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    final catIds = catsSnap.docs.map((d) => d.id).toList();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final list = <ReminderModel>[];
    for (final catId in catIds) {
      final rem = await getReminder(catId);
      if (rem?.nextReminderDate != null) {
        final d = rem!.nextReminderDate!;
        if (!d.isBefore(startOfDay) && d.isBefore(endOfDay)) {
          list.add(rem);
        }
      }
    }
    return list;
  }
}

