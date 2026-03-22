import '../core/constants/enums.dart';

/// 与后端 `/ai/symptom` 的 `advice_sections` 对应（snake_case 键由 [fromApiJson] 解析）。
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

  SymptomAdviceSections copyWith({
    String? summary,
    String? riskWarnings,
    String? homeCare,
    String? vetWhen,
    String? reassurance,
    String? disclaimer,
  }) {
    return SymptomAdviceSections(
      summary: summary ?? this.summary,
      riskWarnings: riskWarnings ?? this.riskWarnings,
      homeCare: homeCare ?? this.homeCare,
      vetWhen: vetWhen ?? this.vetWhen,
      reassurance: reassurance ?? this.reassurance,
      disclaimer: disclaimer ?? this.disclaimer,
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
    required this.sections,
    required this.detectedLanguage,
    required this.responseLanguage,
    required this.modelDisplayName,
    this.flatAdvice = '',
  });

  final SymptomAdviceSections sections;
  final String detectedLanguage;
  final String responseLanguage;
  final String modelDisplayName;

  /// 后端拼接的 `advice`（兼容旧客户端）；解析时可用于回填。
  final String flatAdvice;

  bool get hasUsableContent => sections.hasAnyNonEmpty;

  factory SymptomAdviceResult.fromApiJson(Map<String, dynamic> json, String modelDisplayName) {
    final sections = SymptomAdviceSections.fromApiJson(json['advice_sections']);
    final detected = '${json['detected_language'] ?? ''}'.trim().toLowerCase();
    final response = '${json['response_language'] ?? ''}'.trim().toLowerCase();
    final flat = '${json['advice'] ?? ''}'.trim();
    return SymptomAdviceResult(
      sections: sections,
      detectedLanguage: detected,
      responseLanguage: response,
      modelDisplayName: modelDisplayName,
      flatAdvice: flat,
    );
  }

  SymptomAdviceResult copyWith({
    SymptomAdviceSections? sections,
    String? detectedLanguage,
    String? responseLanguage,
    String? modelDisplayName,
    String? flatAdvice,
  }) {
    return SymptomAdviceResult(
      sections: sections ?? this.sections,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      responseLanguage: responseLanguage ?? this.responseLanguage,
      modelDisplayName: modelDisplayName ?? this.modelDisplayName,
      flatAdvice: flatAdvice ?? this.flatAdvice,
    );
  }

  /// 离线或解析失败时的结构化占位（按应用界面语言分支）。
  factory SymptomAdviceResult.offlineFallback({
    required String symptom,
    required Severity severity,
    required String appLanguageCode,
    required String modelDisplayName,
  }) {
    final sev = severity.value;
    final code = appLanguageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    switch (code) {
      case 'zh':
        return SymptomAdviceResult(
          sections: SymptomAdviceSections(
            summary: '当前无法连接 AI 服务。以下为占位说明，不能替代兽医诊断。症状：「$symptom」（严重程度：$sev）。',
            riskWarnings: '若出现呼吸困难、持续呕吐、精神萎靡、拒食超过 24 小时等情况，请尽快就医。',
            homeCare: '请保持环境安静、提供清水，观察症状变化并记录。',
            vetWhen: '症状加重或出现上述危险信号时，应立即联系兽医。',
            reassurance: '您已经在关注猫咪状况，这是很好的第一步。',
            disclaimer: '以上内容仅供教育参考，不能替代执业兽医的诊断与治疗建议。',
          ),
          detectedLanguage: '',
          responseLanguage: 'zh',
          modelDisplayName: modelDisplayName,
        );
      case 'ja':
        return SymptomAdviceResult(
          sections: SymptomAdviceSections(
            summary: 'AI に接続できません。以下は参考用で、獣医の診断の代わりにはなりません。症状：「$symptom」（程度：$sev）。',
            riskWarnings: '呼吸困難、嘔吐が続く、ぐったり、24時間以上食べないなどは早めに受診してください。',
            homeCare: '静かな環境と水を用意し、様子の変化を観察・記録してください。',
            vetWhen: '悪化したり危険なサインが出たら、すぐに獣医に相談してください。',
            reassurance: '様子を見てあげていること、それ自体が大切な一歩です。',
            disclaimer: '教育目的の情報であり、獣医師の診断・治療に代わるものではありません。',
          ),
          detectedLanguage: '',
          responseLanguage: 'ja',
          modelDisplayName: modelDisplayName,
        );
      case 'ko':
        return SymptomAdviceResult(
          sections: SymptomAdviceSections(
            summary: 'AI에 연결할 수 없습니다. 아래는 참고용이며 수의사 진단을 대체하지 않습니다. 증상: "$symptom" (심각도: $sev).',
            riskWarnings: '호흡 곤란, 구토 지속, 무기력, 24시간 이상 식욕 부진이 있으면 빨리 병원에 가세요.',
            homeCare: '조용한 환경과 물을 제공하고 증상 변화를 관찰·기록하세요.',
            vetWhen: '악화되거나 위험 신호가 보이면 즉시 수의사와 상담하세요.',
            reassurance: '지금 고양이 상태를 살펴보고 계신 것만으로도 큰 도움이 됩니다.',
            disclaimer: '교육 목적의 정보이며 면허 수의사의 진단·치료를 대체하지 않습니다.',
          ),
          detectedLanguage: '',
          responseLanguage: 'ko',
          modelDisplayName: modelDisplayName,
        );
      default:
        return SymptomAdviceResult(
          sections: SymptomAdviceSections(
            summary:
                'Unable to reach the AI service. This is placeholder guidance only, not veterinary diagnosis. Symptom: "$symptom" (severity: $sev).',
            riskWarnings:
                'Seek urgent care if you notice labored breathing, repeated vomiting, extreme lethargy, or no eating for over 24 hours.',
            homeCare: 'Keep the environment calm, offer fresh water, and watch for changes; note what you observe.',
            vetWhen: 'Contact a veterinarian promptly if symptoms worsen or red flags appear.',
            reassurance: 'Noticing something is off and checking in is already an important step.',
            disclaimer:
                'For education only; not a substitute for diagnosis or treatment by a licensed veterinarian.',
          ),
          detectedLanguage: '',
          responseLanguage: 'en',
          modelDisplayName: modelDisplayName,
        );
    }
  }
}
