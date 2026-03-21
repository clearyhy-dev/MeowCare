import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/l10n_ext.dart';
import '../../models/user_model.dart';
import '../../screens/ai/ai_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/cats/cats_screen.dart';
import '../../screens/family/create_family_screen.dart';
import '../../screens/family/join_family_screen.dart';
import '../../screens/feed/home_page.dart';
import '../../screens/feed/post_detail_page.dart';
import '../../screens/feed/create_post_page.dart';
import '../../screens/cats/my_cats_page.dart';
import '../../screens/cats/cat_edit_page.dart';
import '../../screens/health/health_screen.dart';
import '../../screens/plan/plan_page.dart';
import '../../screens/reminder/reminder_page.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/subscription/subscription_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/primary_fab.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String auth = '/auth';
  /// 旧版邮箱注册链接，重定向到 [auth]。
  static const String registerLegacy = '/register';
  static const String createFamily = '/family/create';
  static const String joinFamily = '/family/join';
  static const String home = '/';
  static const String cats = '/cats';
  static const String tasks = '/tasks';
  static const String health = '/health';
  static const String ai = '/ai';
  static const String subscription = '/subscription';
  static const String settings = '/settings';
  static const String postDetail = '/post';
  static const String postCreate = '/post/create';
  static const String myCats = '/my-cats';
  static const String catEdit = '/cat/edit';
  static const String plan = '/plan';
  static const String reminder = '/reminder';

  static GoRouter createRouter(GoRouterRefreshNotifier refreshNotifier) {
    return GoRouter(
      refreshListenable: refreshNotifier,
      initialLocation: splash,
      redirect: (context, state) {
        final location = state.uri.path;
        if (location == registerLegacy) return auth;

        if (refreshNotifier.isLoading) {
          if (location == splash) return null;
          return splash;
        }

        if (location == splash) {
          final fbu = refreshNotifier.firebaseUser;
          if (fbu == null) return home;
          final user = refreshNotifier.profile;
          if (user == null || user.familyId == null || user.familyId!.isEmpty) {
            return createFamily;
          }
          return home;
        }

        final fbu = refreshNotifier.firebaseUser;
        if (fbu == null) {
          if (location == createFamily || location == joinFamily) return auth;
          return null;
        }

        final user = refreshNotifier.profile;
        if (user == null || user.familyId == null || user.familyId!.isEmpty) {
          if (location == createFamily || location == joinFamily) return null;
          return createFamily;
        }

        if (location == auth || location == createFamily || location == joinFamily) {
          return home;
        }
        return null;
      },
      routes: [
        GoRoute(path: splash, builder: (context, state) => const _AuthSplashPage()),
        GoRoute(path: auth, builder: (context, state) => const LoginScreen()),
        GoRoute(path: createFamily, builder: (context, state) => const CreateFamilyScreen()),
        GoRoute(path: joinFamily, builder: (context, state) => const JoinFamilyScreen()),
        GoRoute(
          path: home,
          builder: (context, state) => const MainShell(),
          routes: [
            GoRoute(path: 'cats', builder: (context, state) => const CatsScreen()),
            GoRoute(path: 'tasks', builder: (context, state) => const TasksScreen()),
            GoRoute(path: 'health', builder: (context, state) => const HealthScreen()),
            GoRoute(path: 'ai', builder: (context, state) => const AIScreen()),
            GoRoute(path: 'subscription', builder: (context, state) => const SubscriptionScreen()),
            GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
            GoRoute(path: 'post/create', builder: (context, state) => const CreatePostPage()),
            GoRoute(path: 'post/:id', builder: (context, state) => PostDetailPage(postId: state.pathParameters['id']!)),
            GoRoute(path: 'my-cats', builder: (context, state) => const MyCatsPage()),
            GoRoute(path: 'cat/edit/:id', builder: (context, state) => CatEditPage(catId: state.pathParameters['id']!)),
            GoRoute(path: 'plan', builder: (context, state) => const PlanPage()),
            GoRoute(path: 'reminder', builder: (context, state) => const ReminderPage()),
          ],
        ),

      ],
    );
  }
}

class _AuthSplashPage extends StatelessWidget {
  const _AuthSplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier();

  AsyncValue<fb.User?> _authState = const AsyncValue.loading();
  AsyncValue<UserModel?> _profileState = const AsyncValue.loading();

  void update(AsyncValue<fb.User?> auth, AsyncValue<UserModel?> profile) {
    _authState = auth;
    _profileState = profile;
    notifyListeners();
  }

  bool get isLoading {
    if (_authState.isLoading) return true;
    if (_authState.valueOrNull != null && _profileState.isLoading) return true;
    return false;
  }

  fb.User? get firebaseUser => _authState.valueOrNull;
  UserModel? get profile => _profileState.valueOrNull;
}


class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    return Scaffold(
      body: const HomePage(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: PrimaryFab(
        tooltip: context.l10n.createPost,
        onPressed: () {
          if (user == null) {
            context.push(AppRouter.auth);
            return;
          }
          context.push('${AppRouter.home}post/create');
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: context.l10n.home),
          NavigationDestination(icon: const Icon(Icons.check_circle_outline), label: context.l10n.tasks),
          NavigationDestination(icon: const Icon(Icons.favorite_border), label: context.l10n.health),
          NavigationDestination(icon: const Icon(Icons.smart_toy_outlined), label: context.l10n.aiNavLabel),
        ],


      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/tasks')) return 1;
    if (path.startsWith('/health')) return 2;
    if (path.startsWith('/ai')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go('${AppRouter.home}tasks');
        break;
      case 2:
        context.go('${AppRouter.home}health');
        break;
      case 3:
        context.go('${AppRouter.home}ai');
        break;
    }
  }
}

