import 'package:flutter/material.dart';

/// Galleria immagini della card utente.
/// Gestisce tap a sinistra/destra, indicatori e frecce overlay.
class ProfileImageGallery extends StatefulWidget {
  final List<String> images;
  final ValueChanged<bool>? onScrolling;

  const ProfileImageGallery({
    super.key,
    required this.images,
    this.onScrolling,
  });

  @override
  State<ProfileImageGallery> createState() => _ProfileImageGalleryState();
}

class _ProfileImageGalleryState extends State<ProfileImageGallery> {
  final PageController _pageCtrl = PageController();
  int _currentPhoto = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentPhoto > 0) {
      setState(() => _currentPhoto--);
      _pageCtrl.animateToPage(
        _currentPhoto,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNext() {
    if (_currentPhoto < widget.images.length - 1) {
      setState(() => _currentPhoto++);
      _pageCtrl.animateToPage(
        _currentPhoto,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          height: 300,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text('Nessuna immagine',
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Tap sinistra/destra per cambiare immagine
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                final tapPosition =
                box?.globalToLocal(details.globalPosition);
                if (tapPosition == null) return;

                final width = box!.size.width;
                final tapX = tapPosition.dx;

                if (tapX < width / 2) {
                  _goToPrevious();
                } else {
                  _goToNext();
                }
              },
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final path = images[index];
                  return Image.asset(
                    path,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Text(
                        'Asset non trovato:\n$path',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Indicatori in basso (pallini)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPhoto == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPhoto == i
                          ? Colors.white
                          : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // Frecce ai lati (solo indicative)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}