import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/core.dart';
import '../../state/posts.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(postProvider(widget.id)).value?.images ?? const <String>[];
    final image = ref.watch(imageProviderFactory);
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
          return InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image(image: image(images[i]), fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
