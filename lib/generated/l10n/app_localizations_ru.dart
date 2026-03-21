// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => 'Напоминания о кормлении и здоровье для семьи';

  @override
  String get feed => 'Кормление';

  @override
  String get water => 'Сменить воду';

  @override
  String get litter => 'Уборка лотка';

  @override
  String get grooming => 'Уход';

  @override
  String get bath => 'Купание';

  @override
  String get deworm => 'Глисты';

  @override
  String get vaccine => 'Прививка';

  @override
  String get addCat => 'Добавить кота';

  @override
  String get addFirstCat => 'Добавить первого кота';

  @override
  String get editCat => 'Редактировать кота';

  @override
  String get todayCare => 'Забота сегодня';

  @override
  String get markDone => 'Сделано';

  @override
  String get allTasks => 'Все задачи';

  @override
  String get noTasksYet => 'Нет задач. Добавьте кота и создайте задачи.';

  @override
  String get aiSymptomSupport => 'ИИ-поддержка по симптомам';

  @override
  String aiTitleWithName(String catName) {
    return 'С $catName всё в порядке?';
  }

  @override
  String get aiTitleGeneric => 'Чем помочь?';

  @override
  String get aiSubtitle => 'Только информация. Не замена ветеринару.';

  @override
  String get aiHint => 'напр. чихание, потеря аппетита';

  @override
  String get getGuidance => 'Получить совет';

  @override
  String get guidance => 'Совет';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get signIn => 'Войти';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get register => 'Регистрация';

  @override
  String get createFamily => 'Создать семью';

  @override
  String get createFamilyDesc => 'Создайте семью, чтобы делить заботу о коте.';

  @override
  String get iHaveInviteCode => 'У меня есть код приглашения';

  @override
  String get yourInviteCode => 'Ваш код приглашения';

  @override
  String get continueToApp => 'Перейти в приложение';

  @override
  String get joinFamily => 'Вступить в семью';

  @override
  String get join => 'Вступить';

  @override
  String get createFamilyInstead => 'Создать семью вместо этого';

  @override
  String get inviteCode => 'Код приглашения';

  @override
  String get enterInviteCode => 'Введите код';

  @override
  String get invalidCode => 'Код недействителен или истёк';

  @override
  String get cats => 'Коты';

  @override
  String get noCatsYet => 'Нет котов';

  @override
  String get tasks => 'Задачи';

  @override
  String get addTask => 'Добавить задачу';

  @override
  String get newTask => 'Новая задача';

  @override
  String get editTask => 'Редактировать задачу';

  @override
  String get cat => 'Кот';

  @override
  String get reminder => 'Напоминание';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteCat => 'Удалить кота?';

  @override
  String get name => 'Имя';

  @override
  String get birthday => 'День рождения';

  @override
  String get weight => 'Вес (кг)';

  @override
  String get neutered => 'Стерилизован';

  @override
  String get activity => 'Активность';

  @override
  String get health => 'Здоровье';

  @override
  String get addCatFirstHealth =>
      'Сначала добавьте кота для записей о здоровье.';

  @override
  String get addHealthLog => 'Добавить запись о здоровье';

  @override
  String noHealthLogs(String catName) {
    return 'Пока нет записей для $catName';
  }

  @override
  String get type => 'Тип';

  @override
  String get note => 'Заметка';

  @override
  String get subscription => 'Подписка';

  @override
  String get free => 'Бесплатно';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => 'Текущий план';

  @override
  String freeCats(int count) {
    return '$count кот';
  }

  @override
  String freeMembers(int count) {
    return '$count участник (только вы)';
  }

  @override
  String freeAiPerDay(int count) {
    return '$count запросов ИИ в день';
  }

  @override
  String get multipleCats => 'Несколько котов';

  @override
  String get multipleMembers => 'Несколько участников';

  @override
  String get unlimitedAi => 'Безлимитные запросы ИИ';

  @override
  String get advancedReminders => 'Расширенные напоминания';

  @override
  String get upgradeToPro => 'Перейти на Pro (демо)';

  @override
  String get proActivated => 'Pro активирован (демо)';

  @override
  String get settings => 'Настройки';

  @override
  String get family => 'Семья';

  @override
  String get members => 'Участники';

  @override
  String get manageMembers => 'Управление участниками';

  @override
  String get leaveFamily => 'Выйти из семьи';

  @override
  String get leaveFamilyConfirm => 'Выйти из семьи?';

  @override
  String get leave => 'Выйти';

  @override
  String get signOut => 'Выйти из аккаунта';

  @override
  String get inviteCodeCopied => 'Код скопирован';

  @override
  String get familyMembers => 'Члены семьи';

  @override
  String get ok => 'OK';

  @override
  String get freeLimitOneCat => 'Бесплатно: 1 кот. Pro — для большего.';

  @override
  String get upgradeForFamilySharing => 'Pro для семейного доступа';

  @override
  String get upgradeForFamilySharingBody =>
      'С Pro — больше котов и приглашение семьи. Простой уход для всех.';

  @override
  String get goToSubscription => 'Смотреть Pro';

  @override
  String get email => 'Почта';

  @override
  String get password => 'Пароль';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get enterEmail => 'Введите почту';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get enterName => 'Введите имя';

  @override
  String get atLeast6Chars => 'Минимум 6 символов';

  @override
  String get home => 'Главная';

  @override
  String get today => 'Сегодня';

  @override
  String get severity => 'Степень';

  @override
  String get severityGreen => 'лёгкая';

  @override
  String get severityYellow => 'средняя';

  @override
  String get severityRed => 'тяжёлая';

  @override
  String get repeatDaily => 'ежедневно';

  @override
  String get repeatWeekly => 'еженедельно';

  @override
  String get repeatMonthly => 'ежемесячно';

  @override
  String get repeatCustom => 'своя';

  @override
  String get healthWeight => 'вес';

  @override
  String get healthDeworm => 'глисты';

  @override
  String get healthVaccine => 'прививка';

  @override
  String get healthNote => 'заметка';

  @override
  String get activityLow => 'низкая';

  @override
  String get activityMedium => 'средняя';

  @override
  String get activityHigh => 'высокая';

  @override
  String get language => 'Язык';

  @override
  String get languageFollowSystem => 'По системе';

  @override
  String get region => 'Регион';

  @override
  String get goToSettingsToSignIn =>
      'Войдите в настройках для доступа ко всем функциям.';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get myCats => 'Мои коты';

  @override
  String get signInToManageCats => 'Войдите, чтобы управлять котами';

  @override
  String get noCatsYetAddOne => 'Нет котов. Добавьте одного!';

  @override
  String get createPost => 'Создать запись';

  @override
  String get postButton => 'Опубликовать';

  @override
  String get submit => 'Отправить';

  @override
  String get title => 'Заголовок';

  @override
  String get summary => 'Кратко';

  @override
  String get content => 'Текст';

  @override
  String get contentTooLong =>
      'Текст слишком длинный. Сократите перед публикацией.';

  @override
  String get backendUrlNotConfigured => 'URL бэкенда не настроен.';

  @override
  String get pleaseSignIn => 'Войдите в аккаунт.';

  @override
  String get contentUpdated => 'Содержимое обновлено.';

  @override
  String get aiUnavailable => 'ИИ недоступен.';

  @override
  String aiUnavailableReason(String reason) {
    return 'ИИ недоступен: $reason';
  }

  @override
  String get failedToPost => 'Ошибка публикации';

  @override
  String get aiRewriteLabel => 'ИИ переписать';

  @override
  String get breeds => 'Породы';

  @override
  String get topics => 'Темы';

  @override
  String get selectBreed => 'Выбрать породу';

  @override
  String get publicProfile => 'Публичный профиль';

  @override
  String get yourNotes => 'Ваши заметки (опыт)';

  @override
  String get planTitle => '7-дневный план для новых владельцев';

  @override
  String get signInToStartPlan => 'Войдите, чтобы начать план';

  @override
  String get reminders => 'Напоминания';

  @override
  String get signInToSetReminders => 'Войдите, чтобы настроить напоминания';

  @override
  String get selectCat => 'Выбрать кота';

  @override
  String get saveReminder => 'Сохранить напоминание';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get signInToSeeBookmarks => 'Войдите, чтобы видеть закладки';

  @override
  String get noBookmarksYet => 'Нет закладок';

  @override
  String get post => 'Запись';

  @override
  String get likes => 'Likes';

  @override
  String get comments => 'Комментарии';

  @override
  String get report => 'Пожаловаться';

  @override
  String get reason => 'Причина';

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
  String get reminderDialogTitle => 'Напоминание';

  @override
  String get time => 'Время';

  @override
  String get repeat => 'Повтор';

  @override
  String get everyNDays => 'Каждые N дней';

  @override
  String get signInForFullFeatures => 'Вы не вошли. Войдите для всех функций.';

  @override
  String get loadMore => 'Ещё';

  @override
  String get noCatsYetShort => 'Нет котов';

  @override
  String get selectCatLabel => 'Выбрать кота';

  @override
  String get noneOption => '— Нет —';

  @override
  String get failedToLoadBreeds => 'Не удалось загрузить породы';

  @override
  String get addCatLabel => 'Добавить кота';

  @override
  String get editCatLabel => 'Редактировать кота';

  @override
  String get dewormCycleDays => 'Цикл глистогонки (дней)';

  @override
  String get bathCycleDays => 'Цикл купания (дней)';

  @override
  String get vaccineNextDate => 'Дата следующей прививки';

  @override
  String get notFound => 'Не найдено';

  @override
  String get postNotFound => 'Запись не найдена';

  @override
  String get latest => 'Новые';

  @override
  String get hot => 'Популярные';

  @override
  String get allBreeds => 'Все породы';

  @override
  String get allTopics => 'Все темы';

  @override
  String get topicCare => 'Уход';

  @override
  String get topicHealth => 'Здоровье';

  @override
  String get topicFeeding => 'Кормление';

  @override
  String get topicBehavior => 'Поведение';

  @override
  String get loadingRegionContent => 'Загрузка контента для этого региона…';

  @override
  String get feedLoadFailed => 'Не удалось загрузить ленту. Повторите попытку.';

  @override
  String get aiNavLabel => 'ИИ';

  @override
  String get aiErrorDescribeSymptom => 'Опишите симптом';

  @override
  String aiErrorFreeLimit(int count) {
    return 'Бесплатно: $count запросов ИИ в день. Pro — без лимита.';
  }

  @override
  String get aiModelLabel => 'Текущая модель';

  @override
  String get retry => 'Повторить';

  @override
  String get me => 'Я';

  @override
  String get planDay1 => 'День 1: Подготовка дома';

  @override
  String get planDay2 => 'День 2: Корм и миски';

  @override
  String get planDay3 => 'День 3: Лоток';

  @override
  String get planDay4 => 'День 4: Первый визит к ветеринару';

  @override
  String get planDay5 => 'День 5: Уход';

  @override
  String get planDay6 => 'День 6: Игры и контакт';

  @override
  String get planDay7 => 'День 7: Режим';
}
