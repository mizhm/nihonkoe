import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models.dart';
import '../../logic/tags.dart';
import '../../state/posts.dart';
import '../../state/search_history.dart';
import '../l10n.dart';
import '../links.dart';
import '../widgets/message.dart';

enum SearchMode { keyword, tags, cv }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  SearchMode _mode = SearchMode.keyword;
  String _text = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final q = raw.trim();
    if (q.isEmpty || _mode != SearchMode.keyword) return;
    _controller.text = q;
    setState(() => _text = q);
    ref.read(searchHistoryProvider.notifier).push(q);
    context.push(resultsPath(branchBase(context), ListQuery.search(q), title: q));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.tabsSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              controller: _controller,
              hintText: _mode == SearchMode.keyword ? l.searchPlaceholder : l.searchFilterPlaceholder,
              leading: const Icon(Symbols.search),
              trailing: [
                if (_text.isNotEmpty)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                    icon: const Icon(Symbols.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _text = '');
                    },
                  ),
              ],
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _text = v),
              onSubmitted: _submit,
            ),
          ),
          SegmentedButton<SearchMode>(
            segments: [
              ButtonSegment(value: SearchMode.keyword, label: Text(l.searchModeKeyword)),
              ButtonSegment(value: SearchMode.tags, label: Text(l.searchModeTags)),
              ButtonSegment(value: SearchMode.cv, label: Text(l.searchModeCv)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.single),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_mode) {
              SearchMode.keyword when _text.trim().isEmpty => _RecentSearches(onSubmit: _submit),
              SearchMode.keyword => ListView(children: [
                  ListTile(leading: const Icon(Symbols.search), title: Text(l.searchInAll(_text.trim())), onTap: () => _submit(_text)),
                ]),
              SearchMode.tags => _TagIndexList(index: TagIndex.tags, filter: _text),
              SearchMode.cv => _TagIndexList(index: TagIndex.cv, filter: _text),
            },
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final history = ref.watch(searchHistoryProvider).value ?? const [];
    if (history.isEmpty) return Message(icon: Symbols.search, title: l.searchHint, hint: l.searchHintDescription);
    final notifier = ref.read(searchHistoryProvider.notifier);
    return ListView(
      children: [
        ListTile(
          title: Text(l.searchRecent, style: Theme.of(context).textTheme.titleSmall),
          trailing: TextButton(onPressed: notifier.clear, child: Text(l.searchClearHistory)),
        ),
        for (final q in history)
          ListTile(
            leading: const Icon(Symbols.history),
            title: Text(q),
            onTap: () => onSubmit(q),
            trailing: IconButton(
              tooltip: l.searchRemoveHistory(q),
              icon: const Icon(Symbols.close),
              onPressed: () => notifier.remove(q),
            ),
          ),
      ],
    );
  }
}

class _TagIndexList extends ConsumerWidget {
  const _TagIndexList({required this.index, required this.filter});
  final TagIndex index;
  final String filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = branchBase(context);
    return ref.watch(tagIndexProvider(index)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Message(
            icon: Symbols.cloud_off,
            title: l.listErrorTitle,
            hint: l.listErrorHint,
            onRetry: () => ref.invalidate(tagIndexProvider(index)),
          ),
          data: (items) {
            final matches = filterTags(items, filter);
            if (matches.isEmpty) return Message(icon: Symbols.search_off, title: l.listEmpty);
            return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final tag = matches[i];
                return ListTile(
                  title: Text(tag.name),
                  trailing: Text(l.searchWorks(tag.count)),
                  onTap: () => context.push(tagPath(base, tag.slug, tag.name)),
                );
              },
            );
          },
        );
  }
}
