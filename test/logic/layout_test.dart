import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/layout.dart';

void main() {
  test('next cycles grid → compact → list → grid', () {
    expect(CardLayout.grid.next, CardLayout.compact);
    expect(CardLayout.compact.next, CardLayout.list);
    expect(CardLayout.list.next, CardLayout.grid);
  });

  test('toCardLayout falls back to grid for unknown persisted values', () {
    expect(toCardLayout('list'), CardLayout.list);
    expect(toCardLayout('tiles'), CardLayout.grid);
    expect(toCardLayout(null), CardLayout.grid);
  });

  test('layout tables', () {
    expect([for (final l in CardLayout.values) l.columns], [2, 3, 1]);
    expect([for (final l in CardLayout.values) l.tags], [2, 0, 3]);
  });
}
