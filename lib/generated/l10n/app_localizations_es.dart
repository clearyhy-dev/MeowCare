// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => 'Recordatorios de alimentación y salud en familia';

  @override
  String get feed => 'Alimentar';

  @override
  String get water => 'Cambiar agua';

  @override
  String get litter => 'Limpiar arenero';

  @override
  String get grooming => 'Cepillado';

  @override
  String get bath => 'Baño';

  @override
  String get deworm => 'Desparasitar';

  @override
  String get vaccine => 'Vacuna';

  @override
  String get addCat => 'Añadir gato';

  @override
  String get addFirstCat => 'Añadir primer gato';

  @override
  String get editCat => 'Editar gato';

  @override
  String get todayCare => 'Cuidados de hoy';

  @override
  String get markDone => 'Marcar hecho';

  @override
  String get allTasks => 'Todas las tareas';

  @override
  String get noTasksYet => 'Sin tareas. Añade un gato y crea tareas.';

  @override
  String get aiSymptomSupport => 'Ayuda de síntomas con IA';

  @override
  String aiTitleWithName(String catName) {
    return '¿$catName se encuentra bien?';
  }

  @override
  String get aiTitleGeneric => '¿Cómo podemos ayudar?';

  @override
  String get aiSubtitle => 'Solo informativo. No sustituye al veterinario.';

  @override
  String get aiHint => 'ej. estornudos, pérdida de apetito';

  @override
  String get getGuidance => 'Obtener orientación';

  @override
  String get guidance => 'Orientación';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get register => 'Registrarse';

  @override
  String get createFamily => 'Crear familia';

  @override
  String get createFamilyDesc =>
      'Crea una familia para compartir el cuidado del gato.';

  @override
  String get iHaveInviteCode => 'Tengo un código de invitación';

  @override
  String get yourInviteCode => 'Tu código de invitación';

  @override
  String get continueToApp => 'Continuar a la app';

  @override
  String get joinFamily => 'Unirse a familia';

  @override
  String get join => 'Unirse';

  @override
  String get createFamilyInstead => 'Crear familia en su lugar';

  @override
  String get inviteCode => 'Código de invitación';

  @override
  String get enterInviteCode => 'Introducir código';

  @override
  String get invalidCode => 'Código inválido o caducado';

  @override
  String get cats => 'Gatos';

  @override
  String get noCatsYet => 'Sin gatos';

  @override
  String get tasks => 'Tareas';

  @override
  String get addTask => 'Añadir tarea';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get cat => 'Gato';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteCat => '¿Eliminar gato?';

  @override
  String get name => 'Nombre';

  @override
  String get birthday => 'Cumpleaños';

  @override
  String get weight => 'Peso (kg)';

  @override
  String get neutered => 'Esterilizado';

  @override
  String get activity => 'Actividad';

  @override
  String get health => 'Salud';

  @override
  String get addCatFirstHealth => 'Añade un gato para el historial de salud.';

  @override
  String get addHealthLog => 'Añadir registro de salud';

  @override
  String noHealthLogs(String catName) {
    return 'Aún no hay registros de $catName';
  }

  @override
  String get type => 'Tipo';

  @override
  String get note => 'Nota';

  @override
  String get subscription => 'Suscripción';

  @override
  String get free => 'Gratis';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => 'Plan actual';

  @override
  String freeCats(int count) {
    return '$count gato';
  }

  @override
  String freeMembers(int count) {
    return '$count miembro (solo tú)';
  }

  @override
  String freeAiPerDay(int count) {
    return '$count consultas IA al día';
  }

  @override
  String get multipleCats => 'Varios gatos';

  @override
  String get multipleMembers => 'Varios miembros';

  @override
  String get unlimitedAi => 'Consultas IA ilimitadas';

  @override
  String get advancedReminders => 'Recordatorios avanzados';

  @override
  String get upgradeToPro => 'Pasar a Pro (demo)';

  @override
  String get proActivated => 'Pro activado (demo)';

  @override
  String get settings => 'Ajustes';

  @override
  String get family => 'Familia';

  @override
  String get members => 'Miembros';

  @override
  String get manageMembers => 'Gestionar miembros';

  @override
  String get leaveFamily => 'Salir de familia';

  @override
  String get leaveFamilyConfirm => '¿Salir de familia?';

  @override
  String get leave => 'Salir';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get inviteCodeCopied => 'Código copiado';

  @override
  String get familyMembers => 'Miembros de la familia';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat => 'Gratis: 1 gato. Pasa a Pro para más.';

  @override
  String get upgradeForFamilySharing => 'Pro para compartir en familia';

  @override
  String get upgradeForFamilySharingBody =>
      'Con Pro, más gatos e invitar familia. Cuidados sencillos para todos.';

  @override
  String get goToSubscription => 'Ver Pro';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get displayName => 'Nombre para mostrar';

  @override
  String get enterEmail => 'Introducir correo';

  @override
  String get enterPassword => 'Introducir contraseña';

  @override
  String get enterName => 'Introducir nombre';

  @override
  String get atLeast6Chars => 'Al menos 6 caracteres';

  @override
  String get home => 'Inicio';

  @override
  String get today => 'Hoy';

  @override
  String get severity => 'Gravedad';

  @override
  String get severityGreen => 'leve';

  @override
  String get severityYellow => 'medio';

  @override
  String get severityRed => 'grave';

  @override
  String get repeatDaily => 'diario';

  @override
  String get repeatWeekly => 'semanal';

  @override
  String get repeatMonthly => 'mensual';

  @override
  String get repeatCustom => 'personalizado';

  @override
  String get healthWeight => 'peso';

  @override
  String get healthDeworm => 'desparasitación';

  @override
  String get healthVaccine => 'vacuna';

  @override
  String get healthNote => 'nota';

  @override
  String get activityLow => 'bajo';

  @override
  String get activityMedium => 'medio';

  @override
  String get activityHigh => 'alto';

  @override
  String get language => 'Idioma';

  @override
  String get languageFollowSystem => 'Seguir sistema';

  @override
  String get region => 'Región';

  @override
  String get goToSettingsToSignIn =>
      'Ve a Ajustes e inicia sesión para usar todas las funciones.';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get myCats => 'Mis gatos';

  @override
  String get signInToManageCats => 'Inicia sesión para gestionar tus gatos';

  @override
  String get noCatsYetAddOne => 'Aún no hay gatos. ¡Añade uno!';

  @override
  String get createPost => 'Crear publicación';

  @override
  String get postButton => 'Publicar';

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
  String get submit => 'Enviar';

  @override
  String get title => 'Título';

  @override
  String get summary => 'Resumen';

  @override
  String get content => 'Contenido';

  @override
  String get contentTooLong =>
      'Contenido demasiado largo. Acorta antes de publicar.';

  @override
  String get backendUrlNotConfigured => 'URL del backend no configurada.';

  @override
  String get pleaseSignIn => 'Inicia sesión.';

  @override
  String get contentUpdated => 'Contenido actualizado.';

  @override
  String get aiUnavailable => 'IA no disponible.';

  @override
  String aiUnavailableReason(String reason) {
    return 'IA no disponible: $reason';
  }

  @override
  String get failedToPost => 'Error al publicar';

  @override
  String get aiRewriteLabel => 'Reescribir con IA';

  @override
  String get breeds => 'Razas';

  @override
  String get topics => 'Temas';

  @override
  String get selectBreed => 'Seleccionar raza';

  @override
  String get publicProfile => 'Perfil público';

  @override
  String get yourNotes => 'Tus notas (experiencia)';

  @override
  String get planTitle => 'Plan de 7 días para nuevos dueños';

  @override
  String get signInToStartPlan => 'Inicia sesión para empezar el plan';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get signInToSetReminders =>
      'Inicia sesión para configurar recordatorios';

  @override
  String get selectCat => 'Seleccionar gato';

  @override
  String get saveReminder => 'Guardar recordatorio';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get signInToSeeBookmarks => 'Inicia sesión para ver marcadores';

  @override
  String get noBookmarksYet => 'Aún no hay marcadores';

  @override
  String get post => 'Publicación';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Comentarios';

  @override
  String get report => 'Reportar';

  @override
  String get reason => 'Motivo';

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
  String get reminderDialogTitle => 'Recordatorio';

  @override
  String get time => 'Hora';

  @override
  String get repeat => 'Repetir';

  @override
  String get everyNDays => 'Cada N días';

  @override
  String get signInForFullFeatures =>
      'No has iniciado sesión. Inicia sesión para usar todas las funciones.';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get noCatsYetShort => 'Aún no hay gatos';

  @override
  String get selectCatLabel => 'Seleccionar gato';

  @override
  String get noneOption => '— Ninguno —';

  @override
  String get failedToLoadBreeds => 'Error al cargar razas';

  @override
  String get addCatLabel => 'Añadir gato';

  @override
  String get editCatLabel => 'Editar gato';

  @override
  String get dewormCycleDays => 'Ciclo de desparasitación (días)';

  @override
  String get bathCycleDays => 'Ciclo de baño (días)';

  @override
  String get vaccineNextDate => 'Próxima fecha de vacuna';

  @override
  String get notFound => 'No encontrado';

  @override
  String get postNotFound => 'Publicación no encontrada';

  @override
  String get latest => 'Recientes';

  @override
  String get hot => 'Popular';

  @override
  String get allBreeds => 'Todas las razas';

  @override
  String get allTopics => 'Todos los temas';

  @override
  String get topicCare => 'Cuidados';

  @override
  String get topicHealth => 'Salud';

  @override
  String get topicFeeding => 'Alimentación';

  @override
  String get topicBehavior => 'Comportamiento';

  @override
  String get loadingRegionContent => 'Cargando contenido de esta región…';

  @override
  String get feedLoadFailed => 'Error al cargar el feed. Inténtalo de nuevo.';

  @override
  String get feedNoContent => 'No content for this topic yet.';

  @override
  String get aiNavLabel => 'IA';

  @override
  String get aiErrorDescribeSymptom => 'Describe el síntoma';

  @override
  String aiErrorFreeLimit(int count) {
    return 'Límite gratis: $count consultas IA al día. Pasa a Pro para ilimitadas.';
  }

  @override
  String get aiModelLabel => 'Modelo actual';

  @override
  String get retry => 'Reintentar';

  @override
  String get searchPostsHint => 'Search by title, content, or #topic';

  @override
  String get noResultFound => 'No matching posts found.';

  @override
  String get me => 'Yo';

  @override
  String get planDay1 => 'Día 1: Preparar la casa';

  @override
  String get planDay2 => 'Día 2: Comida y cuencos';

  @override
  String get planDay3 => 'Día 3: Arena';

  @override
  String get planDay4 => 'Día 4: Primera visita al veterinario';

  @override
  String get planDay5 => 'Día 5: Cepillado';

  @override
  String get planDay6 => 'Día 6: Juego y vínculo';

  @override
  String get planDay7 => 'Día 7: Rutina';

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
}
