// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => '家庭喂食与健康提醒';

  @override
  String get feed => '喂食';

  @override
  String get water => '换水';

  @override
  String get litter => '清理猫砂';

  @override
  String get grooming => '梳毛';

  @override
  String get bath => '洗澡';

  @override
  String get deworm => '驱虫';

  @override
  String get vaccine => '疫苗';

  @override
  String get addCat => '添加猫咪';

  @override
  String get addFirstCat => '添加第一只猫';

  @override
  String get editCat => '编辑猫咪';

  @override
  String get todayCare => '今日护理';

  @override
  String get markDone => '标记完成';

  @override
  String get allTasks => '全部任务';

  @override
  String get noTasksYet => '暂无任务。添加猫咪并创建任务。';

  @override
  String get aiSymptomSupport => 'AI 症状咨询';

  @override
  String aiTitleWithName(String catName) {
    return '$catName 还好吗？';
  }

  @override
  String get aiTitleGeneric => '需要什么帮助？';

  @override
  String get aiSubtitle => '仅供参考，不能替代兽医诊断。';

  @override
  String get aiHint => '如：打喷嚏、食欲不振';

  @override
  String get getGuidance => '获取建议';

  @override
  String get guidance => '建议';

  @override
  String get createAccount => '注册账号';

  @override
  String get signIn => '登录';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get register => '注册';

  @override
  String get createFamily => '创建家庭';

  @override
  String get createFamilyDesc => '创建家庭以与家人共享养猫提醒。';

  @override
  String get iHaveInviteCode => '我有邀请码';

  @override
  String get yourInviteCode => '你的邀请码';

  @override
  String get continueToApp => '进入应用';

  @override
  String get joinFamily => '加入家庭';

  @override
  String get join => '加入';

  @override
  String get createFamilyInstead => '改为创建家庭';

  @override
  String get inviteCode => '邀请码';

  @override
  String get enterInviteCode => '输入邀请码';

  @override
  String get invalidCode => '邀请码无效或已过期';

  @override
  String get cats => '猫咪';

  @override
  String get noCatsYet => '暂无猫咪';

  @override
  String get tasks => '任务';

  @override
  String get addTask => '添加任务';

  @override
  String get newTask => '新任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get cat => '猫咪';

  @override
  String get reminder => '提醒';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get deleteCat => '删除猫咪？';

  @override
  String get name => '名称';

  @override
  String get birthday => '生日';

  @override
  String get weight => '体重（公斤）';

  @override
  String get neutered => '已绝育';

  @override
  String get activity => '活动量';

  @override
  String get health => '健康';

  @override
  String get addCatFirstHealth => '请先添加猫咪以记录健康。';

  @override
  String get addHealthLog => '添加健康记录';

  @override
  String noHealthLogs(String catName) {
    return '$catName 暂无健康记录';
  }

  @override
  String get type => '类型';

  @override
  String get note => '备注';

  @override
  String get subscription => '订阅';

  @override
  String get free => '免费';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => '当前方案';

  @override
  String freeCats(int count) {
    return '$count 只猫';
  }

  @override
  String freeMembers(int count) {
    return '$count 位成员（仅你）';
  }

  @override
  String freeAiPerDay(int count) {
    return '每日 $count 次 AI 咨询';
  }

  @override
  String get multipleCats => '多只猫咪';

  @override
  String get multipleMembers => '多位家庭成员';

  @override
  String get unlimitedAi => '无限次 AI 咨询';

  @override
  String get advancedReminders => '高级提醒';

  @override
  String get upgradeToPro => '升级到 Pro（演示）';

  @override
  String get proActivated => '已开通 Pro（演示）';

  @override
  String get settings => '设置';

  @override
  String get family => '家庭';

  @override
  String get members => '成员';

  @override
  String get manageMembers => '管理成员';

  @override
  String get leaveFamily => '退出家庭';

  @override
  String get leaveFamilyConfirm => '确定退出家庭？';

  @override
  String get leave => '退出';

  @override
  String get signOut => '退出登录';

  @override
  String get inviteCodeCopied => '邀请码已复制';

  @override
  String get familyMembers => '家庭成员';

  @override
  String get ok => '确定';

  @override
  String get freeLimitOneCat => '免费版仅 1 只猫，升级 Pro 可添加更多。';

  @override
  String get upgradeForFamilySharing => '升级 Pro 与家人共享';

  @override
  String get upgradeForFamilySharingBody => 'Pro 可添加更多猫咪并邀请家人，简单温暖的护理。';

  @override
  String get goToSubscription => '查看 Pro';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get displayName => '显示名称';

  @override
  String get enterEmail => '输入邮箱';

  @override
  String get enterPassword => '输入密码';

  @override
  String get enterName => '输入名称';

  @override
  String get atLeast6Chars => '至少 6 个字符';

  @override
  String get home => '首页';

  @override
  String get today => '今天';

  @override
  String get severity => '严重程度';

  @override
  String get severityGreen => '轻微';

  @override
  String get severityYellow => '中等';

  @override
  String get severityRed => '严重';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatMonthly => '每月';

  @override
  String get repeatCustom => '自定义';

  @override
  String get healthWeight => '体重';

  @override
  String get healthDeworm => '驱虫';

  @override
  String get healthVaccine => '疫苗';

  @override
  String get healthNote => '备注';

  @override
  String get activityLow => '低';

  @override
  String get activityMedium => '中';

  @override
  String get activityHigh => '高';

  @override
  String get language => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get region => '国家/地区';

  @override
  String get goToSettingsToSignIn => '请前往「设置」登录以使用完整功能。';

  @override
  String errorWithMessage(String message) {
    return '错误：$message';
  }

  @override
  String get myCats => '我的猫咪';

  @override
  String get signInToManageCats => '登录后管理你的猫咪';

  @override
  String get noCatsYetAddOne => '暂无猫咪，去添加一只吧';

  @override
  String get createPost => '发帖';

  @override
  String get postButton => '发帖';

  @override
  String get postAddImage => 'Add image';

  @override
  String get postRemoveImage => 'Remove image';

  @override
  String get postImagePickFailed => 'Could not pick image.';

  @override
  String get postImageUploadFailed =>
      'Image upload failed. The post may be published without a cover.';

  @override
  String get submit => '提交';

  @override
  String get title => '标题';

  @override
  String get summary => '摘要';

  @override
  String get content => '内容';

  @override
  String get contentTooLong => '内容过长，请缩短后再发';

  @override
  String get backendUrlNotConfigured => '未配置后端地址，请设置 MEOWCARE_BACKEND_URL。';

  @override
  String get pleaseSignIn => '请先登录。';

  @override
  String get contentUpdated => '内容已更新。';

  @override
  String get aiUnavailable => 'AI 不可用，请检查后端 GEMINI_API_KEY。';

  @override
  String aiUnavailableReason(String reason) {
    return 'AI 不可用：$reason';
  }

  @override
  String get failedToPost => '发帖失败';

  @override
  String get aiRewriteLabel => 'AI 改写';

  @override
  String get breeds => '品种';

  @override
  String get topics => '话题';

  @override
  String get selectBreed => '选择品种';

  @override
  String get publicProfile => '公开资料';

  @override
  String get yourNotes => '你的笔记（养猫心得）';

  @override
  String get planTitle => '7 天新手养猫计划';

  @override
  String get signInToStartPlan => '登录后开始计划';

  @override
  String get reminders => '提醒';

  @override
  String get signInToSetReminders => '登录后设置提醒';

  @override
  String get selectCat => '选择猫咪';

  @override
  String get saveReminder => '保存提醒';

  @override
  String get bookmarks => '收藏';

  @override
  String get signInToSeeBookmarks => '登录后查看收藏';

  @override
  String get noBookmarksYet => '暂无收藏';

  @override
  String get post => '帖子';

  @override
  String get likes => '点赞';

  @override
  String get comments => '评论';

  @override
  String get report => '举报';

  @override
  String get reason => '原因';

  @override
  String get share => '分享';

  @override
  String get shareFromMeowCare => '来自 MeowCare，一起科学养猫';

  @override
  String get shareAppMenu => '分享 MeowCare';

  @override
  String get shareAppSubject => 'MeowCare — 猫咪护理与社区';

  @override
  String shareAppBody(String url) {
    return 'MeowCare — 养猫提醒、家庭协作与猫咪内容流。\n\n下载应用：\n$url';
  }

  @override
  String sharePostLinkLine(String url) {
    return '查看帖子（链接占位，正式页面上线后可用）：\n$url';
  }

  @override
  String get sourceReddit => '来源：Reddit';

  @override
  String get viewDiscussionOnReddit => '在 Reddit 查看讨论';

  @override
  String get trendingCatsFromReddit => 'Reddit 热门猫咪话题';

  @override
  String get reminderDialogTitle => '提醒';

  @override
  String get time => '时间';

  @override
  String get repeat => '重复';

  @override
  String get everyNDays => '每 N 天';

  @override
  String get signInForFullFeatures => '未登录，登录后可使用完整功能';

  @override
  String get loadMore => '加载更多';

  @override
  String get noCatsYetShort => '暂无猫咪';

  @override
  String get selectCatLabel => '选择猫咪';

  @override
  String get noneOption => '— 无 —';

  @override
  String get failedToLoadBreeds => '加载品种失败';

  @override
  String get addCatLabel => '添加猫咪';

  @override
  String get editCatLabel => '编辑猫咪';

  @override
  String get dewormCycleDays => '驱虫周期（天）';

  @override
  String get bathCycleDays => '洗澡周期（天）';

  @override
  String get vaccineNextDate => '下次疫苗日期';

  @override
  String get notFound => '未找到';

  @override
  String get postNotFound => '帖子未找到';

  @override
  String get latest => '最新';

  @override
  String get hot => '热门';

  @override
  String get allBreeds => '全部品种';

  @override
  String get allTopics => '全部话题';

  @override
  String get topicCare => '护理';

  @override
  String get topicHealth => '健康';

  @override
  String get topicFeeding => '喂食';

  @override
  String get topicBehavior => '行为';

  @override
  String get loadingRegionContent => '正在加载该地区内容…';

  @override
  String get feedLoadFailed => '加载动态失败，请重试。';

  @override
  String get aiNavLabel => 'AI';

  @override
  String get aiErrorDescribeSymptom => '请描述症状';

  @override
  String aiErrorFreeLimit(int count) {
    return '免费每日限 $count 次 AI 咨询，升级 Pro 可无限使用。';
  }

  @override
  String get aiModelLabel => '当前模型';

  @override
  String get retry => '重试';

  @override
  String get me => '我';

  @override
  String get planDay1 => '第 1 天：为猫咪准备家居环境';

  @override
  String get planDay2 => '第 2 天：选择食物与食具';

  @override
  String get planDay3 => '第 3 天：布置猫砂盆';

  @override
  String get planDay4 => '第 4 天：首次体检要点';

  @override
  String get planDay5 => '第 5 天：梳毛入门';

  @override
  String get planDay6 => '第 6 天：玩耍与互动';

  @override
  String get planDay7 => '第 7 天：建立日常节奏';
}
