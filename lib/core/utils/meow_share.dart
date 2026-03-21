import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import 'l10n_ext.dart';

/// App 与帖子分享（share_plus），文案走 l10n，链接走 [AppConstants] 可配置占位。
class MeowShare {
  MeowShare._();

  static Future<void> shareApp(BuildContext context) async {
    final l10n = context.l10n;
    await Share.share(
      l10n.shareAppBody(AppConstants.appDownloadUrl),
      subject: l10n.shareAppSubject,
    );
  }

  static Future<void> sharePost(
    BuildContext context, {
    required String postId,
    required String title,
  }) async {
    final l10n = context.l10n;
    final url = AppConstants.postShareUrl(postId);
    final b = StringBuffer(title);
    b.write('\n\n');
    b.write(l10n.sharePostLinkLine(url));
    b.write('\n\n');
    b.write(l10n.shareFromMeowCare);
    await Share.share(b.toString(), subject: title);
  }
}
