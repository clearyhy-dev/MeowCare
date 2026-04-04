# -*- coding: utf-8 -*-
"""One-off: add community hub l10n keys to all app_*.arb files."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "l10n"

EN_EXTRA = {
    "communityHubTitle": "Community hub",
    "communityHubSubtitle": "Manage your posts, notifications, and social preferences",
    "communityHubPostsSubtitle": "Drafts, pending, and published",
    "communityHubCommentsSubtitle": "Threads and replies you joined",
    "communityHubSavedSubtitle": "Posts you saved for later",
    "communityHubNotificationsSubtitle": "Likes, comments, and mentions",
    "communityHubPreferencesSubtitle": "Defaults for your community experience",
    "communityHubLanguageSubtitle": "App language and formats",
    "communityHubBlockedSubtitle": "Muted people and hidden content",
    "communityHubGuidelinesSubtitle": "Safety, respect, and help",
    "communityPreferencesTitle": "Community preferences",
    "communityPreferencesSubtitle": "Tune how MeowCare feels in the feed. More options will roll out here.",
    "communityComingSoon": "Coming soon",
    "communityBlockedTitle": "Blocked & hidden",
    "communityBlockedBody": "You'll be able to manage blocked users and hidden posts here in a future update.",
    "communityGuidelinesTitle": "Community guidelines",
    "communityGuidelinesLead": "MeowCare is a kind space for cat parents. Help us keep it welcoming for everyone.",
    "communityGuidelinesP1": "Be respectful. Debate ideas, not people. No harassment, hate, or targeted attacks.",
    "communityGuidelinesP2": "Share accurate, safe pet care info. This app does not replace a veterinarian for medical decisions.",
    "communityGuidelinesP3": "No spam, scams, or misleading links. Report content that breaks these rules.",
    "settingsSectionShare": "Share & support",
    "settingsSectionAccount": "Account & billing",
}

ZH_EXTRA = {
    "communityHubTitle": "社区中心",
    "communityHubSubtitle": "管理帖子、通知与社区偏好",
    "communityHubPostsSubtitle": "草稿、待审与已发布",
    "communityHubCommentsSubtitle": "你参与的讨论与回复",
    "communityHubSavedSubtitle": "稍后阅读的收藏帖子",
    "communityHubNotificationsSubtitle": "点赞、评论与提及",
    "communityHubPreferencesSubtitle": "社区与动态默认体验",
    "communityHubLanguageSubtitle": "应用语言与格式",
    "communityHubBlockedSubtitle": "屏蔽用户与隐藏内容",
    "communityHubGuidelinesSubtitle": "安全、尊重与帮助",
    "communityPreferencesTitle": "社区偏好",
    "communityPreferencesSubtitle": "调整动态与社区体验，更多选项将陆续推出。",
    "communityComingSoon": "即将推出",
    "communityBlockedTitle": "屏蔽与隐藏",
    "communityBlockedBody": "后续可在此管理屏蔽用户与隐藏内容。",
    "communityGuidelinesTitle": "社区准则",
    "communityGuidelinesLead": "MeowCare 希望成为友善的养猫社区，请一起维护良好氛围。",
    "communityGuidelinesP1": "保持尊重：就事论事，不人身攻击、不骚扰、不仇恨言论。",
    "communityGuidelinesP2": "分享真实、安全的养宠信息；应用不能替代兽医的专业诊疗。",
    "communityGuidelinesP3": "禁止垃圾信息、诈骗与误导链接；发现违规内容请举报。",
    "settingsSectionShare": "分享与支持",
    "settingsSectionAccount": "账户与订阅",
}


def main() -> None:
    for path in sorted(ROOT.glob("app_*.arb")):
        locale = path.stem.replace("app_", "")
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        extra = ZH_EXTRA if locale == "zh" else EN_EXTRA
        for k, v in extra.items():
            data[k] = v
        with path.open("w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("patched", path.name)


if __name__ == "__main__":
    main()
