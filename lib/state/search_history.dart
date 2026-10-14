import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import 'core.dart';

final searchHistoryRepoProvider = Provider<SearchHistoryRepo>((ref) => SearchHistoryRepo(ref.watch(dbProvider)));

class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  SearchHistoryRepo get _repo => ref.read(searchHistoryRepoProvider);

  @override
  Future<List<String>> build() => ref.watch(searchHistoryRepoProvider).list();

  Future<void> _then(Future<void> change) async {
    await change;
    state = AsyncData(await _repo.list());
  }

  Future<void> push(String query) => _then(_repo.push(query));
  Future<void> remove(String query) => _then(_repo.remove(query));
  Future<void> clear() => _then(_repo.clear());
}

final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
