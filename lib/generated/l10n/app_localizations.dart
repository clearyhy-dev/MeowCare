import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MeowCare'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family Feeding & Health Reminder'**
  String get appSubtitle;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Change Water'**
  String get water;

  /// No description provided for @litter.
  ///
  /// In en, this message translates to:
  /// **'Clean Litter'**
  String get litter;

  /// No description provided for @grooming.
  ///
  /// In en, this message translates to:
  /// **'Grooming'**
  String get grooming;

  /// No description provided for @bath.
  ///
  /// In en, this message translates to:
  /// **'Bath'**
  String get bath;

  /// No description provided for @deworm.
  ///
  /// In en, this message translates to:
  /// **'Deworm'**
  String get deworm;

  /// No description provided for @vaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get vaccine;

  /// No description provided for @addCat.
  ///
  /// In en, this message translates to:
  /// **'Add cat'**
  String get addCat;

  /// No description provided for @addFirstCat.
  ///
  /// In en, this message translates to:
  /// **'Add first cat'**
  String get addFirstCat;

  /// No description provided for @editCat.
  ///
  /// In en, this message translates to:
  /// **'Edit cat'**
  String get editCat;

  /// No description provided for @todayCare.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Care'**
  String get todayCare;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasks;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Add a cat and create tasks.'**
  String get noTasksYet;

  /// No description provided for @aiSymptomSupport.
  ///
  /// In en, this message translates to:
  /// **'AI symptom support'**
  String get aiSymptomSupport;

  /// No description provided for @aiTitleWithName.
  ///
  /// In en, this message translates to:
  /// **'Is {catName} feeling okay?'**
  String aiTitleWithName(String catName);

  /// No description provided for @aiTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get aiTitleGeneric;

  /// No description provided for @aiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Informational guidance only. Not a substitute for veterinary care.'**
  String get aiSubtitle;

  /// No description provided for @aiHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. sneezing, loss of appetite'**
  String get aiHint;

  /// No description provided for @getGuidance.
  ///
  /// In en, this message translates to:
  /// **'Get guidance'**
  String get getGuidance;

  /// No description provided for @guidance.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidance;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamily;

  /// No description provided for @createFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a family to share cat care with others.'**
  String get createFamilyDesc;

  /// No description provided for @iHaveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get iHaveInviteCode;

  /// No description provided for @yourInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get yourInviteCode;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to app'**
  String get continueToApp;

  /// No description provided for @joinFamily.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinFamily;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @createFamilyInstead.
  ///
  /// In en, this message translates to:
  /// **'Create a family instead'**
  String get createFamilyInstead;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get enterInviteCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get invalidCode;

  /// No description provided for @cats.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get cats;

  /// No description provided for @noCatsYet.
  ///
  /// In en, this message translates to:
  /// **'No cats yet'**
  String get noCatsYet;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @cat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get cat;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteCat.
  ///
  /// In en, this message translates to:
  /// **'Delete cat?'**
  String get deleteCat;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @neutered.
  ///
  /// In en, this message translates to:
  /// **'Neutered'**
  String get neutered;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @addCatFirstHealth.
  ///
  /// In en, this message translates to:
  /// **'Add a cat first to log health.'**
  String get addCatFirstHealth;

  /// No description provided for @addHealthLog.
  ///
  /// In en, this message translates to:
  /// **'Add health log'**
  String get addHealthLog;

  /// No description provided for @noHealthLogs.
  ///
  /// In en, this message translates to:
  /// **'No health logs for {catName} yet'**
  String noHealthLogs(String catName);

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @freeCats.
  ///
  /// In en, this message translates to:
  /// **'{count} cat'**
  String freeCats(int count);

  /// No description provided for @freeMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} member (just you)'**
  String freeMembers(int count);

  /// No description provided for @freeAiPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count} AI requests per day'**
  String freeAiPerDay(int count);

  /// No description provided for @multipleCats.
  ///
  /// In en, this message translates to:
  /// **'Multiple cats'**
  String get multipleCats;

  /// No description provided for @multipleMembers.
  ///
  /// In en, this message translates to:
  /// **'Multiple family members'**
  String get multipleMembers;

  /// No description provided for @unlimitedAi.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI requests'**
  String get unlimitedAi;

  /// No description provided for @advancedReminders.
  ///
  /// In en, this message translates to:
  /// **'Advanced reminders'**
  String get advancedReminders;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro (demo)'**
  String get upgradeToPro;

  /// No description provided for @proActivated.
  ///
  /// In en, this message translates to:
  /// **'Pro activated (demo)'**
  String get proActivated;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @leaveFamily.
  ///
  /// In en, this message translates to:
  /// **'Leave family'**
  String get leaveFamily;

  /// No description provided for @leaveFamilyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave family?'**
  String get leaveFamilyConfirm;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family members'**
  String get familyMembers;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @freeLimitOneCat.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows 1 cat. Upgrade to Pro for more.'**
  String get freeLimitOneCat;

  /// No description provided for @upgradeForFamilySharing.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for family sharing'**
  String get upgradeForFamilySharing;

  /// No description provided for @upgradeForFamilySharingBody.
  ///
  /// In en, this message translates to:
  /// **'Add more cats and invite family members with Pro. Warm, simple care for everyone.'**
  String get upgradeForFamilySharingBody;

  /// No description provided for @goToSubscription.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get goToSubscription;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @severityGreen.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get severityGreen;

  /// No description provided for @severityYellow.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get severityYellow;

  /// No description provided for @severityRed.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get severityRed;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'custom'**
  String get repeatCustom;

  /// No description provided for @healthWeight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get healthWeight;

  /// No description provided for @healthDeworm.
  ///
  /// In en, this message translates to:
  /// **'deworm'**
  String get healthDeworm;

  /// No description provided for @healthVaccine.
  ///
  /// In en, this message translates to:
  /// **'vaccine'**
  String get healthVaccine;

  /// No description provided for @healthNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get healthNote;

  /// No description provided for @activityLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get activityLow;

  /// No description provided for @activityMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get activityMedium;

  /// No description provided for @activityHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get activityHigh;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @goToSettingsToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings to sign in for full access.'**
  String get goToSettingsToSignIn;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @myCats.
  ///
  /// In en, this message translates to:
  /// **'My cats'**
  String get myCats;

  /// No description provided for @signInToManageCats.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your cats'**
  String get signInToManageCats;

  /// No description provided for @noCatsYetAddOne.
  ///
  /// In en, this message translates to:
  /// **'No cats yet. Add one!'**
  String get noCatsYetAddOne;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get createPost;

  /// No description provided for @postButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postButton;

  /// No description provided for @postAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get postAddImage;

  /// No description provided for @postRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get postRemoveImage;

  /// No description provided for @postImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image.'**
  String get postImagePickFailed;

  /// No description provided for @postImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed. The post may be published without a cover.'**
  String get postImageUploadFailed;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @contentTooLong.
  ///
  /// In en, this message translates to:
  /// **'Content too long. Please shorten before posting.'**
  String get contentTooLong;

  /// No description provided for @backendUrlNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Backend URL not configured. Set MEOWCARE_BACKEND_URL.'**
  String get backendUrlNotConfigured;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in.'**
  String get pleaseSignIn;

  /// No description provided for @contentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Content updated.'**
  String get contentUpdated;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI unavailable. Check backend GEMINI_API_KEY.'**
  String get aiUnavailable;

  /// No description provided for @aiUnavailableReason.
  ///
  /// In en, this message translates to:
  /// **'AI unavailable: {reason}'**
  String aiUnavailableReason(String reason);

  /// No description provided for @failedToPost.
  ///
  /// In en, this message translates to:
  /// **'Failed to post'**
  String get failedToPost;

  /// No description provided for @aiRewriteLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Rewrite'**
  String get aiRewriteLabel;

  /// No description provided for @breeds.
  ///
  /// In en, this message translates to:
  /// **'Breeds'**
  String get breeds;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @selectBreed.
  ///
  /// In en, this message translates to:
  /// **'Select breed'**
  String get selectBreed;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfile;

  /// No description provided for @yourNotes.
  ///
  /// In en, this message translates to:
  /// **'Your notes (experience)'**
  String get yourNotes;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'7-day new owner plan'**
  String get planTitle;

  /// No description provided for @signInToStartPlan.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start the plan'**
  String get signInToStartPlan;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @signInToSetReminders.
  ///
  /// In en, this message translates to:
  /// **'Sign in to set reminders'**
  String get signInToSetReminders;

  /// No description provided for @selectCat.
  ///
  /// In en, this message translates to:
  /// **'Select cat'**
  String get selectCat;

  /// No description provided for @saveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get saveReminder;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @signInToSeeBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see bookmarks'**
  String get signInToSeeBookmarks;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareFromMeowCare.
  ///
  /// In en, this message translates to:
  /// **'From MeowCare – cat care made simple'**
  String get shareFromMeowCare;

  /// No description provided for @shareAppMenu.
  ///
  /// In en, this message translates to:
  /// **'Share MeowCare'**
  String get shareAppMenu;

  /// No description provided for @shareAppSubject.
  ///
  /// In en, this message translates to:
  /// **'MeowCare — cat care & community'**
  String get shareAppSubject;

  /// No description provided for @shareAppBody.
  ///
  /// In en, this message translates to:
  /// **'MeowCare — cat care reminders, family sharing, and a friendly cat feed.\n\nGet the app:\n{url}'**
  String shareAppBody(String url);

  /// No description provided for @sharePostLinkLine.
  ///
  /// In en, this message translates to:
  /// **'Open post (link placeholder):\n{url}'**
  String sharePostLinkLine(String url);

  /// No description provided for @sourceReddit.
  ///
  /// In en, this message translates to:
  /// **'Source: Reddit'**
  String get sourceReddit;

  /// No description provided for @viewDiscussionOnReddit.
  ///
  /// In en, this message translates to:
  /// **'View discussion on Reddit'**
  String get viewDiscussionOnReddit;

  /// No description provided for @trendingCatsFromReddit.
  ///
  /// In en, this message translates to:
  /// **'Trending cats from Reddit'**
  String get trendingCatsFromReddit;

  /// No description provided for @reminderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderDialogTitle;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get everyNDays;

  /// No description provided for @signInForFullFeatures.
  ///
  /// In en, this message translates to:
  /// **'Sign in for full features'**
  String get signInForFullFeatures;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @noCatsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No cats yet'**
  String get noCatsYetShort;

  /// No description provided for @selectCatLabel.
  ///
  /// In en, this message translates to:
  /// **'Select cat'**
  String get selectCatLabel;

  /// No description provided for @noneOption.
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get noneOption;

  /// No description provided for @failedToLoadBreeds.
  ///
  /// In en, this message translates to:
  /// **'Failed to load breeds'**
  String get failedToLoadBreeds;

  /// No description provided for @addCatLabel.
  ///
  /// In en, this message translates to:
  /// **'Add cat'**
  String get addCatLabel;

  /// No description provided for @editCatLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit cat'**
  String get editCatLabel;

  /// No description provided for @dewormCycleDays.
  ///
  /// In en, this message translates to:
  /// **'Deworming cycle (days)'**
  String get dewormCycleDays;

  /// No description provided for @bathCycleDays.
  ///
  /// In en, this message translates to:
  /// **'Bath cycle (days)'**
  String get bathCycleDays;

  /// No description provided for @vaccineNextDate.
  ///
  /// In en, this message translates to:
  /// **'Vaccine next date'**
  String get vaccineNextDate;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @postNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found'**
  String get postNotFound;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @hot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get hot;

  /// No description provided for @allBreeds.
  ///
  /// In en, this message translates to:
  /// **'All breeds'**
  String get allBreeds;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get allTopics;

  /// No description provided for @topicCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get topicCare;

  /// No description provided for @topicHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get topicHealth;

  /// No description provided for @topicFeeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get topicFeeding;

  /// No description provided for @topicBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get topicBehavior;

  /// No description provided for @loadingRegionContent.
  ///
  /// In en, this message translates to:
  /// **'Loading content for this region…'**
  String get loadingRegionContent;

  /// No description provided for @feedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feed. Please retry.'**
  String get feedLoadFailed;

  /// No description provided for @feedNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content for this topic yet.'**
  String get feedNoContent;

  /// No description provided for @aiNavLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiNavLabel;

  /// No description provided for @aiErrorDescribeSymptom.
  ///
  /// In en, this message translates to:
  /// **'Please describe the symptom'**
  String get aiErrorDescribeSymptom;

  /// No description provided for @aiErrorFreeLimit.
  ///
  /// In en, this message translates to:
  /// **'Free limit: {count} AI requests per day. Upgrade to Pro for unlimited.'**
  String aiErrorFreeLimit(int count);

  /// No description provided for @aiModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Current model'**
  String get aiModelLabel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @planDay1.
  ///
  /// In en, this message translates to:
  /// **'Day 1: Prepare your home for the cat'**
  String get planDay1;

  /// No description provided for @planDay2.
  ///
  /// In en, this message translates to:
  /// **'Day 2: Choose food and bowls'**
  String get planDay2;

  /// No description provided for @planDay3.
  ///
  /// In en, this message translates to:
  /// **'Day 3: Set up litter box'**
  String get planDay3;

  /// No description provided for @planDay4.
  ///
  /// In en, this message translates to:
  /// **'Day 4: First vet visit basics'**
  String get planDay4;

  /// No description provided for @planDay5.
  ///
  /// In en, this message translates to:
  /// **'Day 5: Grooming introduction'**
  String get planDay5;

  /// No description provided for @planDay6.
  ///
  /// In en, this message translates to:
  /// **'Day 6: Play and bonding'**
  String get planDay6;

  /// No description provided for @planDay7.
  ///
  /// In en, this message translates to:
  /// **'Day 7: Establish routine'**
  String get planDay7;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseAppLanguage;

  /// No description provided for @loginErrorFirestoreSync.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google, but profile sync failed (network or Firestore). Check your network, try without VPN, and ensure Firestore is enabled.'**
  String get loginErrorFirestoreSync;

  /// No description provided for @loginErrorGoogleConfig.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In setup: add your app\'s SHA-1 in Firebase and re-download google-services.json.'**
  String get loginErrorGoogleConfig;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get loginErrorNetwork;

  /// No description provided for @languageTagEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageTagEn;

  /// No description provided for @languageTagZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageTagZh;

  /// No description provided for @languageTagJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageTagJa;

  /// No description provided for @languageTagEs.
  ///
  /// In en, this message translates to:
  /// **'ES'**
  String get languageTagEs;

  /// No description provided for @languageTagFr.
  ///
  /// In en, this message translates to:
  /// **'FR'**
  String get languageTagFr;

  /// No description provided for @languageTagDe.
  ///
  /// In en, this message translates to:
  /// **'DE'**
  String get languageTagDe;

  /// No description provided for @languageTagPt.
  ///
  /// In en, this message translates to:
  /// **'PT'**
  String get languageTagPt;

  /// No description provided for @languageTagRu.
  ///
  /// In en, this message translates to:
  /// **'RU'**
  String get languageTagRu;

  /// No description provided for @languageTagKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageTagKo;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageNameZh;

  /// No description provided for @languageNameJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageNameJa;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageNameEs;

  /// No description provided for @languageNameFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageNameFr;

  /// No description provided for @languageNameDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageNameDe;

  /// No description provided for @languageNamePt.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languageNamePt;

  /// No description provided for @languageNameRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageNameRu;

  /// No description provided for @languageNameKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageNameKo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'ko',
        'pt',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
