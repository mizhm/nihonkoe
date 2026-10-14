import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models.dart';
import '../../logic/layout.dart';
import '../../state/settings.dart';
import '../l10n.dart';
import '../sheets/sort.dart';
import '../widgets/post_grid.dart';

const _layoutIcons = {CardLayout.grid: Symbols.grid_view, CardLayout.compact: Symbols.apps, CardLayout.list: Symbols.view_list};

/// Search results, tag pages, category pages and the "see all" lists.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.query, this.sort = ListSort.newest, this.title});
  final ListQuery query;
  final ListSort sort;
  final String? title;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late ListSort _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final layout = ref.watch(settingsProvider.select((s) => s.cardLayout));
    final title = widget.title ?? widget.query.value;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: l.sortHeading,
                icon: const Icon(Symbols.sort),
                onPressed: () async {
                  final sort = await showSortSheet(context, _sort);
                  if (sort != null) setState(() => _sort = sort);
                },
              ),
              IconButton(
                tooltip: l.layoutSwitch(
                  {CardLayout.grid: l.layoutGrid, CardLayout.compact: l.layoutCompact, CardLayout.list: l.layoutList}[layout.next]!,
                ),
                icon: Icon(_layoutIcons[layout]),
                onPressed: ref.read(settingsProvider.notifier).cycleCardLayout,
              ),
            ],
          ),
          PostSliverGrid(listKey: (query: widget.query, sort: _sort)),
        ],
      ),
    );
  }
}
