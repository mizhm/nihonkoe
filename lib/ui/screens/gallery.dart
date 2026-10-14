import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../state/core.dart';
import '../../state/posts.dart';
import '../../state/settings.dart';
import '../l10n.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, required this.id, this.initialIndex = 0});
  final int id;
  final int initialIndex;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;
  final _revealed = <int>{}; // pages shown sharp in privacy mode

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(postProvider(widget.id)).value?.images ?? const <String>[];
    final image = ref.watch(imageProviderFactory);
    final privacy = ref.watch(settingsProvider.select((s) => s.privacy));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: images.isEmpty ? null : Text('${_page + 1} / ${images.length}'),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) {
          final picture = InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image(image: image(images[i]), fit: BoxFit.contain)),
          );
          if (!privacy || _revealed.contains(i)) return picture;
          // Privacy mode: blurred until the user asks to see this page.
          return GestureDetector(
            onTap: () => setState(() => _revealed.add(i)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: picture),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _revealed.add(i)),
                  icon: const Icon(Symbols.visibility),
                  label: Text(context.l10n.galleryReveal),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
