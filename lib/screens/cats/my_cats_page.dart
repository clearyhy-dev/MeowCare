import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../widgets/network_avatar.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/cat_repository.dart';
import '../../models/cat_model.dart';
import '../../providers/user_provider.dart';


final myCatsRepositoryProvider = Provider<CatRepository>((ref) => CatRepository());

class MyCatsPage extends ConsumerStatefulWidget {
  const MyCatsPage({super.key});

  @override
  ConsumerState<MyCatsPage> createState() => _MyCatsPageState();
}

class _MyCatsPageState extends ConsumerState<MyCatsPage> {
  List<CatModel> _cats = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(myCatsRepositoryProvider);
    final result = await repo.getMyCats(uid: uid, limit: AppConstants.feedPageSize);
    if (mounted) {
      setState(() {
        _cats = result.list;
        _hasMore = result.list.length == AppConstants.feedPageSize;
        _lastDoc = result.lastDoc;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _loadingMore = true);
    final repo = ref.read(myCatsRepositoryProvider);
    final result = await repo.getMyCats(uid: uid, limit: AppConstants.feedPageSize, startAfter: _lastDoc);
    if (mounted) {
      setState(() {
        _cats = [..._cats, ...result.list];
        _hasMore = result.list.length == AppConstants.feedPageSize;
        _lastDoc = result.lastDoc;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myCats),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('${AppRouter.home}cat/edit/new'),
            ),
        ],
      ),
      body: user == null
          ? Center(child: Text(context.l10n.signInToManageCats))
          : _loading && _cats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _cats.isEmpty
                  ? Center(child: Text(context.l10n.noCatsYetAddOne))
                  : ListView.builder(
                      itemCount: _cats.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _cats.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _loadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _loadMore,
                                      child: Text(context.l10n.loadMore),
                                    ),
                            ),
                          );
                        }
                        final cat = _cats[index];
                        return ListTile(
                          leading: NetworkAvatar(imageUrl: cat.avatarUrl),
                          title: Text(cat.name),
                          subtitle: Text(cat.isPublic ? 'Public' : 'Private'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('${AppRouter.home}cat/edit/${cat.catId}'),
                        );
                      },
                    ),
    );
  }
}

