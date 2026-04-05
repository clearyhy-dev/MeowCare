import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';
import '../core/utils/date_utils.dart';
import '../models/health_model.dart';
import '../models/symptom_advice_result.dart';

/// 当前使用的 AI 模型显示名（与后端一致，无后端时展示用）
const String kAIModelDisplayName = 'Gemini 2.5 Flash';

/// 可识别的 AI 请求失败（用于界面区分重试与文案）。
class AIServiceException implements Exception {
  AIServiceException(this.kind, [this.detail]);
  final AIServiceErrorKind kind;
  final String? detail;

  @override
  String toString() => 'AIServiceException($kind, $detail)';
}

enum AIServiceErrorKind {
  unauthorized,
  timeout,
  network,
  httpError,
}

class AIService {
  AIService._();
  static final AIService _instance = AIService._();
  factory AIService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Duration _kSymptomTimeout = Duration(seconds: 55);

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

  /// Uses backend `/ai/symptom` with BCP 47 [localeTag], [appLanguage] (UI code), optional [userLanguageHint].
  /// Throws [AIServiceException] on network/timeout/auth; returns structured or offline fallback when HTTP 200 but empty.
  Future<SymptomAdviceResult> getAIResponse(
    String requestId,
    String symptom,
    Severity severity, {
    required String localeTag,
    required String appLanguage,
    String userLanguageHint = '',
  }) async {
    final baseUrl = AppConstants.backendBaseUrl;
    final appLang = appLanguage.trim().isEmpty ? 'en' : appLanguage.trim().toLowerCase();

    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      return SymptomAdviceResult.offlineFallback(
        symptom: symptom,
        severity: severity,
        appLanguageCode: appLang,
        modelDisplayName: kAIModelDisplayName,
      );
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) {
      throw AIServiceException(AIServiceErrorKind.unauthorized);
    }

    final uri = Uri.parse('$baseUrl/ai/symptom');
    final tag = localeTag.trim().isEmpty ? 'en' : localeTag.trim();

    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'symptom': symptom,
              'severity': severity.value,
              'locale': tag,
              'app_language': appLang,
              'user_language': userLanguageHint.trim(),
            }),
          )
          .timeout(_kSymptomTimeout);

      if (res.statusCode != 200) {
        throw AIServiceException(
          AIServiceErrorKind.httpError,
          'HTTP ${res.statusCode}',
        );
      }

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        data = null;
      }
      if (data == null) {
        return SymptomAdviceResult.offlineFallback(
          symptom: symptom,
          severity: severity,
          appLanguageCode: appLang,
          modelDisplayName: kAIModelDisplayName,
        );
      }

      final modelName = _formatModelName(data['model'] as String?);
      var parsed = SymptomAdviceResult.fromApiJson(
        data,
        modelName,
        userSeverity: severity,
      );

      if (!parsed.hasUsableContent) {
        final flat = parsed.flatAdvice.isNotEmpty ? parsed.flatAdvice : (data['advice'] as String? ?? '');
        if (flat.trim().isNotEmpty) {
          parsed = parsed.copyWith(
            analysis: parsed.analysis.copyWith(
              summary: flat.trim(),
            ),
          );
        }
      }

      if (parsed.hasUsableContent) {
        return parsed;
      }

      return SymptomAdviceResult.offlineFallback(
        symptom: symptom,
        severity: severity,
        appLanguageCode: appLang,
        modelDisplayName: modelName,
      );
    } on TimeoutException {
      throw AIServiceException(AIServiceErrorKind.timeout);
    } on AIServiceException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('network is unreachable') ||
          msg.contains('connection refused') ||
          msg.contains('connection reset')) {
        throw AIServiceException(AIServiceErrorKind.network, '$e');
      }
      throw AIServiceException(AIServiceErrorKind.httpError, '$e');
    }
  }

  static String _formatModelName(String? raw) {
    if (raw == null || raw.isEmpty) return kAIModelDisplayName;
    if (raw == 'gemini-2.5-flash') return 'Gemini 2.5 Flash';
    if (raw == 'gemini-2.0-flash') return 'Gemini 2.0 Flash';
    if (raw == 'gemini-1.5-flash') return 'Gemini 1.5 Flash';

    return raw;
  }
}
