// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => 'Family Feeding & Health Reminder';

  @override
  String get feed => 'Feed';

  @override
  String get water => 'Change Water';

  @override
  String get litter => 'Clean Litter';

  @override
  String get grooming => 'Grooming';

  @override
  String get bath => 'Bath';

  @override
  String get deworm => 'Deworm';

  @override
  String get vaccine => 'Vaccine';

  @override
  String get addCat => 'Add cat';

  @override
  String get addFirstCat => 'Add first cat';

  @override
  String get editCat => 'Edit cat';

  @override
  String get todayCare => 'Today\'s Care';

  @override
  String get markDone => 'Mark Done';

  @override
  String get allTasks => 'All tasks';

  @override
  String get noTasksYet => 'No tasks yet. Add a cat and create tasks.';

  @override
  String get aiSymptomSupport => 'AI symptom support';

  @override
  String aiTitleWithName(String catName) {
    return 'Is $catName feeling okay?';
  }

  @override
  String get aiTitleGeneric => 'How can we help?';

  @override
  String get aiSubtitle =>
      'Informational guidance only. Not a substitute for veterinary care.';

  @override
  String get aiHint => 'e.g. sneezing, loss of appetite';

  @override
  String get getGuidance => 'Get guidance';

  @override
  String get guidance => 'Guidance';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get register => 'Register';

  @override
  String get createFamily => 'Create family';

  @override
  String get createFamilyDesc =>
      'Create a family to share cat care with others.';

  @override
  String get iHaveInviteCode => 'I have an invite code';

  @override
  String get yourInviteCode => 'Your invite code';

  @override
  String get continueToApp => 'Continue to app';

  @override
  String get joinFamily => 'Join family';

  @override
  String get join => 'Join';

  @override
  String get createFamilyInstead => 'Create a family instead';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get enterInviteCode => 'Enter invite code';

  @override
  String get invalidCode => 'Invalid or expired code';

  @override
  String get cats => 'Cats';

  @override
  String get noCatsYet => 'No cats yet';

  @override
  String get tasks => 'Tasks';

  @override
  String get addTask => 'Add task';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get cat => 'Cat';

  @override
  String get reminder => 'Reminder';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteCat => 'Delete cat?';

  @override
  String get name => 'Name';

  @override
  String get birthday => 'Birthday';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get neutered => 'Neutered';

  @override
  String get activity => 'Activity';

  @override
  String get health => 'Health';

  @override
  String get addCatFirstHealth => 'Add a cat first to log health.';

  @override
  String get addHealthLog => 'Add health log';

  @override
  String noHealthLogs(String catName) {
    return 'No health logs for $catName yet';
  }

  @override
  String get type => 'Type';

  @override
  String get note => 'Note';

  @override
  String get subscription => 'Subscription';

  @override
  String get free => 'Free';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => 'Current plan';

  @override
  String freeCats(int count) {
    return '$count cat';
  }

  @override
  String freeMembers(int count) {
    return '$count member (just you)';
  }

  @override
  String freeAiPerDay(int count) {
    return '$count AI requests per day';
  }

  @override
  String get multipleCats => 'Multiple cats';

  @override
  String get multipleMembers => 'Multiple family members';

  @override
  String get unlimitedAi => 'Unlimited AI requests';

  @override
  String get advancedReminders => 'Advanced reminders';

  @override
  String get upgradeToPro => 'Upgrade to Pro (demo)';

  @override
  String get proActivated => 'Pro activated (demo)';

  @override
  String get settings => 'Settings';

  @override
  String get family => 'Family';

  @override
  String get members => 'Members';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get leaveFamily => 'Leave family';

  @override
  String get leaveFamilyConfirm => 'Leave family?';

  @override
  String get leave => 'Leave';

  @override
  String get signOut => 'Sign out';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String get familyMembers => 'Family members';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat =>
      'Free plan allows 1 cat. Upgrade to Pro for more.';

  @override
  String get upgradeForFamilySharing => 'Upgrade to Pro for family sharing';

  @override
  String get upgradeForFamilySharingBody =>
      'Add more cats and invite family members with Pro. Warm, simple care for everyone.';

  @override
  String get goToSubscription => 'See Pro';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Display name';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get enterName => 'Enter name';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get home => 'Home';

  @override
  String get today => 'Today';

  @override
  String get severity => 'Severity';

  @override
  String get severityGreen => 'green';

  @override
  String get severityYellow => 'yellow';

  @override
  String get severityRed => 'red';

  @override
  String get repeatDaily => 'daily';

  @override
  String get repeatWeekly => 'weekly';

  @override
  String get repeatMonthly => 'monthly';

  @override
  String get repeatCustom => 'custom';

  @override
  String get healthWeight => 'weight';

  @override
  String get healthDeworm => 'deworm';

  @override
  String get healthVaccine => 'vaccine';

  @override
  String get healthNote => 'note';

  @override
  String get activityLow => 'low';

  @override
  String get activityMedium => 'medium';

  @override
  String get activityHigh => 'high';

  @override
  String get language => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get region => 'Region';

  @override
  String get goToSettingsToSignIn =>
      'Please go to Settings to sign in for full access.';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get myCats => 'My cats';

  @override
  String get signInToManageCats => 'Sign in to manage your cats';

  @override
  String get noCatsYetAddOne => 'No cats yet. Add one!';

  @override
  String get createPost => 'Create post';

  @override
  String get postButton => 'Post';

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
  String get submit => 'Submit';

  @override
  String get title => 'Title';

  @override
  String get summary => 'Summary';

  @override
  String get content => 'Content';

  @override
  String get contentTooLong =>
      'Content too long. Please shorten before posting.';

  @override
  String get backendUrlNotConfigured =>
      'Backend URL not configured. Set MEOWCARE_BACKEND_URL.';

  @override
  String get pleaseSignIn => 'Please sign in.';

  @override
  String get contentUpdated => 'Content updated.';

  @override
  String get aiUnavailable => 'AI unavailable. Check backend GEMINI_API_KEY.';

  @override
  String aiUnavailableReason(String reason) {
    return 'AI unavailable: $reason';
  }

  @override
  String get failedToPost => 'Failed to post';

  @override
  String get aiRewriteLabel => 'AI Rewrite';

  @override
  String get breeds => 'Breeds';

  @override
  String get topics => 'Topics';

  @override
  String get selectBreed => 'Select breed';

  @override
  String get publicProfile => 'Public profile';

  @override
  String get yourNotes => 'Your notes (experience)';

  @override
  String get planTitle => '7-day new owner plan';

  @override
  String get signInToStartPlan => 'Sign in to start the plan';

  @override
  String get reminders => 'Reminders';

  @override
  String get signInToSetReminders => 'Sign in to set reminders';

  @override
  String get selectCat => 'Select cat';

  @override
  String get saveReminder => 'Save reminder';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get signInToSeeBookmarks => 'Sign in to see bookmarks';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get post => 'Post';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Comments';

  @override
  String get report => 'Report';

  @override
  String get reason => 'Reason';

  @override
  String get share => 'Share';

  @override
  String get shareFromMeowCare => 'From MeowCare – cat care made simple';

  @override
  String get shareAppMenu => 'Share MeowCare';

  @override
  String get shareAppSubject => 'MeowCare — cat care & community';

  @override
  String shareAppBody(String url) {
    return 'MeowCare — cat care reminders, family sharing, and a friendly cat feed.\n\nGet the app:\n$url';
  }

  @override
  String sharePostLinkLine(String url) {
    return 'Open post (link placeholder):\n$url';
  }

  @override
  String get sourceReddit => 'Source: Reddit';

  @override
  String get viewDiscussionOnReddit => 'View discussion on Reddit';

  @override
  String get trendingCatsFromReddit => 'Trending cats from Reddit';

  @override
  String get reminderDialogTitle => 'Reminder';

  @override
  String get time => 'Time';

  @override
  String get repeat => 'Repeat';

  @override
  String get everyNDays => 'Every N days';

  @override
  String get signInForFullFeatures => 'Sign in for full features';

  @override
  String get loadMore => 'Load more';

  @override
  String get noCatsYetShort => 'No cats yet';

  @override
  String get selectCatLabel => 'Select cat';

  @override
  String get noneOption => '— None —';

  @override
  String get failedToLoadBreeds => 'Failed to load breeds';

  @override
  String get addCatLabel => 'Add cat';

  @override
  String get editCatLabel => 'Edit cat';

  @override
  String get dewormCycleDays => 'Deworming cycle (days)';

  @override
  String get bathCycleDays => 'Bath cycle (days)';

  @override
  String get vaccineNextDate => 'Vaccine next date';

  @override
  String get notFound => 'Not found';

  @override
  String get postNotFound => 'Post not found';

  @override
  String get latest => 'Latest';

  @override
  String get hot => 'Hot';

  @override
  String get allBreeds => 'All breeds';

  @override
  String get allTopics => 'All topics';

  @override
  String get topicCare => 'Care';

  @override
  String get topicHealth => 'Health';

  @override
  String get topicFeeding => 'Feeding';

  @override
  String get topicBehavior => 'Behavior';

  @override
  String get loadingRegionContent => 'Loading content for this region…';

  @override
  String get feedLoadFailed => 'Failed to load feed. Please retry.';

  @override
  String get feedNoContent => 'No content for this topic yet.';

  @override
  String get aiNavLabel => 'AI';

  @override
  String get aiErrorDescribeSymptom => 'Please describe the symptom';

  @override
  String aiErrorFreeLimit(int count) {
    return 'Free limit: $count AI requests per day. Upgrade to Pro for unlimited.';
  }

  @override
  String get aiModelLabel => 'Current model';

  @override
  String get aiAdviceSectionSummary => 'Summary';

  @override
  String get aiAdviceSectionHomeCare => 'Home care';

  @override
  String get aiAdviceSectionRedFlags => 'Red flags';

  @override
  String get aiAdviceSectionVet => 'When to see a vet';

  @override
  String get aiAdviceSectionReassurance => 'A note for you';

  @override
  String get aiAdviceSectionDisclaimer => 'Disclaimer';

  @override
  String get retry => 'Retry';

  @override
  String get searchPostsHint => 'Search by title, content, or #topic';

  @override
  String get noResultFound => 'No matching posts found.';

  @override
  String get me => 'Me';

  @override
  String get planDay1 => 'Day 1: Prepare your home for the cat';

  @override
  String get planDay2 => 'Day 2: Choose food and bowls';

  @override
  String get planDay3 => 'Day 3: Set up litter box';

  @override
  String get planDay4 => 'Day 4: First vet visit basics';

  @override
  String get planDay5 => 'Day 5: Grooming introduction';

  @override
  String get planDay6 => 'Day 6: Play and bonding';

  @override
  String get planDay7 => 'Day 7: Establish routine';

  @override
  String get appLanguage => 'App language';

  @override
  String get profile => 'Profile';

  @override
  String get chooseAppLanguage => 'Choose app language';

  @override
  String get loginErrorFirestoreSync =>
      'Signed in with Google, but profile sync failed (network or Firestore). Check your network, try without VPN, and ensure Firestore is enabled.';

  @override
  String get loginErrorGoogleConfig =>
      'Google Sign-In setup: add your app\'s SHA-1 in Firebase and re-download google-services.json.';

  @override
  String get loginErrorNetwork =>
      'Network error. Check your connection and try again.';

  @override
  String get languageTagEn => 'EN';

  @override
  String get languageTagZh => '中文';

  @override
  String get languageTagJa => '日本語';

  @override
  String get languageTagEs => 'ES';

  @override
  String get languageTagFr => 'FR';

  @override
  String get languageTagDe => 'DE';

  @override
  String get languageTagPt => 'PT';

  @override
  String get languageTagRu => 'RU';

  @override
  String get languageTagKo => '한국어';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameZh => '简体中文';

  @override
  String get languageNameJa => '日本語';

  @override
  String get languageNameEs => 'Español';

  @override
  String get languageNameFr => 'Français';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNamePt => 'Português';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get languageNameKo => '한국어';

  @override
  String get replyAction => 'Reply';

  @override
  String replyToUser(String name) {
    return 'Reply to $name';
  }

  @override
  String viewMoreReplies(int count) {
    return 'View $count more replies';
  }

  @override
  String get collapseReplies => 'Collapse replies';

  @override
  String get communitySectionTitle => 'Community';

  @override
  String get myPostsTitle => 'My posts';

  @override
  String get myCommentsTitle => 'My comments';

  @override
  String get savedPostsTitle => 'Saved';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllNotificationsRead => 'Mark all read';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get myPostsEmpty => 'No posts in this tab.';

  @override
  String get myCommentsEmpty => 'You have not commented yet.';

  @override
  String get savedPostsEmpty => 'No saved posts yet.';

  @override
  String get postStatusDraft => 'Draft';

  @override
  String get postStatusPending => 'Pending';

  @override
  String get postStatusPublished => 'Published';

  @override
  String get postStatusRejected => 'Rejected';

  @override
  String get postTitleUnknown => 'Post';

  @override
  String get notificationMarkReadFailed =>
      'Could not update notification. Try again later.';

  @override
  String get notificationsAllMarkedRead => 'All notifications marked as read.';
}
