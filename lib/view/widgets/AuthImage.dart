import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Fetch image bytes dengan Authorization header.
/// Mengatasi 403 di Android karena NetworkImage tidak support custom headers.
class AuthImage extends StatefulWidget {
  final String url;
  final String token;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? base64Fallback;

  const AuthImage({
    super.key,
    required this.url,
    required this.token,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.base64Fallback,
  });

  // In-process memory cache: url → bytes
  static final Map<String, Uint8List> cache = {};

  static void clearCache() => cache.clear();

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AuthImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.token != widget.token) {
      setState(() {
        _bytes = null;
        _loading = true;
        _hasError = false;
      });
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.url.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (AuthImage.cache.containsKey(widget.url)) {
      if (mounted)
        setState(() {
          _bytes = AuthImage.cache[widget.url];
          _loading = false;
        });
      return;
    }
    try {
      final resp = await http
          .get(
            Uri.parse(widget.url),
            headers: {'Authorization': 'Bearer ${widget.token}'},
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        AuthImage.cache[widget.url] = resp.bodyBytes;
        if (mounted)
          setState(() {
            _bytes = resp.bodyBytes;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _loading = false;
            _hasError = true;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return SizedBox(height: widget.height, width: widget.width);
    }
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
      return _BrokenImage(height: widget.height, width: widget.width);
    }
    return Image.memory(
      _bytes!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      errorBuilder: (_, __, ___) =>
          _BrokenImage(height: widget.height, width: widget.width),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  final double? height;
  final double? width;
  const _BrokenImage({this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
        ),
      ),
    );
  }
}
