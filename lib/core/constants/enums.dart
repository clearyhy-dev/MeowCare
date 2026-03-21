/// Subscription tier.
enum SubscriptionStatus {
  free,
  pro;

  String get value => name;
  static SubscriptionStatus fromString(String? v) {
    if (v == 'pro') return SubscriptionStatus.pro;
    return SubscriptionStatus.free;
  }
}

/// Family member role.
enum FamilyRole {
  owner,
  member;

  String get value => name;
  static FamilyRole fromString(String? v) {
    if (v == 'owner') return FamilyRole.owner;
    return FamilyRole.member;
  }
}

/// Cat activity level.
enum ActivityLevel {
  low,
  medium,
  high;

  String get value => name;
  static ActivityLevel fromString(String? v) {
    switch (v) {
      case 'medium':
        return ActivityLevel.medium;
      case 'high':
        return ActivityLevel.high;
      default:
        return ActivityLevel.low;
    }
  }
}

/// Task type (daily care).
enum TaskType {
  feed,
  water,
  litter,
  grooming,
  bath,
  deworm,
  vaccine;

  String get value => name;
  static TaskType fromString(String? v) {
    for (final e in TaskType.values) {
      if (e.value == v) return e;
    }
    return TaskType.feed;
  }
}

/// Task repeat pattern.
enum RepeatType {
  daily,
  weekly,
  monthly,
  custom;

  String get value => name;
  static RepeatType fromString(String? v) {
    switch (v) {
      case 'weekly':
        return RepeatType.weekly;
      case 'monthly':
        return RepeatType.monthly;
      case 'custom':
        return RepeatType.custom;
      default:
        return RepeatType.daily;
    }
  }
}

/// Health log type.
enum HealthLogType {
  weight,
  deworm,
  vaccine,
  note;

  String get value => name;
  static HealthLogType fromString(String? v) {
    switch (v) {
      case 'deworm':
        return HealthLogType.deworm;
      case 'vaccine':
        return HealthLogType.vaccine;
      case 'note':
        return HealthLogType.note;
      default:
        return HealthLogType.weight;
    }
  }
}

/// AI request severity.
enum Severity {
  green,
  yellow,
  red;

  String get value => name;
  static Severity fromString(String? v) {
    if (v == 'yellow') return Severity.yellow;
    if (v == 'red') return Severity.red;
    return Severity.green;
  }
}
