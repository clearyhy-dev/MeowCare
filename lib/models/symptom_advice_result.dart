import '../core/constants/enums.dart';

/// 后端 `/ai/symptom` 返回的结构化分析（与 API snake_case 对齐，由 [SymptomAdviceResult.fromApiJson] 解析）。
class SymptomAnalysis {
  const SymptomAnalysis({
    required this.severity,
    required this.summary,
    required this.possibleCauses,
    required this.watchAtHome,
    required this.seekVetNow,
    required this.nextQuestions,
    required this.disclaimer,
  });

  final Severity severity;
  final String summary;
  final List<String> possibleCauses;
  final String watchAtHome;
  final String seekVetNow;
  final List<String> nextQuestions;
  final String disclaimer;

  static const SymptomAnalysis empty = SymptomAnalysis(
    severity: Severity.green,
    summary: '',
    possibleCauses: [],
    watchAtHome: '',
    seekVetNow: '',
    nextQuestions: [],
    disclaimer: '',
  );

  bool get hasAnyNonEmpty =>
      summary.isNotEmpty ||
      possibleCauses.isNotEmpty ||
      watchAtHome.isNotEmpty ||
      seekVetNow.isNotEmpty ||
      nextQuestions.isNotEmpty ||
      disclaimer.isNotEmpty;

  SymptomAnalysis copyWith({
    Severity? severity,
    String? summary,
    List<String>? possibleCauses,
    String? watchAtHome,
    String? seekVetNow,
    List<String>? nextQuestions,
    String? disclaimer,
  }) {
    return SymptomAnalysis(
      severity: severity ?? this.severity,
      summary: summary ?? this.summary,
      possibleCauses: possibleCauses ?? this.possibleCauses,
      watchAtHome: watchAtHome ?? this.watchAtHome,
      seekVetNow: seekVetNow ?? this.seekVetNow,
      nextQuestions: nextQuestions ?? this.nextQuestions,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  static Severity _parseSeverity(dynamic raw, Severity fallback) {
    final s = '${raw ?? ''}'.trim().toLowerCase();
    if (s == 'yellow' || s == 'moderate') return Severity.yellow;
    if (s == 'red' || s == 'urgent') return Severity.red;
    if (s == 'green' || s == 'mild') return Severity.green;
    return fallback;
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return [];
  }

  /// 优先解析顶层结构化字段；否则从 [advice_sections] 或 [legacySections] 回填。
  factory SymptomAnalysis.fromApiJson(
    Map<String, dynamic> json, {
    required Severity userSeverity,
    SymptomAdviceSections? legacySections,
  }) {
    final summary = '${json['summary'] ?? ''}'.trim();
    final causes = _stringList(json['possible_causes']);
    final watch = '${json['watch_at_home'] ?? ''}'.trim();
    final vet = '${json['seek_vet_now'] ?? ''}'.trim();
    final nq = _stringList(json['next_questions']);
    final dis = '${json['disclaimer'] ?? ''}'.trim();
    final sev = _parseSeverity(json['severity'], userSeverity);

    if (summary.isNotEmpty ||
        causes.isNotEmpty ||
        watch.isNotEmpty ||
        vet.isNotEmpty ||
        nq.isNotEmpty ||
        dis.isNotEmpty) {
      return SymptomAnalysis(
        severity: sev,
        summary: summary,
        possibleCauses: causes,
        watchAtHome: watch,
        seekVetNow: vet,
        nextQuestions: nq,
        disclaimer: dis,
      );
    }

    final leg = legacySections;
    if (leg != null && leg.hasAnyNonEmpty) {
      final riskParts = leg.riskWarnings.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return SymptomAnalysis(
        severity: userSeverity,
        summary: leg.summary,
        possibleCauses: riskParts,
        watchAtHome: leg.homeCare,
        seekVetNow: leg.vetWhen,
        nextQuestions: const [],
        disclaimer: leg.disclaimer,
      );
    }

    return SymptomAnalysis.empty;
  }
}

/// 兼容旧版 `advice_sections`（后端仍可能附带）。
class SymptomAdviceSections {
  const SymptomAdviceSections({
    required this.summary,
    required this.riskWarnings,
    required this.homeCare,
    required this.vetWhen,
    required this.reassurance,
    required this.disclaimer,
  });

  final String summary;
  final String riskWarnings;
  final String homeCare;
  final String vetWhen;
  final String reassurance;
  final String disclaimer;

  static const SymptomAdviceSections empty = SymptomAdviceSections(
    summary: '',
    riskWarnings: '',
    homeCare: '',
    vetWhen: '',
    reassurance: '',
    disclaimer: '',
  );

  static String _pick(Map<String, dynamic> m, String snake, String camel) {
    final a = m[snake];
    final b = m[camel];
    final s = (a != null && '$a'.trim().isNotEmpty) ? '$a' : (b != null ? '$b' : '');
    return s.trim();
  }

  factory SymptomAdviceSections.fromApiJson(dynamic raw) {
    if (raw is! Map) return SymptomAdviceSections.empty;
    final m = Map<String, dynamic>.from(raw);
    return SymptomAdviceSections(
      summary: _pick(m, 'summary', 'summary'),
      riskWarnings: _pick(m, 'risk_warnings', 'riskWarnings'),
      homeCare: _pick(m, 'home_care', 'homeCare'),
      vetWhen: _pick(m, 'vet_when', 'vetWhen'),
      reassurance: _pick(m, 'reassurance', 'reassurance'),
      disclaimer: _pick(m, 'disclaimer', 'disclaimer'),
    );
  }

  bool get hasAnyNonEmpty =>
      summary.isNotEmpty ||
      riskWarnings.isNotEmpty ||
      homeCare.isNotEmpty ||
      vetWhen.isNotEmpty ||
      reassurance.isNotEmpty ||
      disclaimer.isNotEmpty;
}

class SymptomAdviceResult {
  const SymptomAdviceResult({
    required this.analysis,
    required this.detectedLanguage,
    required this.responseLanguage,
    required this.modelDisplayName,
    this.flatAdvice = '',
    this.apiOk = true,
    this.apiFallback = false,
    this.errorDetail,
  });

  final SymptomAnalysis analysis;
  final String detectedLanguage;
  final String responseLanguage;
  final String modelDisplayName;
  final String flatAdvice;
  final bool apiOk;
  final bool apiFallback;
  final String? errorDetail;

  bool get hasUsableContent => analysis.hasAnyNonEmpty;

  factory SymptomAdviceResult.fromApiJson(
    Map<String, dynamic> json,
    String modelDisplayName, {
    required Severity userSeverity,
  }) {
    final legacy = SymptomAdviceSections.fromApiJson(json['advice_sections']);
    final analysis = SymptomAnalysis.fromApiJson(
      json,
      userSeverity: userSeverity,
      legacySections: legacy.hasAnyNonEmpty ? legacy : null,
    );
    final detected = '${json['detected_language'] ?? ''}'.trim().toLowerCase();
    final response = '${json['response_language'] ?? ''}'.trim().toLowerCase();
    final flat = '${json['advice'] ?? ''}'.trim();
    final ok = json['ok'] as bool? ?? true;
    final fallback = json['fallback'] as bool? ?? false;
    final err = json['error_detail'] as String?;
    return SymptomAdviceResult(
      analysis: analysis,
      detectedLanguage: detected,
      responseLanguage: response.isNotEmpty ? response : detected,
      modelDisplayName: modelDisplayName,
      flatAdvice: flat,
      apiOk: ok,
      apiFallback: fallback,
      errorDetail: err,
    );
  }

  SymptomAdviceResult copyWith({
    SymptomAnalysis? analysis,
    String? detectedLanguage,
    String? responseLanguage,
    String? modelDisplayName,
    String? flatAdvice,
    bool? apiOk,
    bool? apiFallback,
    String? errorDetail,
    bool clearErrorDetail = false,
  }) {
    return SymptomAdviceResult(
      analysis: analysis ?? this.analysis,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      responseLanguage: responseLanguage ?? this.responseLanguage,
      modelDisplayName: modelDisplayName ?? this.modelDisplayName,
      flatAdvice: flatAdvice ?? this.flatAdvice,
      apiOk: apiOk ?? this.apiOk,
      apiFallback: apiFallback ?? this.apiFallback,
      errorDetail: clearErrorDetail ? null : (errorDetail ?? this.errorDetail),
    );
  }

  factory SymptomAdviceResult.offlineFallback({
    required String symptom,
    required Severity severity,
    required String appLanguageCode,
    required String modelDisplayName,
  }) {
    final sev = severity;
    final code = appLanguageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    switch (code) {
      case 'zh':
        return SymptomAdviceResult(
          analysis: SymptomAnalysis(
            severity: sev,
            summary:
                '当前无法连接 AI 服务。以下为占位说明，不能替代兽医诊断。症状：「$symptom」（您选择的风险等级：${sev.value}）。',
            possibleCauses: const ['环境或饮食因素', '轻度应激或胃肠不适', '需结合个体情况判断'],
            watchAtHome: '请保持环境安静、提供清水，观察食欲、精神、呕吐与排便；避免自行用药。',
            seekVetNow: '若出现呼吸困难、持续呕吐、精神极差、超过 24 小时拒食、排尿困难或疼痛明显加重，请尽快就医。',
            nextQuestions: const ['症状从何时开始？', '是否有新食物或新环境变化？'],
            disclaimer: '以上内容仅供教育参考，不能替代执业兽医的诊断与治疗建议。',
          ),
          detectedLanguage: '',
          responseLanguage: 'zh',
          modelDisplayName: modelDisplayName,
          apiOk: false,
          apiFallback: true,
          errorDetail: 'offline',
        );
      case 'ja':
        return SymptomAdviceResult(
          analysis: SymptomAnalysis(
            severity: sev,
            summary:
                'AI に接続できません。以下は参考用で、獣医の診断の代わりにはなりません。症状：「$symptom」（程度：${sev.value}）。',
            possibleCauses: const ['環境・食事要因', '軽いストレスや胃腸の不調', '個体差あり'],
            watchAtHome: '静かな環境と水を確保し、食欲・精神・嘔吐・排泄を観察してください。',
            seekVetNow: '呼吸困難、嘔吐が続く、極度の無気力、24 時間以上拒食などは早めに受診してください。',
            nextQuestions: const ['いつから症状がありますか？', '変化のあった食物や環境はありますか？'],
            disclaimer: '教育目的の情報であり、獣医師の診断・治療に代わるものではありません。',
          ),
          detectedLanguage: '',
          responseLanguage: 'ja',
          modelDisplayName: modelDisplayName,
          apiOk: false,
          apiFallback: true,
          errorDetail: 'offline',
        );
      case 'ko':
        return SymptomAdviceResult(
          analysis: SymptomAnalysis(
            severity: sev,
            summary:
                'AI에 연결할 수 없습니다. 아래는 참고용이며 수의사 진단을 대체하지 않습니다. 증상: "$symptom" (심각도: ${sev.value}).',
            possibleCauses: const ['환경·식이 요인', '가벼운 스트레스나 소화기 불편', '개체차 있음'],
            watchAtHome: '조용한 환경과 물을 제공하고 식욕·활력·구토·배변을 관찰하세요.',
            seekVetNow: '호흡 곤란, 구토 지속, 심한 무기력, 24시간 이상 식욕 부진 시 빨리 병원에 가세요.',
            nextQuestions: const ['언제부터 증상이 있나요?', '새 사료나 환경 변화가 있었나요?'],
            disclaimer: '교육 목적의 정보이며 면허 수의사의 진단·치료를 대체하지 않습니다.',
          ),
          detectedLanguage: '',
          responseLanguage: 'ko',
          modelDisplayName: modelDisplayName,
          apiOk: false,
          apiFallback: true,
          errorDetail: 'offline',
        );
      default:
        return SymptomAdviceResult(
          analysis: SymptomAnalysis(
            severity: sev,
            summary:
                'Unable to reach the AI service. This is placeholder guidance only, not veterinary diagnosis. Symptom: "$symptom" (level: ${sev.value}).',
            possibleCauses: const [
              'Environmental or dietary factors',
              'Mild stress or GI upset',
              'Varies by individual',
            ],
            watchAtHome:
                'Keep the environment calm, offer fresh water, and monitor appetite, energy, vomiting, and litter habits.',
            seekVetNow:
                'Seek urgent care for labored breathing, repeated vomiting, severe lethargy, no eating 24h+, trouble urinating, or worsening pain.',
            nextQuestions: const ['When did this start?', 'Any new food or stressors?'],
            disclaimer:
                'For education only; not a substitute for diagnosis or treatment by a licensed veterinarian.',
          ),
          detectedLanguage: '',
          responseLanguage: 'en',
          modelDisplayName: modelDisplayName,
          apiOk: false,
          apiFallback: true,
          errorDetail: 'offline',
        );
    }
  }
}
