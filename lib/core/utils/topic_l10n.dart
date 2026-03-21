import 'package:flutter/material.dart';

import '../utils/l10n_ext.dart';

/// 话题 key：care, health, feeding, behavior（与 Firestore 存储一致）
/// 返回当前语言下的展示文案。
String topicLabel(BuildContext context, String topicKey) {
  final l10n = context.l10n;
  switch (topicKey) {
    case 'care':
      return l10n.topicCare;
    case 'health':
      return l10n.topicHealth;
    case 'feeding':
      return l10n.topicFeeding;
    case 'behavior':
      return l10n.topicBehavior;
    default:
      return topicKey;
  }
}

