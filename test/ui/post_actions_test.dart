import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/ui/sheets/post_actions.dart';

import '../helpers.dart';

Widget opener(PostRef post) => Builder(
      builder: (context) => Scaffold(
        body: Center(child: TextButton(onPressed: () => showPostActions(context, post), child: const Text('open'))),
      ),
    );

void main() {
  testWidgets('shows every action; playback and favorites are disabled in phase 1', (tester) async {
    await pumpRouted(tester, opener(const PostRef(id: 150207, title: 'T', circle: 'HONEY NOIR', cv: '木蜜甜花')),
        overrides: await testOverrides());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final label in [en.actionsPlayNow, en.actionsPlayNext, en.detailAddToQueue, en.detailFavorite]) {
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, label)).enabled, isFalse, reason: label);
    }
    for (final label in [en.actionsViewCircle, en.actionsViewCv, en.actionsViewTags, en.actionsShare, en.actionsOpenWeb]) {
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, label)).enabled, isTrue, reason: label);
    }
  });

  testWidgets('circle and CV rows are hidden when unknown', (tester) async {
    await pumpRouted(tester, opener(const PostRef(id: 1, title: 'T')), overrides: await testOverrides());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(en.actionsViewCircle), findsNothing);
    expect(find.text(en.actionsViewCv), findsNothing);
  });

  testWidgets('view tags loads the post and shows its tags as chips', (tester) async {
    final post = File('test/fixtures/post.html').readAsStringSync();
    await pumpRouted(tester, opener(const PostRef(id: 150207, title: 'T')),
        overrides: await testOverrides(client: mockHttp({'https://japaneseasmr.com/150207/': post})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.actionsViewTags));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Ear Licking 【耳舐め】'), findsOneWidget);
  });
}
