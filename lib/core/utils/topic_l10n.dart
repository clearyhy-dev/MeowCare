import 'package:flutter/material.dart';

import 'l10n_ext.dart';

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

/// Feed 卡片分类：已知 topic 走 l10n，其余转为可读英文式标题（如 senior_cat → Senior cat）。
String feedTopicCategoryLabel(BuildContext context, String topicKey) {
  switch (topicKey) {
    case 'care':
    case 'health':
    case 'feeding':
    case 'behavior':
      return topicLabel(context, topicKey);
    case 'grooming':
      return 'Grooming';
    case 'kitten':
      return 'Kitten';
    case 'senior_cat':
      return 'Senior cat';
    case 'indoor_cat':
      return 'Indoor cat';
    case 'hydration':
      return 'Hydration';
    case 'litter_box':
      return 'Litter box';
    default:
      return _snakeCaseToDisplayTitle(topicKey);
  }
}

String _snakeCaseToDisplayTitle(String key) {
  if (key.isEmpty) return key;
  return key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}')
      .join(' ');
}
