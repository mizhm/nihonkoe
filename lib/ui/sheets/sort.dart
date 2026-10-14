import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/models.dart';
import '../l10n.dart';

Future<ListSort?> showSortSheet(BuildContext context, ListSort current) {
  final l = context.l10n;
  final labels = {
    ListSort.newest: l.sortNewest,
    ListSort.oldest: l.sortOldest,
    ListSort.title: l.sortTitle,
    ListSort.popularWeek: l.sortPopularWeek,
    ListSort.popularMonth: l.sortPopularMonth,
    ListSort.popularYear: l.sortPopularYear,
    ListSort.popularAll: l.sortPopularAll,
  };
  Widget option(BuildContext context, ListSort sort) => ListTile(
        title: Text(labels[sort]!),
        selected: sort == current,
        trailing: sort == current ? const Icon(Symbols.check) : null,
        onTap: () => Navigator.pop(context, sort),
      );
  return showModalBottomSheet<ListSort>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(l.sortHeading, style: Theme.of(context).textTheme.titleMedium)),
          for (final s in [ListSort.newest, ListSort.oldest, ListSort.title]) option(context, s),
          ListTile(dense: true, title: Text(l.sortPopular)),
          for (final s in [ListSort.popularWeek, ListSort.popularMonth, ListSort.popularYear, ListSort.popularAll]) option(context, s),
        ],
      ),
    ),
  );
}
