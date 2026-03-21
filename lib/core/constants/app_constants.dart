/// App-wide limits and magic numbers.
class AppConstants {
  AppConstants._();

  /// Free tier: max cats per family.
  static const int freeMaxCats = 1;

  /// Free tier: max members per family (only self).
  static const int freeMaxMembers = 1;

  /// Free tier: AI requests per day.
  static const int freeAiRequestsPerDay = 2;

  /// Firestore collection names.
  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String membersSubcollection = 'members';
  static const String catsCollection = 'cats';
  static const String catsPrivateCollection = 'catsPrivate';
  static const String remindersCollection = 'reminders';
  static const String tasksCollection = 'tasks';
  static const String taskLogsCollection = 'taskLogs';
  static const String healthLogsCollection = 'healthLogs';
  static const String aiRequestsCollection = 'aiRequests';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String bookmarksCollection = 'bookmarks';
  static const String reportsCollection = 'reports';
  static const String breedsCollection = 'breeds';
  static const String adminsCollection = 'admins';

  /// Storage paths.
  static const String storageAvatarsPath = 'avatars';
  static const String storageCoversPath = 'covers';

  /// Feed page size.
  static const int feedPageSize = 20;

  /// Backend API base URL for admin/AI. Override with --dart-define=MEOWCARE_BACKEND_URL=... for local.
  static const String backendBaseUrl = String.fromEnvironment(
    'MEOWCARE_BACKEND_URL',
    defaultValue: 'https://meowcare-api-394032854754.asia-east1.run.app',
  );

  /// Play / App Store link used in「分享 App」. Override: `--dart-define=MEOWCARE_APP_URL=https://...`
  static const String appDownloadUrl = String.fromEnvironment(
    'MEOWCARE_APP_URL',
    defaultValue: 'https://play.google.com/store/apps/details?id=com.meowcare.meowcare',
  );

  /// 帖子 Web 分享链接前缀（占位，上线站点后替换）。`--dart-define=MEOWCARE_POST_WEB_BASE=https://example.com/p`
  static const String postShareWebBase = String.fromEnvironment(
    'MEOWCARE_POST_WEB_BASE',
    defaultValue: 'https://meowcare.app/post',
  );

  static String postShareUrl(String postId) => '$postShareWebBase/$postId';
}


