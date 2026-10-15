import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/ui/widgets/cover.dart';

import '../helpers.dart';

Widget covers() => const Scaffold(body: SizedBox(width: 200, height: 150, child: Cover(url: 'https://pic.weeabo0.xyz/1.jpg')));

void main() {
  testWidgets('privacy mode leaves in-app covers sharp', (tester) async {
    await pumpRouted(tester, covers(), overrides: await testOverrides(prefs: {'language': 'en', 'privacy': true}));
    await tester.pumpAndSettle();
    // Privacy only hides artwork outside the app (lock screen, media controls).
    expect(find.byType(ImageFiltered), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).image, isNot(isA<ResizeImage>()));
  });
}
