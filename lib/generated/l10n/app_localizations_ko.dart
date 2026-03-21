// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MeowCare';

  @override
  String get appSubtitle => '가족 고양이 급여·건강 리마인더';

  @override
  String get feed => '급여';

  @override
  String get water => '물 갈기';

  @override
  String get litter => '화장실 청소';

  @override
  String get grooming => '그루밍';

  @override
  String get bath => '목욕';

  @override
  String get deworm => '구충';

  @override
  String get vaccine => '예방접종';

  @override
  String get addCat => '고양이 추가';

  @override
  String get addFirstCat => '첫 고양이 추가';

  @override
  String get editCat => '고양이 수정';

  @override
  String get todayCare => '오늘의 케어';

  @override
  String get markDone => '완료';

  @override
  String get allTasks => '모든 작업';

  @override
  String get noTasksYet => '아직 작업이 없습니다. 고양이를 추가하고 작업을 만드세요.';

  @override
  String get aiSymptomSupport => 'AI 증상 지원';

  @override
  String aiTitleWithName(String catName) {
    return '$catName 상태가 어떠신가요?';
  }

  @override
  String get aiTitleGeneric => '무엇을 도와드릴까요?';

  @override
  String get aiSubtitle => '정보 제공만을 위한 것입니다. 수의사의 진료를 대체하지 않습니다.';

  @override
  String get aiHint => '예: 재채기, 식욕 부진';

  @override
  String get getGuidance => '안내 보기';

  @override
  String get guidance => '안내';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get signIn => '로그인';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get register => '가입';

  @override
  String get createFamily => '가족 만들기';

  @override
  String get createFamilyDesc => '가족을 만들어 고양이 케어를 함께 공유하세요.';

  @override
  String get iHaveInviteCode => '초대 코드가 있어요';

  @override
  String get yourInviteCode => '초대 코드';

  @override
  String get continueToApp => '앱으로 계속';

  @override
  String get joinFamily => '가족에 참여';

  @override
  String get join => '참여';

  @override
  String get createFamilyInstead => '가족 새로 만들기';

  @override
  String get inviteCode => '초대 코드';

  @override
  String get enterInviteCode => '초대 코드 입력';

  @override
  String get invalidCode => '잘못되었거나 만료된 코드입니다';

  @override
  String get cats => '고양이';

  @override
  String get noCatsYet => '고양이가 없습니다';

  @override
  String get tasks => '작업';

  @override
  String get addTask => '작업 추가';

  @override
  String get newTask => '새 작업';

  @override
  String get editTask => '작업 수정';

  @override
  String get cat => '고양이';

  @override
  String get reminder => '리마인더';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get deleteCat => '고양이를 삭제할까요?';

  @override
  String get name => '이름';

  @override
  String get birthday => '생일';

  @override
  String get weight => '체중(kg)';

  @override
  String get neutered => '중성화됨';

  @override
  String get activity => '활동량';

  @override
  String get health => '건강';

  @override
  String get addCatFirstHealth => '건강 기록을 위해 먼저 고양이를 추가하세요.';

  @override
  String get addHealthLog => '건강 기록 추가';

  @override
  String noHealthLogs(String catName) {
    return '$catName의 건강 기록이 아직 없습니다';
  }

  @override
  String get type => '유형';

  @override
  String get note => '메모';

  @override
  String get subscription => '구독';

  @override
  String get free => '무료';

  @override
  String get pro => 'Pro';

  @override
  String get currentPlan => '현재 플랜';

  @override
  String freeCats(int count) {
    return '고양이 $count마리';
  }

  @override
  String freeMembers(int count) {
    return '멤버 $count명 (본인만)';
  }

  @override
  String freeAiPerDay(int count) {
    return '하루 AI $count회';
  }

  @override
  String get multipleCats => '고양이 여러 마리';

  @override
  String get multipleMembers => '가족 여러 명';

  @override
  String get unlimitedAi => 'AI 무제한';

  @override
  String get advancedReminders => '고급 리마인더';

  @override
  String get upgradeToPro => 'Pro 업그레이드 (데모)';

  @override
  String get proActivated => 'Pro가 활성화되었습니다 (데모)';

  @override
  String get settings => '설정';

  @override
  String get family => '가족';

  @override
  String get members => '멤버';

  @override
  String get manageMembers => '멤버 관리';

  @override
  String get leaveFamily => '가족 나가기';

  @override
  String get leaveFamilyConfirm => '가족에서 나가시겠습니까?';

  @override
  String get leave => '나가기';

  @override
  String get signOut => '로그아웃';

  @override
  String get inviteCodeCopied => '초대 코드가 복사되었습니다';

  @override
  String get familyMembers => '가족 멤버';

  @override
  String get ok => '확인';

  @override
  String get freeLimitOneCat => '무료 플랜은 고양이 1마리까지입니다. 더 많이 쓰려면 Pro로.';

  @override
  String get upgradeForFamilySharing => 'Pro로 가족과 공유';

  @override
  String get upgradeForFamilySharingBody =>
      'Pro로 고양이를 더 추가하고 가족을 초대하세요. 따뜻하고 간단한 케어.';

  @override
  String get goToSubscription => 'Pro 보기';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get displayName => '표시 이름';

  @override
  String get enterEmail => '이메일 입력';

  @override
  String get enterPassword => '비밀번호 입력';

  @override
  String get enterName => '이름 입력';

  @override
  String get atLeast6Chars => '6자 이상';

  @override
  String get home => '홈';

  @override
  String get today => '오늘';

  @override
  String get severity => '심각도';

  @override
  String get severityGreen => '가벼움';

  @override
  String get severityYellow => '보통';

  @override
  String get severityRed => '심함';

  @override
  String get repeatDaily => '매일';

  @override
  String get repeatWeekly => '매주';

  @override
  String get repeatMonthly => '매월';

  @override
  String get repeatCustom => '맞춤';

  @override
  String get healthWeight => '체중';

  @override
  String get healthDeworm => '구충';

  @override
  String get healthVaccine => '예방접종';

  @override
  String get healthNote => '메모';

  @override
  String get activityLow => '낮음';

  @override
  String get activityMedium => '보통';

  @override
  String get activityHigh => '높음';

  @override
  String get language => '언어';

  @override
  String get languageFollowSystem => '시스템 설정 따르기';

  @override
  String get region => '국가/지역';

  @override
  String get goToSettingsToSignIn => '설정에서 로그인하면 모든 기능을 사용할 수 있습니다.';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get myCats => '내 고양이';

  @override
  String get signInToManageCats => '로그인하여 고양이를 관리하세요';

  @override
  String get noCatsYetAddOne => '아직 고양이가 없습니다. 추가해 보세요!';

  @override
  String get createPost => '게시글 작성';

  @override
  String get postButton => '게시';

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
  String get submit => '제출';

  @override
  String get title => '제목';

  @override
  String get summary => '요약';

  @override
  String get content => '내용';

  @override
  String get contentTooLong => '내용이 너무 깁니다. 짧게 줄인 후 게시해 주세요.';

  @override
  String get backendUrlNotConfigured => '백엔드 URL이 설정되지 않았습니다.';

  @override
  String get pleaseSignIn => '로그인해 주세요.';

  @override
  String get contentUpdated => '내용이 업데이트되었습니다.';

  @override
  String get aiUnavailable => 'AI를 사용할 수 없습니다.';

  @override
  String aiUnavailableReason(String reason) {
    return 'AI 사용 불가: $reason';
  }

  @override
  String get failedToPost => '게시 실패';

  @override
  String get aiRewriteLabel => 'AI 다시 쓰기';

  @override
  String get breeds => '품종';

  @override
  String get topics => '주제';

  @override
  String get selectBreed => '품종 선택';

  @override
  String get publicProfile => '공개 프로필';

  @override
  String get yourNotes => '메모 (경험)';

  @override
  String get planTitle => '7일 새 집사 플랜';

  @override
  String get signInToStartPlan => '로그인하여 플랜 시작';

  @override
  String get reminders => '알림';

  @override
  String get signInToSetReminders => '로그인하여 알림 설정';

  @override
  String get selectCat => '고양이 선택';

  @override
  String get saveReminder => '알림 저장';

  @override
  String get bookmarks => '북마크';

  @override
  String get signInToSeeBookmarks => '로그인하여 북마크 보기';

  @override
  String get noBookmarksYet => '아직 북마크가 없습니다';

  @override
  String get post => '게시글';

  @override
  String get likes => 'Likes';

  @override
  String get comments => '댓글';

  @override
  String get report => '신고';

  @override
  String get reason => '사유';

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
  String get reminderDialogTitle => '알림';

  @override
  String get time => '시간';

  @override
  String get repeat => '반복';

  @override
  String get everyNDays => 'N일마다';

  @override
  String get signInForFullFeatures => '로그인하지 않았습니다. 로그인하면 모든 기능을 사용할 수 있습니다.';

  @override
  String get loadMore => '더 보기';

  @override
  String get noCatsYetShort => '아직 고양이가 없습니다';

  @override
  String get selectCatLabel => '고양이 선택';

  @override
  String get noneOption => '— 없음 —';

  @override
  String get failedToLoadBreeds => '품종을 불러오지 못했습니다';

  @override
  String get addCatLabel => '고양이 추가';

  @override
  String get editCatLabel => '고양이 편집';

  @override
  String get dewormCycleDays => '구충 주기(일)';

  @override
  String get bathCycleDays => '목욕 주기(일)';

  @override
  String get vaccineNextDate => '다음 예방접종일';

  @override
  String get notFound => '찾을 수 없음';

  @override
  String get postNotFound => '게시글을 찾을 수 없습니다';

  @override
  String get latest => '최신';

  @override
  String get hot => '인기';

  @override
  String get allBreeds => '전체 품종';

  @override
  String get allTopics => '전체 주제';

  @override
  String get topicCare => '케어';

  @override
  String get topicHealth => '건강';

  @override
  String get topicFeeding => '급여';

  @override
  String get topicBehavior => '행동';

  @override
  String get loadingRegionContent => '해당 지역 콘텐츠를 불러오는 중…';

  @override
  String get feedLoadFailed => '피드를 불러오지 못했습니다. 다시 시도해 주세요.';

  @override
  String get aiNavLabel => 'AI';

  @override
  String get aiErrorDescribeSymptom => '증상을 입력해 주세요';

  @override
  String aiErrorFreeLimit(int count) {
    return '무료는 하루 $count회까지. Pro로 무제한.';
  }

  @override
  String get aiModelLabel => '현재 모델';

  @override
  String get retry => '다시 시도';

  @override
  String get me => '나';

  @override
  String get planDay1 => '1일: 집 준비';

  @override
  String get planDay2 => '2일: 사료와 그릇';

  @override
  String get planDay3 => '3일: 화장실';

  @override
  String get planDay4 => '4일: 첫 병원';

  @override
  String get planDay5 => '5일: 그루밍';

  @override
  String get planDay6 => '6일: 놀이와 유대';

  @override
  String get planDay7 => '7일: 루틴';
}
