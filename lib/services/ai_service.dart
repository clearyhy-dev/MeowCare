import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';
import '../core/utils/date_utils.dart';
import '../models/health_model.dart';

/// 当前使用的 AI 模型显示名（与后端一致，无后端时展示用）
const String kAIModelDisplayName = 'Gemini 2.5 Flash';

class AIService {
  AIService._();
  static final AIService _instance = AIService._();
  factory AIService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns (canRequest, todayCount). Free users limited to freeAiRequestsPerDay per day.
  Future<({bool canRequest, int todayCount})> checkCanRequestAI(String uid, bool isPro) async {
    if (isPro) return (canRequest: true, todayCount: 0);
    final start = AppDateUtils.startOfToday();
    final end = AppDateUtils.endOfToday();
    final snap = await _firestore
        .collection(AppConstants.aiRequestsCollection)
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .count()
        .get();
    final count = snap.count ?? 0;

    return (canRequest: count < AppConstants.freeAiRequestsPerDay, todayCount: count);
  }

  Future<AIRequestModel> submitRequest(String uid, String symptom, Severity severity) async {
    final ref = _firestore.collection(AppConstants.aiRequestsCollection).doc();
    final request = AIRequestModel(
      requestId: ref.id,
      uid: uid,
      symptom: symptom,
      severity: severity,
      createdAt: DateTime.now(),
    );
    await ref.set(request.toMap());
    return request;
  }

  /// Returns (advice, modelDisplayName). Uses backend /ai/symptom with [locale] for language-matched advice; fallback to localized mock if backend unavailable.
  Future<({String advice, String modelDisplayName})> getAIResponse(
    String requestId,
    String symptom,
    Severity severity, {
    required String locale,
  }) async {
    final baseUrl = AppConstants.backendBaseUrl;
    if (baseUrl.isNotEmpty) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null) {
        try {
          final uri = Uri.parse('$baseUrl/ai/symptom');
          final res = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'symptom': symptom,
              'severity': severity.value,
              'locale': locale.isEmpty ? 'en' : locale,
            }),
          );
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>?;
            final advice = data?['advice'] as String? ?? '';
            final model = data?['model'] as String?;
            if (advice.isNotEmpty) {
              return (advice: advice, modelDisplayName: _formatModelName(model));
            }
          } else {
            final msg = res.body.isNotEmpty ? res.body : 'HTTP ${res.statusCode}';
            throw Exception(msg);
          }
        } catch (e) {
          rethrow;
        }

      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return (
      advice: _fallbackAdvice(symptom, severity, locale),
      modelDisplayName: kAIModelDisplayName,
    );
  }

  static String _formatModelName(String? raw) {
    if (raw == null || raw.isEmpty) return kAIModelDisplayName;
    if (raw == 'gemini-2.5-flash') return 'Gemini 2.5 Flash';
    if (raw == 'gemini-2.0-flash') return 'Gemini 2.0 Flash';
    if (raw == 'gemini-1.5-flash') return 'Gemini 1.5 Flash';


    return raw;
  }

  static String _fallbackAdvice(String symptom, Severity severity, String locale) {
    final severityStr = severity.value;
    if (locale.startsWith('zh')) {
      return '以上仅供参考，不能替代兽医诊断。症状：“$symptom”（严重程度：$severityStr）。建议尽快咨询兽医以获取正确诊断。';
    }
    if (locale.startsWith('ja')) {
      return '参考までです。獣医の診断の代わりにはなりません。症状：「$symptom」（程度：$severityStr）。獣医にご相談ください。';
    }
    if (locale.startsWith('ko')) {
      return '참고용이며 수의사 진단을 대체하지 않습니다. 증상: "$symptom" (심각도: $severityStr). 수의사 상담을 권합니다.';
    }
    return 'This is informational guidance only, not a substitute for veterinary care. '
        'For symptom: "$symptom" (severity: $severityStr), please consider consulting a veterinarian for proper diagnosis.';
  }
}

