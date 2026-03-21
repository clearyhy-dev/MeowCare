import '../../generated/l10n/app_localizations.dart';

/// Feed / 详情语言角标与设置页展示名（文案来自 arb）。
class AppLanguageDisplay {
  AppLanguageDisplay._();

  static String chipLabel(String code, AppLocalizations l10n) {
    switch (code.trim().toLowerCase()) {
      case 'en':
        return l10n.languageTagEn;
      case 'zh':
        return l10n.languageTagZh;
      case 'ja':
        return l10n.languageTagJa;
      case 'es':
        return l10n.languageTagEs;
      case 'fr':
        return l10n.languageTagFr;
      case 'de':
        return l10n.languageTagDe;
      case 'pt':
        return l10n.languageTagPt;
      case 'ru':
        return l10n.languageTagRu;
      case 'ko':
        return l10n.languageTagKo;
      default:
        return code.trim().toUpperCase();
    }
  }

  static String fullName(String code, AppLocalizations l10n) {
    switch (code.trim().toLowerCase()) {
      case 'en':
        return l10n.languageNameEn;
      case 'zh':
        return l10n.languageNameZh;
      case 'ja':
        return l10n.languageNameJa;
      case 'es':
        return l10n.languageNameEs;
      case 'fr':
        return l10n.languageNameFr;
      case 'de':
        return l10n.languageNameDe;
      case 'pt':
        return l10n.languageNamePt;
      case 'ru':
        return l10n.languageNameRu;
      case 'ko':
        return l10n.languageNameKo;
      default:
        return code;
    }
  }
}
