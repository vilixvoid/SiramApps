import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';
import 'package:siram/view/widgets/AuthImage.dart';
import 'package:siram/view/widgets/PhotoViewerScreen.dart';
import 'package:siram/viewmodel/DetailWorkOrderViewModel.dart';

/// Kartu foto Before atau After dengan carousel multi-slide + upload.
class PhotoCarouselCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String type; // 'before' | 'after'

  const PhotoCarouselCard({
    super.key,
    required this.title,
    required this.icon,
    required this.type,
  });

  @override
  State<PhotoCarouselCard> createState() => _PhotoCarouselCardState();
}

class _PhotoCarouselCardState extends State<PhotoCarouselCard> {
  final PageController _pageCtrl = PageController();
  final TextEditingController _noteCtrl = TextEditingController();
  int _currentPage = 0;
  File? _newFile;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _newFile = File(picked.path));
  }

  Future<void> _upload(DetailWorkOrderViewModel vm) async {
    if (_newFile == null) return;
    final success = widget.type == 'before'
        ? await vm.uploadPhotoBefore(_newFile!, notes: _noteCtrl.text)
        : await vm.uploadPhotoAfter(_newFile!, notes: _noteCtrl.text);

    if (success) {
      if (mounted) {
        setState(() {
          _newFile = null;
          _noteCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} berhasil diupload!'),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Jump to last page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final pods = vm.getPodsOfType(widget.type);
          if (pods.isNotEmpty && _pageCtrl.hasClients) {
            _pageCtrl.jumpToPage(pods.length - 1);
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload gagal, coba lagi'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetailWorkOrderViewModel>(
      builder: (_, vm, __) {
        final pods = vm.getPodsOfType(widget.type);
        final isUploading = widget.type == 'before'
            ? vm.isUploadingBefore
            : vm.isUploadingAfter;

        return _WoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF7BCEF5), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (pods.isNotEmpty)
                    Text(
                      '${pods.length} foto',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Existing carousel
              if (pods.isNotEmpty && _newFile == null) ...[
                _PhotoCarousel(
                  pods: pods,
                  pageController: _pageCtrl,
                  currentPage: _currentPage,
                  token: vm.token,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  onTap: (idx) {
                    final urls = pods
                        .map((p) => p.bestUrl)
                        .where((u) => u.isNotEmpty)
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                          urls: urls,
                          initialIndex: idx,
                          token: vm.token,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (pods.length > 1)
                  _DotIndicator(count: pods.length, current: _currentPage),
                _PhotoCommentSection(pods: pods, currentPage: _currentPage),
              ] else if (pods.isEmpty && _newFile == null) ...[
                _PhotoPlaceholder(message: 'Belum ada foto'),
              ],

              // New file preview
              if (_newFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _newFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Keterangan foto (opsional)...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _newFile = null;
                          _noteCtrl.clear();
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : () => _upload(vm),
                        icon: isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.cloud_upload_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                        label: Text(
                          isUploading ? 'Uploading...' : 'Upload Foto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7BCEF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              if (_newFile == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                      color: Color(0xFF7BCEF5),
                    ),
                    label: Text(
                      pods.isNotEmpty ? 'Tambah Foto' : 'Pilih Foto',
                      style: const TextStyle(
                        color: Color(0xFF7BCEF5),
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7BCEF5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── _PhotoCarousel ───────────────────────────────────────────────────────────
class _PhotoCarousel extends StatelessWidget {
  final List<WorkOrderPod> pods;
  final PageController pageController;
  final int currentPage;
  final String token;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTap;

  const _PhotoCarousel({
    required this.pods,
    required this.pageController,
    required this.currentPage,
    required this.token,
    required this.onPageChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: pods.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) {
              final pod = pods[i];
              return GestureDetector(
                onTap: () => onTap(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AuthImage(
                    url: pod.bestUrl,
                    token: token,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          // Counter
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentPage + 1}/${pods.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (pods.length > 1 && currentPage > 0)
            _ArrowButton(
              left: true,
              onTap: () => pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          if (pods.length > 1 && currentPage < pods.length - 1)
            _ArrowButton(
              left: false,
              onTap: () => pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── _PhotoCommentSection ─────────────────────────────────────────────────────
class _PhotoCommentSection extends StatelessWidget {
  final List<WorkOrderPod> pods;
  final int currentPage;

  const _PhotoCommentSection({required this.pods, required this.currentPage});

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pods.isEmpty) return const SizedBox.shrink();
    final pod = pods[currentPage.clamp(0, pods.length - 1)];
    if (pod.notes.isEmpty && pod.createdAt.isEmpty)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pod.createdAt.isNotEmpty)
            Text(
              _formatDateTime(pod.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          if (pod.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 14,
                  color: Color(0xFF7BCEF5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pod.notes,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _DotIndicator ────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current == i ? 16 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: current == i
                ? const Color(0xFF7BCEF5)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─── _PhotoPlaceholder ────────────────────────────────────────────────────────
class _PhotoPlaceholder extends StatelessWidget {
  final String message;
  const _PhotoPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
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
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ArrowButton ─────────────────────────────────────────────────────────────
class _ArrowButton extends StatelessWidget {
  final bool left;
  final VoidCallback onTap;
  const _ArrowButton({required this.left, required this.onTap});

  @override
  Widget build(BuildContext context) {
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

// ─── _WoCard ──────────────────────────────────────────────────────────────────
class _WoCard extends StatelessWidget {
  final Widget child;
  const _WoCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}
