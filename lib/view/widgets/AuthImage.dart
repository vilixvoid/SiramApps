import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget gambar yang:
/// 1. Kirim Authorization Bearer token untuk URL
/// 2. Fallback ke base64 (pod_data) jika URL kosong atau 403
/// 3. Dipakai di PhotoCarouselCard dan PhotoViewerScreen
class AuthImage extends StatelessWidget {
  final String url;
  final String token;
  final double? height;
  final double? width;
  final BoxFit fit;

  /// Base64 string (pod_data dari API) — dipakai ketika [url] kosong atau gagal.
  /// Ambil dari WorkOrderPod.podData
  final String? base64Data;

  const AuthImage({
    super.key,
    required this.url,
    required this.token,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.base64Data,
  });

  @override
  Widget build(BuildContext context) {
    // Jika URL kosong → langsung render base64 (tidak perlu HTTP sama sekali)
    if (url.isEmpty) {
      if (base64Data != null && base64Data!.isNotEmpty) {
        return _Base64Image(
          data: base64Data!,
          height: height,
          width: width,
          fit: fit,
        );
      }
      return _broken();
    }

    // Ada URL → coba load via HTTP dengan Bearer token
    return Image(
      image: NetworkImage(url, headers: {'Authorization': 'Bearer $token'}),
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return _loading();
      },
      errorBuilder: (_, err, __) {
        debugPrint('❌ AuthImage gagal load: $url');
        // Fallback ke base64 jika tersedia
        if (base64Data != null && base64Data!.isNotEmpty) {
          return _Base64Image(
            data: base64Data!,
            height: height,
            width: width,
            fit: fit,
          );
        }
        return _broken();
      },
    );
  }

  Widget _loading() {
    return SizedBox(
      height: height,
      width: width,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7BCEF5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _broken() {
    return SizedBox(
      height: height,
      width: width,
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
            size: 36,
          ),
        ),
      ),
    );
  }
}

// ─── _Base64Image ─────────────────────────────────────────────────────────────
/// Render image dari base64 string (pod_data dari API response).
/// Tidak perlu HTTP — data sudah ada di memory.
class _Base64Image extends StatelessWidget {
  final String data;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _Base64Image({
    required this.data,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final Uint8List bytes = base64Decode(data);
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    } catch (e) {
      debugPrint('❌ Base64 decode error: $e');
      return _broken();
    }
  }

  Widget _broken() {
    return SizedBox(
      height: height,
      width: width,
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
            size: 36,
          ),
        ),
      ),
    );
  }
}
