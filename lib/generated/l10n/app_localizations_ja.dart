// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => '家族でねこの食事・健康リマインダー';

  @override
  String get feed => 'ごはん';

  @override
  String get water => '水の交換';

  @override
  String get litter => 'トイレ掃除';

  @override
  String get grooming => 'ブラッシング';

  @override
  String get bath => 'お風呂';

  @override
  String get deworm => '駆虫';

  @override
  String get vaccine => 'ワクチン';

  @override
  String get addCat => 'ねこを追加';

  @override
  String get addFirstCat => '最初のねこを追加';

  @override
  String get editCat => 'ねこを編集';

  @override
  String get todayCare => '今日のお世話';

  @override
  String get markDone => '完了';

  @override
  String get allTasks => 'すべてのタスク';

  @override
  String get noTasksYet => 'タスクがまだありません。ねこを追加してタスクを作成しましょう。';

  @override
  String get aiSymptomSupport => 'AI 症状サポート';

  @override
  String aiTitleWithName(String catName) {
    return '$catNameの調子はどうですか？';
  }

  @override
  String get aiTitleGeneric => 'どうされましたか？';

  @override
  String get aiSubtitle => '情報提供のみです。獣医師の診療に代わるものではありません。';

  @override
  String get aiHint => '例：くしゃみ、食欲不振';

  @override
  String get getGuidance => 'アドバイスを見る';

  @override
  String get guidance => 'アドバイス';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get signIn => 'ログイン';

  @override
  String get signInWithGoogle => 'Googleでログイン';

  @override
  String get register => '登録';

  @override
  String get createFamily => 'ファミリーを作成';

  @override
  String get createFamilyDesc => 'ファミリーを作成して、ねこのお世話を家族で共有しましょう。';

  @override
  String get iHaveInviteCode => '招待コードを持っています';

  @override
  String get yourInviteCode => '招待コード';

  @override
  String get continueToApp => 'アプリへ進む';

  @override
  String get joinFamily => 'ファミリーに参加';

  @override
  String get join => '参加';

  @override
  String get createFamilyInstead => 'ファミリーを新規作成';

  @override
  String get inviteCode => '招待コード';

  @override
  String get enterInviteCode => '招待コードを入力';

  @override
  String get invalidCode => '無効または期限切れのコードです';

  @override
  String get cats => 'ねこ';

  @override
  String get noCatsYet => 'ねこがいません';

  @override
  String get tasks => 'タスク';

  @override
  String get addTask => 'タスクを追加';

  @override
  String get newTask => '新規タスク';

  @override
  String get editTask => 'タスクを編集';

  @override
  String get cat => 'ねこ';

  @override
  String get reminder => 'リマインダー';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get deleteCat => 'ねこを削除しますか？';

  @override
  String get name => '名前';

  @override
  String get birthday => '誕生日';

  @override
  String get weight => '体重（kg）';

  @override
  String get neutered => '去勢・避妊済み';

  @override
  String get activity => '活動量';

  @override
  String get health => '健康';

  @override
  String get addCatFirstHealth => '健康記録にはまずねこを追加してください。';

  @override
  String get addHealthLog => '健康記録を追加';

  @override
  String noHealthLogs(String catName) {
    return '$catNameの健康記録はまだありません';
  }

  @override
  String get type => '種類';

  @override
  String get note => 'メモ';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get free => '無料';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => '現在のプラン';

  @override
  String freeCats(int count) {
    return 'ねこ$count匹';
  }

  @override
  String freeMembers(int count) {
    return 'メンバー$count人（自分だけ）';
  }

  @override
  String freeAiPerDay(int count) {
    return '1日AI$count回';
  }

  @override
  String get multipleCats => 'ねこ複数匹';

  @override
  String get multipleMembers => '家族複数人';

  @override
  String get unlimitedAi => 'AI無制限';

  @override
  String get advancedReminders => '高度なリマインダー';

  @override
  String get upgradeToPro => 'Proにアップグレード（デモ）';

  @override
  String get proActivated => 'Proを有効にしました（デモ）';

  @override
  String get settings => '設定';

  @override
  String get family => 'ファミリー';

  @override
  String get members => 'メンバー';

  @override
  String get manageMembers => 'メンバーを管理';

  @override
  String get leaveFamily => 'ファミリーを退出';

  @override
  String get leaveFamilyConfirm => 'ファミリーを退出しますか？';

  @override
  String get leave => '退出';

  @override
  String get signOut => 'ログアウト';

  @override
  String get inviteCodeCopied => '招待コードをコピーしました';

  @override
  String get familyMembers => 'ファミリーメンバー';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat => '無料プランはねこ1匹までです。複数匹はProへ。';

  @override
  String get upgradeForFamilySharing => 'Proで家族と共有';

  @override
  String get upgradeForFamilySharingBody =>
      'Proでねこを追加し、家族を招待。みんなで温かく、シンプルにお世話。';

  @override
  String get goToSubscription => 'Proを見る';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get displayName => '表示名';

  @override
  String get enterEmail => 'メールを入力';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get enterName => '名前を入力';

  @override
  String get atLeast6Chars => '6文字以上';

  @override
  String get home => 'ホーム';

  @override
  String get today => '今日';

  @override
  String get severity => '深刻度';

  @override
  String get severityGreen => '軽い';

  @override
  String get severityYellow => '中程度';

  @override
  String get severityRed => '重い';

  @override
  String get repeatDaily => '毎日';

  @override
  String get repeatWeekly => '毎週';

  @override
  String get repeatMonthly => '毎月';

  @override
  String get repeatCustom => 'カスタム';

  @override
  String get healthWeight => '体重';

  @override
  String get healthDeworm => '駆虫';

  @override
  String get healthVaccine => 'ワクチン';

  @override
  String get healthNote => 'メモ';

  @override
  String get activityLow => '低い';

  @override
  String get activityMedium => '普通';

  @override
  String get activityHigh => '高い';

  @override
  String get language => '言語';

  @override
  String get languageFollowSystem => 'システムに従う';

  @override
  String get region => '国・地域';

  @override
  String get goToSettingsToSignIn => '設定からログインするとすべての機能が使えます。';

  @override
  String errorWithMessage(String message) {
    return 'エラー：$message';
  }

  @override
  String get myCats => 'マイねこ';

  @override
  String get signInToManageCats => 'ログインしてねこを管理';

  @override
  String get noCatsYetAddOne => 'ねこがいません。追加しましょう！';

  @override
  String get createPost => '投稿する';

  @override
  String get postButton => '投稿';

  @override
  String get submit => '送信';

  @override
  String get title => 'タイトル';

  @override
  String get summary => '概要';

  @override
  String get content => '本文';

  @override
  String get contentTooLong => '内容が長すぎます。投稿前に短くしてください。';

  @override
  String get backendUrlNotConfigured => 'バックエンドURLが未設定です。';

  @override
  String get pleaseSignIn => 'ログインしてください。';

  @override
  String get contentUpdated => '内容を更新しました。';

  @override
  String get aiUnavailable => 'AIは利用できません。';

  @override
  String aiUnavailableReason(String reason) {
    return 'AI利用不可: $reason';
  }

  @override
  String get failedToPost => '投稿に失敗しました';

  @override
  String get aiRewriteLabel => 'AIで書き換え';

  @override
  String get breeds => '品種';

  @override
  String get topics => 'トピック';

  @override
  String get selectBreed => '品種を選択';

  @override
  String get publicProfile => '公開プロフィール';

  @override
  String get yourNotes => 'あなたのメモ（飼育メモ）';

  @override
  String get planTitle => '7日間・新規飼い主プラン';

  @override
  String get signInToStartPlan => 'ログインしてプランを開始';

  @override
  String get reminders => 'リマインダー';

  @override
  String get signInToSetReminders => 'ログインしてリマインダーを設定';

  @override
  String get selectCat => 'ねこを選択';

  @override
  String get saveReminder => 'リマインダーを保存';

  @override
  String get bookmarks => 'ブックマーク';

  @override
  String get signInToSeeBookmarks => 'ログインしてブックマークを表示';

  @override
  String get noBookmarksYet => 'ブックマークはまだありません';

  @override
  String get post => '投稿';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'コメント';

  @override
  String get report => '報告';

  @override
  String get reason => '理由';

  @override
  String get share => 'Share';

  @override
  String get shareFromMeowCare => 'From MeowCare – cat care made simple';

  @override
  String get sourceReddit => 'Source: Reddit';

  @override
  String get viewDiscussionOnReddit => 'View discussion on Reddit';

  @override
  String get trendingCatsFromReddit => 'Trending cats from Reddit';

  @override
  String get reminderDialogTitle => 'リマインダー';

  @override
  String get time => '時刻';

  @override
  String get repeat => '繰り返し';

  @override
  String get everyNDays => 'N日ごと';

  @override
  String get signInForFullFeatures => '未ログイン。ログインするとすべての機能が使えます。';

  @override
  String get loadMore => 'もっと見る';

  @override
  String get noCatsYetShort => 'ねこがいません';

  @override
  String get selectCatLabel => 'ねこを選択';

  @override
  String get noneOption => '— なし —';

  @override
  String get failedToLoadBreeds => '品種の読み込みに失敗しました';

  @override
  String get addCatLabel => 'ねこを追加';

  @override
  String get editCatLabel => 'ねこを編集';

  @override
  String get dewormCycleDays => '駆虫周期（日）';

  @override
  String get bathCycleDays => 'お風呂の周期（日）';

  @override
  String get vaccineNextDate => '次回ワクチン日';

  @override
  String get notFound => '見つかりません';

  @override
  String get postNotFound => '投稿が見つかりません';

  @override
  String get latest => '最新';

  @override
  String get hot => '人気';

  @override
  String get allBreeds => 'すべての品種';

  @override
  String get allTopics => 'すべてのトピック';

  @override
  String get topicCare => 'ケア';

  @override
  String get topicHealth => '健康';

  @override
  String get topicFeeding => '餌';

  @override
  String get topicBehavior => '行動';

  @override
  String get loadingRegionContent => 'この地域のコンテンツを読み込み中…';

  @override
  String get feedLoadFailed => 'フィードの読み込みに失敗しました。再試行してください。';

  @override
  String get aiNavLabel => 'AI';

  @override
  String get aiErrorDescribeSymptom => '症状を入力してください';

  @override
  String aiErrorFreeLimit(int count) {
    return '無料は1日$count回まで。Proで無制限。';
  }

  @override
  String get aiModelLabel => '現在のモデル';

  @override
  String get retry => '再試行';

  @override
  String get me => '自分';

  @override
  String get planDay1 => '1日目: 家の準備';

  @override
  String get planDay2 => '2日目: フードと食器';

  @override
  String get planDay3 => '3日目: トイレ設置';

  @override
  String get planDay4 => '4日目: 初回健診';

  @override
  String get planDay5 => '5日目: グルーミング';

  @override
  String get planDay6 => '6日目: 遊びと絆';

  @override
  String get planDay7 => '7日目: ルーティン';
}
