import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';
import 'package:siram/viewmodel/DetailWorkOrderViewModel.dart';

/// Kartu Survey Photo dengan carousel dari quotationImage.
class SurveyPhotoCard extends StatefulWidget {
  const SurveyPhotoCard({super.key});

  @override
  State<SurveyPhotoCard> createState() => _SurveyPhotoCardState();
}

class _SurveyPhotoCardState extends State<SurveyPhotoCard> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetailWorkOrderViewModel>(
      builder: (_, vm, __) {
        final imgs = vm.validSurveyImages;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF7BCEF5),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Survey Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  if (imgs.isNotEmpty)
                    Text(
                      '${imgs.length} foto',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (imgs.isEmpty)
                _photoPlaceholder('Belum ada foto survey')
              else ...[
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageCtrl,
                        itemCount: imgs.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _SurveyViewerScreen(
                                images: imgs,
                                initialIndex: i,
                                token: vm.token,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _SurveyImageWidget(
                              image: imgs[i],
                              token: vm.token,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Counter
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${imgs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (imgs.length > 1 && _currentPage > 0)
                        _arrowBtn(
                          left: true,
                          onTap: () => _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      if (imgs.length > 1 && _currentPage < imgs.length - 1)
                        _arrowBtn(
                          left: false,
                          onTap: () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (imgs.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imgs.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 16 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? const Color(0xFF7BCEF5)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  imgs[_currentPage.clamp(0, imgs.length - 1)].podName,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder(String msg) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _arrowBtn({required bool left, required VoidCallback onTap}) {
    return Positioned(
      left: left ? 4 : null,
      right: left ? null : 4,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              left ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _SurveyImageWidget ───────────────────────────────────────────────────────
/// Fetch survey image via API endpoint dengan auth header.
class _SurveyImageWidget extends StatefulWidget {
  final QuotationImage image;
  final String token;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _SurveyImageWidget({
    required this.image,
    required this.token,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<_SurveyImageWidget> createState() => _SurveyImageWidgetState();
}

class _SurveyImageWidgetState extends State<_SurveyImageWidget> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _hasError = false;

  static final Map<String, Uint8List> _cache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = widget.image.imageId.isNotEmpty
        ? widget.image.imageId
        : widget.image.s3Path;
    if (_cache.containsKey(key)) {
      if (mounted)
        setState(() {
          _bytes = _cache[key];
          _loading = false;
        });
      return;
    }

    // Candidate URLs to try
    final baseDomain = 'https://siram.watercare.co.id';
    final candidates = [
      '$baseDomain/api/data/quotationImage/${widget.image.imageId}',
      '$baseDomain/api/data/getQuotationImage/${widget.image.imageId}',
      '$baseDomain/storage/${widget.image.s3Path}',
    ];

    for (final url in candidates) {
      if (url.isEmpty || url.endsWith('/')) continue;
      try {
        final resp = await http
            .get(
              Uri.parse(url),
              headers: {'Authorization': 'Bearer ${widget.token}'},
            )
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          final ct = resp.headers['content-type'] ?? '';
          if (ct.startsWith('image/') ||
              (!_isHtml(resp.bodyBytes) && resp.bodyBytes.length > 500)) {
            _cache[key] = resp.bodyBytes;
            if (mounted)
              setState(() {
                _bytes = resp.bodyBytes;
                _loading = false;
              });
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted)
      setState(() {
        _loading = false;
        _hasError = true;
      });
  }

  bool _isHtml(Uint8List b) {
    if (b.length < 15) return false;
    final p = String.fromCharCodes(b.sublist(0, 15)).toLowerCase();
    return p.contains('<!doctype') || p.contains('<html');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7BCEF5),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (_hasError || _bytes == null) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Container(
          color: const Color(0xFFF5F7FA),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
        ),
      );
    }
    return Image.memory(
      _bytes!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
    );
  }
}

// ─── _SurveyViewerScreen ──────────────────────────────────────────────────────
class _SurveyViewerScreen extends StatefulWidget {
  final List<QuotationImage> images;
  final int initialIndex;
  final String token;

  const _SurveyViewerScreen({
    required this.images,
    required this.initialIndex,
    required this.token,
  });

  @override
  State<_SurveyViewerScreen> createState() => _SurveyViewerScreenState();
}

class _SurveyViewerScreenState extends State<_SurveyViewerScreen> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _SurveyImageWidget(
                  image: widget.images[i],
                  token: widget.token,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? const Color(0xFF7BCEF5)
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          if (_current > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          if (_current < widget.images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
