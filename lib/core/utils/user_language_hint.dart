/// 根据输入文本做轻量脚本启发，供后端 [user_language] 参考。
///
/// **仅作提示**：最终语言以后端/模型从症状文本判断为准；空字符串表示不额外提示。
String userLanguageHintFromText(String text) {
  final t = text.trim();
  if (t.isEmpty) return '';

  var cjk = 0;
  var hangul = 0;
  var kana = 0;
  var latin = 0;
  for (final r in t.runes) {
    if (_isHangulRune(r)) {
      hangul++;
    } else if (_isKanaRune(r)) {
      kana++;
    } else if (_isCjkUnifiedRune(r)) {
      cjk++;
    } else if (_isLatinLetterRune(r)) {
      latin++;
    }
  }

  final scored = cjk + hangul + kana + latin;
  if (scored == 0) return '';

  if (hangul / scored >= 0.25) return 'ko';
  if ((kana / scored >= 0.12) && (kana + cjk) > latin) return 'ja';
  if (cjk / scored >= 0.2) return 'zh';
  if (latin / scored >= 0.45) return 'en';

  return '';
}

bool _isCjkUnifiedRune(int r) =>
    (r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF) || (r >= 0x20000 && r <= 0x2A6DF);

bool _isKanaRune(int r) =>
    (r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF) || (r >= 0x31F0 && r <= 0x31FF);

bool _isHangulRune(int r) => (r >= 0xAC00 && r <= 0xD7AF) || (r >= 0x1100 && r <= 0x11FF);

bool _isLatinLetterRune(int r) =>
    (r >= 0x0041 && r <= 0x005A) || (r >= 0x0061 && r <= 0x007A) || (r >= 0x00C0 && r <= 0x024F);
