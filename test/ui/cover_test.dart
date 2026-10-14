import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nihonkoe/ui/widgets/cover.dart';

import '../helpers.dart';

Widget covers() => const Scaffold(body: SizedBox(width: 200, height: 150, child: Cover(url: 'https://pic.weeabo0.xyz/1.jpg')));

void main() {
  testWidgets('covers are sharp normally and blurred in privacy mode', (tester) async {
    await pumpRouted(tester, covers(), overrides: await testOverrides());
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
    await pumpRouted(tester, covers(), overrides: await testOverrides(prefs: {'language': 'en', 'privacy': true}));
    await tester.pumpAndSettle();
    // A 16-px decode scaled up blurs for free; a per-cover blur layer would jank long grids.
    expect(find.byType(ImageFiltered), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<ResizeImage>());
  });
}
