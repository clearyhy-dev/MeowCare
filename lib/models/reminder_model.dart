import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String catId;
  final int? dewormingCycleDays;
  final int? bathCycleDays;
  final DateTime? vaccineNextDate;
  final DateTime? nextReminderDate;
  final DateTime? updatedAt;

  const ReminderModel({
    required this.catId,
    this.dewormingCycleDays,
    this.bathCycleDays,
    this.vaccineNextDate,
    this.nextReminderDate,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'catId': catId,
      'dewormingCycleDays': dewormingCycleDays,
      'bathCycleDays': bathCycleDays,
      'vaccineNextDate': vaccineNextDate != null ? Timestamp.fromDate(vaccineNextDate!) : null,
      'nextReminderDate': nextReminderDate != null ? Timestamp.fromDate(nextReminderDate!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static ReminderModel fromMap(Map<String, dynamic> map, String catId) {
    final vaccineNext = map['vaccineNextDate'];
    final nextReminder = map['nextReminderDate'];
    final updated = map['updatedAt'];
    return ReminderModel(
      catId: catId,
      dewormingCycleDays: (map['dewormingCycleDays'] as num?)?.toInt(),
      bathCycleDays: (map['bathCycleDays'] as num?)?.toInt(),
      vaccineNextDate: vaccineNext is Timestamp ? vaccineNext.toDate() : null,
      nextReminderDate: nextReminder is Timestamp ? nextReminder.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
