// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle =>
      'Familien-Futter & Gesundheits-Erinnerung für Katzen';

  @override
  String get feed => 'Füttern';

  @override
  String get water => 'Wasser wechseln';

  @override
  String get litter => 'Klo reinigen';

  @override
  String get grooming => 'Pflege';

  @override
  String get bath => 'Bad';

  @override
  String get deworm => 'Entwurmung';

  @override
  String get vaccine => 'Impfung';

  @override
  String get addCat => 'Katze hinzufügen';

  @override
  String get addFirstCat => 'Erste Katze hinzufügen';

  @override
  String get editCat => 'Katze bearbeiten';

  @override
  String get todayCare => 'Heutige Pflege';

  @override
  String get markDone => 'Erledigt';

  @override
  String get allTasks => 'Alle Aufgaben';

  @override
  String get noTasksYet =>
      'Noch keine Aufgaben. Füge eine Katze hinzu und erstelle Aufgaben.';

  @override
  String get aiSymptomSupport => 'KI-Symptomhilfe';

  @override
  String aiTitleWithName(String catName) {
    return 'Geht es $catName gut?';
  }

  @override
  String get aiTitleGeneric => 'Wie können wir helfen?';

  @override
  String get aiSubtitle =>
      'Nur zur Information. Kein Ersatz für tierärztliche Beratung.';

  @override
  String get aiHint => 'z. B. Niesen, Appetitlosigkeit';

  @override
  String get getGuidance => 'Hinweise anzeigen';

  @override
  String get guidance => 'Hinweise';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get createFamily => 'Familie erstellen';

  @override
  String get createFamilyDesc =>
      'Erstelle eine Familie, um die Katzenpflege zu teilen.';

  @override
  String get iHaveInviteCode => 'Ich habe einen Einladungscode';

  @override
  String get yourInviteCode => 'Dein Einladungscode';

  @override
  String get continueToApp => 'Zur App';

  @override
  String get joinFamily => 'Familie beitreten';

  @override
  String get join => 'Beitreten';

  @override
  String get createFamilyInstead => 'Stattdessen Familie erstellen';

  @override
  String get inviteCode => 'Einladungscode';

  @override
  String get enterInviteCode => 'Einladungscode eingeben';

  @override
  String get invalidCode => 'Ungültiger oder abgelaufener Code';

  @override
  String get cats => 'Katzen';

  @override
  String get noCatsYet => 'Noch keine Katzen';

  @override
  String get tasks => 'Aufgaben';

  @override
  String get addTask => 'Aufgabe hinzufügen';

  @override
  String get newTask => 'Neue Aufgabe';

  @override
  String get editTask => 'Aufgabe bearbeiten';

  @override
  String get cat => 'Katze';

  @override
  String get reminder => 'Erinnerung';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteCat => 'Katze löschen?';

  @override
  String get name => 'Name';

  @override
  String get birthday => 'Geburtstag';

  @override
  String get weight => 'Gewicht (kg)';

  @override
  String get neutered => 'Kastriert';

  @override
  String get activity => 'Aktivität';

  @override
  String get health => 'Gesundheit';

  @override
  String get addCatFirstHealth =>
      'Füge zuerst eine Katze hinzu für Gesundheitsprotokolle.';

  @override
  String get addHealthLog => 'Gesundheitsprotokoll hinzufügen';

  @override
  String noHealthLogs(String catName) {
    return 'Noch keine Gesundheitsprotokolle für $catName';
  }

  @override
  String get type => 'Typ';

  @override
  String get note => 'Notiz';

  @override
  String get subscription => 'Abonnement';

  @override
  String get free => 'Kostenlos';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => 'Aktueller Plan';

  @override
  String freeCats(int count) {
    return '$count Katze(n)';
  }

  @override
  String freeMembers(int count) {
    return '$count Mitglied(er) (nur du)';
  }

  @override
  String freeAiPerDay(int count) {
    return '$count KI-Anfragen pro Tag';
  }

  @override
  String get multipleCats => 'Mehrere Katzen';

  @override
  String get multipleMembers => 'Mehrere Familienmitglieder';

  @override
  String get unlimitedAi => 'Unbegrenzte KI-Anfragen';

  @override
  String get advancedReminders => 'Erweiterte Erinnerungen';

  @override
  String get upgradeToPro => 'Auf Pro upgraden (Demo)';

  @override
  String get proActivated => 'Pro aktiviert (Demo)';

  @override
  String get settings => 'Einstellungen';

  @override
  String get family => 'Familie';

  @override
  String get members => 'Mitglieder';

  @override
  String get manageMembers => 'Mitglieder verwalten';

  @override
  String get leaveFamily => 'Familie verlassen';

  @override
  String get leaveFamilyConfirm => 'Familie verlassen?';

  @override
  String get leave => 'Verlassen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get inviteCodeCopied => 'Einladungscode kopiert';

  @override
  String get familyMembers => 'Familienmitglieder';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat => 'Kostenlos nur 1 Katze. Pro für mehr.';

  @override
  String get upgradeForFamilySharing => 'Pro für Familienfreigabe';

  @override
  String get upgradeForFamilySharingBody =>
      'Mit Pro mehr Katzen und Familienmitglieder einladen. Einfache, warme Pflege für alle.';

  @override
  String get goToSubscription => 'Pro ansehen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get enterEmail => 'E-Mail eingeben';

  @override
  String get enterPassword => 'Passwort eingeben';

  @override
  String get enterName => 'Name eingeben';

  @override
  String get atLeast6Chars => 'Mindestens 6 Zeichen';

  @override
  String get home => 'Start';

  @override
  String get today => 'Heute';

  @override
  String get severity => 'Schweregrad';

  @override
  String get severityGreen => 'leicht';

  @override
  String get severityYellow => 'mittel';

  @override
  String get severityRed => 'schwer';

  @override
  String get repeatDaily => 'täglich';

  @override
  String get repeatWeekly => 'wöchentlich';

  @override
  String get repeatMonthly => 'monatlich';

  @override
  String get repeatCustom => 'benutzerdefiniert';

  @override
  String get healthWeight => 'Gewicht';

  @override
  String get healthDeworm => 'Entwurmung';

  @override
  String get healthVaccine => 'Impfung';

  @override
  String get healthNote => 'Notiz';

  @override
  String get activityLow => 'niedrig';

  @override
  String get activityMedium => 'mittel';

  @override
  String get activityHigh => 'hoch';

  @override
  String get language => 'Sprache';

  @override
  String get languageFollowSystem => 'System folgen';

  @override
  String get region => 'Region';

  @override
  String get goToSettingsToSignIn =>
      'Bitte in den Einstellungen anmelden für vollen Zugriff.';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get myCats => 'Meine Katzen';

  @override
  String get signInToManageCats =>
      'Melden Sie sich an, um Ihre Katzen zu verwalten.';

  @override
  String get noCatsYetAddOne => 'Noch keine Katzen. Fügen Sie eine hinzu!';

  @override
  String get createPost => 'Beitrag erstellen';

  @override
  String get postButton => 'Beitrag';

  @override
  String get submit => 'Absenden';

  @override
  String get title => 'Titel';

  @override
  String get summary => 'Zusammenfassung';

  @override
  String get content => 'Inhalt';

  @override
  String get contentTooLong =>
      'Inhalt zu lang. Bitte kürzen Sie vor dem Posten.';

  @override
  String get backendUrlNotConfigured => 'Backend-URL nicht konfiguriert.';

  @override
  String get pleaseSignIn => 'Bitte anmelden.';

  @override
  String get contentUpdated => 'Inhalt aktualisiert.';

  @override
  String get aiUnavailable => 'KI nicht verfügbar.';

  @override
  String aiUnavailableReason(String reason) {
    return 'KI nicht verfügbar: $reason';
  }

  @override
  String get failedToPost => 'Beitrag fehlgeschlagen';

  @override
  String get aiRewriteLabel => 'KI umschreiben';

  @override
  String get breeds => 'Rassen';

  @override
  String get topics => 'Themen';

  @override
  String get selectBreed => 'Rasse wählen';

  @override
  String get publicProfile => 'Öffentliches Profil';

  @override
  String get yourNotes => 'Ihre Notizen (Erfahrung)';

  @override
  String get planTitle => '7-Tage-Plan für neue Halter';

  @override
  String get signInToStartPlan => 'Melden Sie sich an, um den Plan zu starten.';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get signInToSetReminders =>
      'Melden Sie sich an, um Erinnerungen zu setzen.';

  @override
  String get selectCat => 'Katze wählen';

  @override
  String get saveReminder => 'Erinnerung speichern';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get signInToSeeBookmarks =>
      'Melden Sie sich an, um Lesezeichen zu sehen.';

  @override
  String get noBookmarksYet => 'Noch keine Lesezeichen';

  @override
  String get post => 'Beitrag';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Kommentare';

  @override
  String get report => 'Melden';

  @override
  String get reason => 'Grund';

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
  String get reminderDialogTitle => 'Erinnerung';

  @override
  String get time => 'Zeit';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get everyNDays => 'Alle N Tage';

  @override
  String get signInForFullFeatures =>
      'Nicht angemeldet. Bitte anmelden für volle Funktionen.';

  @override
  String get loadMore => 'Mehr laden';

  @override
  String get noCatsYetShort => 'Noch keine Katzen';

  @override
  String get selectCatLabel => 'Katze wählen';

  @override
  String get noneOption => '— Keine —';

  @override
  String get failedToLoadBreeds => 'Rassen konnten nicht geladen werden';

  @override
  String get addCatLabel => 'Katze hinzufügen';

  @override
  String get editCatLabel => 'Katze bearbeiten';

  @override
  String get dewormCycleDays => 'Entwurmungszyklus (Tage)';

  @override
  String get bathCycleDays => 'Badezyklus (Tage)';

  @override
  String get vaccineNextDate => 'Nächstes Impfdatum';

  @override
  String get notFound => 'Nicht gefunden';

  @override
  String get postNotFound => 'Beitrag nicht gefunden';

  @override
  String get latest => 'Neueste';

  @override
  String get hot => 'Beliebt';

  @override
  String get allBreeds => 'Alle Rassen';

  @override
  String get allTopics => 'Alle Themen';

  @override
  String get topicCare => 'Pflege';

  @override
  String get topicHealth => 'Gesundheit';

  @override
  String get topicFeeding => 'Füttern';

  @override
  String get topicBehavior => 'Verhalten';

  @override
  String get loadingRegionContent => 'Lade Inhalte für diese Region…';

  @override
  String get feedLoadFailed =>
      'Feed konnte nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get aiNavLabel => 'KI';

  @override
  String get aiErrorDescribeSymptom => 'Bitte beschreiben Sie die Symptome';

  @override
  String aiErrorFreeLimit(int count) {
    return 'Kostenlos: $count KI-Anfragen pro Tag. Upgrade auf Pro für unbegrenzt.';
  }

  @override
  String get aiModelLabel => 'Aktuelles Modell';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get me => 'Ich';

  @override
  String get planDay1 => 'Tag 1: Zuhause vorbereiten';

  @override
  String get planDay2 => 'Tag 2: Futter und Näpfe';

  @override
  String get planDay3 => 'Tag 3: Katzentoilette';

  @override
  String get planDay4 => 'Tag 4: Erster Tierarztbesuch';

  @override
  String get planDay5 => 'Tag 5: Pflege';

  @override
  String get planDay6 => 'Tag 6: Spielen und Bindung';

  @override
  String get planDay7 => 'Tag 7: Routine';
}
