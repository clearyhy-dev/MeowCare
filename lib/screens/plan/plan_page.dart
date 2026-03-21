import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/user_repository.dart';
import '../../providers/user_provider.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserAsyncProvider).valueOrNull;
      if (user != null && !user.planStarted) {
        await ref.read(userRepositoryProvider).setPlanStarted(user.uid);
        ref.invalidate(currentUserAsyncProvider);
      }
    });
  }

  List<String> _dayKeys(BuildContext context) => [
        context.l10n.planDay1,
        context.l10n.planDay2,
        context.l10n.planDay3,
        context.l10n.planDay4,
        context.l10n.planDay5,
        context.l10n.planDay6,
        context.l10n.planDay7,
      ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserAsyncProvider);
    final user = userAsync.valueOrNull;
    final progress = user?.planProgress ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.planTitle)),
      body: user == null
          ? Center(child: Text(context.l10n.signInToStartPlan))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final days = _dayKeys(context);
                final done = index < progress;
                return ListTile(
                  title: Text(days[index]),

                  trailing: done ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () async {
                    if (index == progress) {
                      await ref.read(userRepositoryProvider).setPlanProgress(user.uid, index + 1);
                      ref.invalidate(currentUserAsyncProvider);
                    }
                  },
                );
              },
            ),
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
