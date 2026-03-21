// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => 'Rappels repas et santé en famille';

  @override
  String get feed => 'Nourrir';

  @override
  String get water => 'Changer l\'eau';

  @override
  String get litter => 'Nettoyer la litière';

  @override
  String get grooming => 'Toilettage';

  @override
  String get bath => 'Bain';

  @override
  String get deworm => 'Vermifuge';

  @override
  String get vaccine => 'Vaccin';

  @override
  String get addCat => 'Ajouter un chat';

  @override
  String get addFirstCat => 'Ajouter le premier chat';

  @override
  String get editCat => 'Modifier le chat';

  @override
  String get todayCare => 'Soins du jour';

  @override
  String get markDone => 'Marquer fait';

  @override
  String get allTasks => 'Toutes les tâches';

  @override
  String get noTasksYet => 'Aucune tâche. Ajoutez un chat et créez des tâches.';

  @override
  String get aiSymptomSupport => 'Aide symptômes IA';

  @override
  String aiTitleWithName(String catName) {
    return '$catName va bien ?';
  }

  @override
  String get aiTitleGeneric => 'Comment vous aider ?';

  @override
  String get aiSubtitle =>
      'Information uniquement. Ne remplace pas un vétérinaire.';

  @override
  String get aiHint => 'ex. éternuements, perte d\'appétit';

  @override
  String get getGuidance => 'Obtenir des conseils';

  @override
  String get guidance => 'Conseils';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signIn => 'Connexion';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get register => 'S\'inscrire';

  @override
  String get createFamily => 'Créer une famille';

  @override
  String get createFamilyDesc =>
      'Créez une famille pour partager les soins du chat.';

  @override
  String get iHaveInviteCode => 'J\'ai un code d\'invitation';

  @override
  String get yourInviteCode => 'Votre code d\'invitation';

  @override
  String get continueToApp => 'Continuer vers l\'app';

  @override
  String get joinFamily => 'Rejoindre une famille';

  @override
  String get join => 'Rejoindre';

  @override
  String get createFamilyInstead => 'Créer une famille à la place';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get enterInviteCode => 'Entrer le code d\'invitation';

  @override
  String get invalidCode => 'Code invalide ou expiré';

  @override
  String get cats => 'Chats';

  @override
  String get noCatsYet => 'Aucun chat';

  @override
  String get tasks => 'Tâches';

  @override
  String get addTask => 'Ajouter une tâche';

  @override
  String get newTask => 'Nouvelle tâche';

  @override
  String get editTask => 'Modifier la tâche';

  @override
  String get cat => 'Chat';

  @override
  String get reminder => 'Rappel';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteCat => 'Supprimer le chat ?';

  @override
  String get name => 'Nom';

  @override
  String get birthday => 'Anniversaire';

  @override
  String get weight => 'Poids (kg)';

  @override
  String get neutered => 'Stérilisé';

  @override
  String get activity => 'Activité';

  @override
  String get health => 'Santé';

  @override
  String get addCatFirstHealth =>
      'Ajoutez d\'abord un chat pour le carnet de santé.';

  @override
  String get addHealthLog => 'Ajouter une entrée santé';

  @override
  String noHealthLogs(String catName) {
    return 'Pas encore d\'entrées pour $catName';
  }

  @override
  String get type => 'Type';

  @override
  String get note => 'Note';

  @override
  String get subscription => 'Abonnement';

  @override
  String get free => 'Gratuit';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => 'Offre actuelle';

  @override
  String freeCats(int count) {
    return '$count chat';
  }

  @override
  String freeMembers(int count) {
    return '$count membre (vous seul)';
  }

  @override
  String freeAiPerDay(int count) {
    return '$count requêtes IA par jour';
  }

  @override
  String get multipleCats => 'Plusieurs chats';

  @override
  String get multipleMembers => 'Plusieurs membres';

  @override
  String get unlimitedAi => 'Requêtes IA illimitées';

  @override
  String get advancedReminders => 'Rappels avancés';

  @override
  String get upgradeToPro => 'Passer à Pro (démo)';

  @override
  String get proActivated => 'Pro activé (démo)';

  @override
  String get settings => 'Paramètres';

  @override
  String get family => 'Famille';

  @override
  String get members => 'Membres';

  @override
  String get manageMembers => 'Gérer les membres';

  @override
  String get leaveFamily => 'Quitter la famille';

  @override
  String get leaveFamilyConfirm => 'Quitter la famille ?';

  @override
  String get leave => 'Quitter';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get inviteCodeCopied => 'Code copié';

  @override
  String get familyMembers => 'Membres de la famille';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat => 'Gratuit : 1 chat. Passez à Pro pour plus.';

  @override
  String get upgradeForFamilySharing => 'Pro pour le partage familial';

  @override
  String get upgradeForFamilySharingBody =>
      'Avec Pro, plus de chats et inviter la famille. Soins simples pour tous.';

  @override
  String get goToSubscription => 'Voir Pro';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get displayName => 'Nom d\'affichage';

  @override
  String get enterEmail => 'Entrer l\'e-mail';

  @override
  String get enterPassword => 'Entrer le mot de passe';

  @override
  String get enterName => 'Entrer le nom';

  @override
  String get atLeast6Chars => 'Au moins 6 caractères';

  @override
  String get home => 'Accueil';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get severity => 'Gravité';

  @override
  String get severityGreen => 'léger';

  @override
  String get severityYellow => 'moyen';

  @override
  String get severityRed => 'grave';

  @override
  String get repeatDaily => 'quotidien';

  @override
  String get repeatWeekly => 'hebdomadaire';

  @override
  String get repeatMonthly => 'mensuel';

  @override
  String get repeatCustom => 'personnalisé';

  @override
  String get healthWeight => 'poids';

  @override
  String get healthDeworm => 'vermifuge';

  @override
  String get healthVaccine => 'vaccin';

  @override
  String get healthNote => 'note';

  @override
  String get activityLow => 'faible';

  @override
  String get activityMedium => 'moyen';

  @override
  String get activityHigh => 'élevé';

  @override
  String get language => 'Langue';

  @override
  String get languageFollowSystem => 'Suivre le système';

  @override
  String get region => 'Région';

  @override
  String get goToSettingsToSignIn =>
      'Allez dans Paramètres et connectez-vous pour accéder à toutes les fonctionnalités.';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get myCats => 'Mes chats';

  @override
  String get signInToManageCats => 'Connectez-vous pour gérer vos chats';

  @override
  String get noCatsYetAddOne => 'Aucun chat. Ajoutez-en un !';

  @override
  String get createPost => 'Créer une publication';

  @override
  String get postButton => 'Publier';

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
  String get submit => 'Envoyer';

  @override
  String get title => 'Titre';

  @override
  String get summary => 'Résumé';

  @override
  String get content => 'Contenu';

  @override
  String get contentTooLong =>
      'Contenu trop long. Veuillez raccourcir avant de publier.';

  @override
  String get backendUrlNotConfigured => 'URL backend non configurée.';

  @override
  String get pleaseSignIn => 'Veuillez vous connecter.';

  @override
  String get contentUpdated => 'Contenu mis à jour.';

  @override
  String get aiUnavailable => 'IA indisponible.';

  @override
  String aiUnavailableReason(String reason) {
    return 'IA indisponible : $reason';
  }

  @override
  String get failedToPost => 'Échec de la publication';

  @override
  String get aiRewriteLabel => 'Réécriture IA';

  @override
  String get breeds => 'Races';

  @override
  String get topics => 'Sujets';

  @override
  String get selectBreed => 'Choisir une race';

  @override
  String get publicProfile => 'Profil public';

  @override
  String get yourNotes => 'Vos notes (expérience)';

  @override
  String get planTitle => 'Plan 7 jours pour nouveaux maîtres';

  @override
  String get signInToStartPlan => 'Connectez-vous pour commencer le plan';

  @override
  String get reminders => 'Rappels';

  @override
  String get signInToSetReminders => 'Connectez-vous pour définir des rappels';

  @override
  String get selectCat => 'Choisir un chat';

  @override
  String get saveReminder => 'Enregistrer le rappel';

  @override
  String get bookmarks => 'Favoris';

  @override
  String get signInToSeeBookmarks => 'Connectez-vous pour voir les favoris';

  @override
  String get noBookmarksYet => 'Aucun favori';

  @override
  String get post => 'Publication';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Commentaires';

  @override
  String get report => 'Signaler';

  @override
  String get reason => 'Raison';

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
  String get reminderDialogTitle => 'Rappel';

  @override
  String get time => 'Heure';

  @override
  String get repeat => 'Répéter';

  @override
  String get everyNDays => 'Tous les N jours';

  @override
  String get signInForFullFeatures =>
      'Non connecté. Connectez-vous pour toutes les fonctionnalités.';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get noCatsYetShort => 'Aucun chat';

  @override
  String get selectCatLabel => 'Choisir un chat';

  @override
  String get noneOption => '— Aucun —';

  @override
  String get failedToLoadBreeds => 'Échec du chargement des races';

  @override
  String get addCatLabel => 'Ajouter un chat';

  @override
  String get editCatLabel => 'Modifier le chat';

  @override
  String get dewormCycleDays => 'Cycle vermifuge (jours)';

  @override
  String get bathCycleDays => 'Cycle bain (jours)';

  @override
  String get vaccineNextDate => 'Prochaine date de vaccin';

  @override
  String get notFound => 'Introuvable';

  @override
  String get postNotFound => 'Publication introuvable';

  @override
  String get latest => 'Récent';

  @override
  String get hot => 'Tendances';

  @override
  String get allBreeds => 'Toutes les races';

  @override
  String get allTopics => 'Tous les sujets';

  @override
  String get topicCare => 'Soins';

  @override
  String get topicHealth => 'Santé';

  @override
  String get topicFeeding => 'Alimentation';

  @override
  String get topicBehavior => 'Comportement';

  @override
  String get loadingRegionContent => 'Chargement du contenu pour cette région…';

  @override
  String get feedLoadFailed =>
      'Échec du chargement du fil. Veuillez réessayer.';

  @override
  String get feedNoContent => 'No content for this topic yet.';

  @override
  String get aiNavLabel => 'IA';

  @override
  String get aiErrorDescribeSymptom => 'Veuillez décrire le symptôme';

  @override
  String aiErrorFreeLimit(int count) {
    return 'Gratuit : $count requêtes IA par jour. Passez à Pro pour illimité.';
  }

  @override
  String get aiModelLabel => 'Modèle actuel';

  @override
  String get retry => 'Réessayer';

  @override
  String get me => 'Moi';

  @override
  String get planDay1 => 'Jour 1 : Préparer la maison';

  @override
  String get planDay2 => 'Jour 2 : Nourriture et gamelles';

  @override
  String get planDay3 => 'Jour 3 : Litière';

  @override
  String get planDay4 => 'Jour 4 : Première visite vétérinaire';

  @override
  String get planDay5 => 'Jour 5 : Toilettage';

  @override
  String get planDay6 => 'Jour 6 : Jeu et lien';

  @override
  String get planDay7 => 'Jour 7 : Routine';

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
}
