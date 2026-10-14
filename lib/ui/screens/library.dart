import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n.dart';
import '../widgets/message.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabsLibrary)),
        body: Message(icon: Symbols.library_music, title: context.l10n.libraryComingSoon),
      );
}
