import 'package:flutter/material.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';
import 'package:siram/view/widgets/AuthImage.dart';

/// Fullscreen photo viewer.
/// Menerima list [WorkOrderPod] agar bisa handle URL + base64 fallback.
class PhotoViewerScreen extends StatefulWidget {
  final List<WorkOrderPod> pods;
  final int initialIndex;
  final String token;

  const PhotoViewerScreen({
    super.key,
    required this.pods,
    required this.initialIndex,
    required this.token,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
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
          '${_current + 1} / ${widget.pods.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.pods.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final pod = widget.pods[i];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: AuthImage(
                    url: pod.bestUrl,
                    token: widget.token,
                    base64Data: pod.podData, // ✅ fallback base64
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Dot indicator
          if (widget.pods.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.pods.length,
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

          // Left arrow
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

          // Right arrow
          if (_current < widget.pods.length - 1)
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
