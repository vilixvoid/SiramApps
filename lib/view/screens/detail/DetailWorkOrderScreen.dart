import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:siram/core/services/ApiServices.dart'; // ✅ sesuaikan path

class DetailWorkOrderScreen extends StatefulWidget {
  final int workOrderId;
  final String token;

  const DetailWorkOrderScreen({
    super.key,
    required this.workOrderId,
    required this.token,
  });

  @override
  State<DetailWorkOrderScreen> createState() => _DetailWorkOrderScreenState();
}

class _DetailWorkOrderScreenState extends State<DetailWorkOrderScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _noteBeforeController = TextEditingController();
  final TextEditingController _noteAfterController = TextEditingController();

  File? _newPhotoBefore;
  File? _newPhotoAfter;
  bool _isUploadingBefore = false;
  bool _isUploadingAfter = false;
  bool _isSubmitting = false;
  bool _isSavingNotes = false;

  bool _checkAreaDibersihkan = false;
  bool _checkTandaTangan = false;
  bool _checkPenutupanTiket = false;

  late final ApiService _apiService;

  // ✅ TODO: Ganti dengan base URL S3 yang benar dari backend
  // Format akhir URL foto = _s3BaseUrl + s3_path
  // Contoh: 'https://siram-bucket.s3.ap-southeast-1.amazonaws.com/'
  // Tanyakan ke backend: curl https://siram.watercare.co.id/api/data/detailWorkOrder/7808
  // lalu cek apakah ada field 's3_base_url' atau tanyakan langsung ke developer backend
  static const String _s3BaseUrl =
      'https://siram.watercare.co.id/storage/'; // ← GANTI INI

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchDetail();
  }

  // ─── Fetch Data ─────────────────────────────────────────────────────────────
  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _apiService.loadToken();
      final data = await _apiService.get(
        'data/detailWorkOrder/${widget.workOrderId}',
      );
      setState(() {
        _data = data;
        _isLoading = false;
        final notes = data['workOrder']?['notes_technician'] ?? '';
        _notesController.text = notes.toString();
      });

      // ─── DEBUG: print semua URL foto ──────────────────────────────────────
      // Hapus blok ini setelah foto sudah muncul dengan benar
      debugPrint('=== DEBUG FOTO ===');
      debugPrint('podBefore  : ${data['podBefore']}');
      debugPrint('podAfter   : ${data['podAfter']}');
      final imgs = data['quotationImage'] as List? ?? [];
      debugPrint('quotationImage count: ${imgs.length}');
      for (var img in imgs) {
        final url = '$_s3BaseUrl${img['s3_path']}';
        debugPrint(
          '  → id=${img['quotation_image_id']} size=${img['pod_size']} type=${img['pod_type']}',
        );
        debugPrint('    URL: $url');
      }
      debugPrint('==================');
      // ─────────────────────────────────────────────────────────────────────
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── Helper: Build photo URL ─────────────────────────────────────────────
  /// Jika s3_path sudah berupa URL lengkap (http://...) → pakai langsung
  /// Jika relatif → gabungkan dengan _s3BaseUrl
  String _buildPhotoUrl(String? s3Path) {
    if (s3Path == null || s3Path.isEmpty) return '';
    if (s3Path.startsWith('http://') || s3Path.startsWith('https://')) {
      return s3Path; // sudah URL lengkap
    }
    final base = _s3BaseUrl.endsWith('/') ? _s3BaseUrl : '$_s3BaseUrl/';
    final path = s3Path.startsWith('/') ? s3Path.substring(1) : s3Path;
    return '$base$path';
  }

  // ─── Helper: Extract photo URL from various formats ──────────────────────
  /// API bisa return podBefore/podAfter dalam berbagai format:
  /// - null        → tidak ada foto
  /// - String      → URL langsung atau s3_path relatif
  /// - Map         → {type, s3_path, url, ...} — print keys untuk debug
  String _extractPhotoUrl(dynamic raw) {
    if (raw == null) return '';

    if (raw is String) {
      return raw.isEmpty ? '' : _buildPhotoUrl(raw);
    }

    if (raw is Map) {
      debugPrint('📦 Pod Map keys: ${raw.keys.toList()} | values: $raw');

      // Coba semua kemungkinan field URL
      for (final key in [
        'url',
        'file_url',
        's3_url',
        'full_url',
        'image_url',
        'photo_url',
        'path',
        'file_path',
      ]) {
        final val = raw[key]?.toString() ?? '';
        if (val.isNotEmpty) return _buildPhotoUrl(val);
      }

      // Fallback ke s3_path
      final s3 = raw['s3_path']?.toString() ?? '';
      if (s3.isNotEmpty) return _buildPhotoUrl(s3);

      // Fallback ke pod_name (jarang, tapi bisa saja)
      final name = raw['pod_name']?.toString() ?? '';
      if (name.isNotEmpty) return _buildPhotoUrl(name);
    }

    debugPrint('⚠️ Tidak bisa ekstrak URL dari: $raw (${raw.runtimeType})');
    return '';
  }

  // ─── Upload Photo Before ─────────────────────────────────────────────────
  Future<void> _pickPhotoBefore() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _newPhotoBefore = File(picked.path));
  }

  Future<void> _uploadPhotoBefore() async {
    if (_newPhotoBefore == null) return;
    setState(() => _isUploadingBefore = true);
    try {
      await _apiService.loadToken();
      final baseUrl = _apiService.baseUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/data/uploadPhotoBefore'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['work_order_id'] = widget.workOrderId.toString();
      if (_noteBeforeController.text.isNotEmpty) {
        request.fields['notes'] = _noteBeforeController.text;
      }
      request.files.add(
        await http.MultipartFile.fromPath('photo', _newPhotoBefore!.path),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        _showSnackBar('Photo Before berhasil diupload!', success: true);
        setState(() {
          _newPhotoBefore = null;
          _noteBeforeController.clear();
        });
        await _fetchDetail();
      } else {
        _showSnackBar('Gagal upload (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Gagal upload: $e');
    } finally {
      setState(() => _isUploadingBefore = false);
    }
  }

  // ─── Upload Photo After ──────────────────────────────────────────────────
  Future<void> _pickPhotoAfter() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _newPhotoAfter = File(picked.path));
  }

  Future<void> _uploadPhotoAfter() async {
    if (_newPhotoAfter == null) return;
    setState(() => _isUploadingAfter = true);
    try {
      await _apiService.loadToken();
      final baseUrl = _apiService.baseUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/data/uploadPhotoAfter'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['work_order_id'] = widget.workOrderId.toString();
      if (_noteAfterController.text.isNotEmpty) {
        request.fields['notes'] = _noteAfterController.text;
      }
      request.files.add(
        await http.MultipartFile.fromPath('photo', _newPhotoAfter!.path),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        _showSnackBar('Photo After berhasil diupload!', success: true);
        setState(() {
          _newPhotoAfter = null;
          _noteAfterController.clear();
        });
        await _fetchDetail();
      } else {
        _showSnackBar('Gagal upload (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Gagal upload: $e');
    } finally {
      setState(() => _isUploadingAfter = false);
    }
  }

  // ─── Save Notes ──────────────────────────────────────────────────────────
  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      await _apiService.post('data/editNotes', {
        'work_order_id': widget.workOrderId,
        'notes_technician': _notesController.text,
      });
      _showSnackBar('Catatan berhasil disimpan!', success: true);
    } catch (e) {
      _showSnackBar('Gagal simpan catatan: $e');
    } finally {
      setState(() => _isSavingNotes = false);
    }
  }

  // ─── Checkin / Checkout ──────────────────────────────────────────────────
  Future<void> _handleMainButton() async {
    final wo = _data?['workOrder'] ?? {};
    final bool hasCheckin = wo['checkin'] != null;
    final bool hasCheckout = wo['checkout'] != null;
    if (hasCheckout) return;
    setState(() => _isSubmitting = true);
    try {
      if (!hasCheckin) {
        await _apiService.post('data/checkin', {
          'work_order_id': widget.workOrderId,
        });
        _showSnackBar('Check-in berhasil!', success: true);
      } else {
        await _apiService.post('data/checkout', {
          'work_order_id': widget.workOrderId,
        });
        _showSnackBar('Tugas berhasil diselesaikan!', success: true);
      }
      await _fetchDetail();
    } catch (e) {
      _showSnackBar('Gagal: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ─── WhatsApp ────────────────────────────────────────────────────────────
  Future<void> _openWhatsApp(String phone) async {
    String normalized = phone.replaceAll(RegExp(r'\D'), '');
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$normalized');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Tidak dapat membuka WhatsApp');
    }
  }

  void _showSnackBar(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF27AE60) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPhotoViewer(List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PhotoViewerScreen(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _commentController.dispose();
    _noteBeforeController.dispose();
    _noteAfterController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7BCEF5)),
            )
          : _error != null
          ? _buildErrorState()
          : _buildBody(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BCEF5),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final wo = _data?['workOrder'] ?? {};
    final customer = _data?['customer'] ?? {};
    final customerAddress = _data?['customerAddress'] ?? {};
    final quotation = _data?['quotation'] ?? {};
    final List products = _data?['product'] ?? [];
    final List comments = _data?['comment'] ?? [];

    final String priority = wo['priority'] ?? 'Medium';
    final String status = wo['status'] ?? '';
    final String address = customerAddress['address'] ?? '-';
    final bool hasCheckin = wo['checkin'] != null;
    final bool hasCheckout = wo['checkout'] != null;
    final String checkInTime = wo['checkin'] != null
        ? _formatTime(wo['checkin'])
        : '-';
    final String checkOutTime = wo['checkout'] != null
        ? _formatTime(wo['checkout'])
        : '-';

    // ✅ Survey photos: ambil semua quotationImage yang punya s3_path
    // Filter LONGGAR: hanya skip yang s3_path null/kosong
    // (pod_size == 0 bisa tetap ada, biarkan Image.network yang handle error)
    final List quotationImages = (_data?['quotationImage'] as List? ?? [])
        .where(
          (img) =>
              img['s3_path'] != null && (img['s3_path'] as String).isNotEmpty,
        )
        .toList();

    final List<String> surveyPhotoUrls = quotationImages
        .map<String>((img) => _buildPhotoUrl(img['s3_path'] as String))
        .where((url) => url.isNotEmpty)
        .toList();

    // ✅ podBefore / podAfter — struktur dari API adalah Map, bukan String
    // Contoh: {type: before, s3_path: "pod/xxx.jpg", url: "https://..."}
    // Debug: print semua key yang ada
    final dynamic podBeforeRaw = _data?['podBefore'];
    final dynamic podAfterRaw = _data?['podAfter'];

    debugPrint(
      'podBefore type: ${podBeforeRaw.runtimeType} value: $podBeforeRaw',
    );
    debugPrint('podAfter type: ${podAfterRaw.runtimeType} value: $podAfterRaw');

    final String podBeforeUrl = _extractPhotoUrl(podBeforeRaw);
    final String podAfterUrl = _extractPhotoUrl(podAfterRaw);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          _buildMapSection(),
          const SizedBox(height: 12),

          // ── Lokasi ───────────────────────────────────────────────────────
          _buildCard(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF7BCEF5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Tugas',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Clock In / Out ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildClockCard('CLOCK IN', checkInTime, status),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildClockCard(
                    'CLOCK OUT',
                    checkOutTime,
                    'Status: OK',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Customer Card ────────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xFF7BCEF5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAMA PELANGGAN',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            customer['customer_name'] ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      Icons.category_outlined,
                      quotation['purchasing_type'] ?? wo['wo_type'] ?? '-',
                    ),
                    _buildInfoChip(Icons.calendar_today, wo['wo_date'] ?? '-'),
                    _buildInfoChip(Icons.access_time, wo['wo_time'] ?? '-'),
                    _buildInfoChip(Icons.timer_outlined, wo['est_time'] ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Color(0xFF7BCEF5)),
                    const SizedBox(width: 6),
                    Text(
                      customer['cp_phone'] ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if ((customer['cp_phone'] ?? '').isNotEmpty)
                      GestureDetector(
                        onTap: () => _openWhatsApp(customer['cp_phone']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.chat, color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if ((wo['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 16,
                          color: Color(0xFFF9A825),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            wo['notes'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Priority ─────────────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioritas Tugas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPrioritySelector(priority),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Aktivitas Tugas header ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aktivitas Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Work Order List ──────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(Icons.list_alt, 'Work Order List'),
                const SizedBox(height: 10),
                _buildWoListItem(wo['wo_name'] ?? '-'),
                ...products.map(
                  (p) => _buildWoListItem(
                    '${p['material_desc']}'
                    '${(p['remarks'] ?? '').toString().isNotEmpty && p['remarks'] != '-' ? ' — ${p['remarks']}' : ''}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Photo Before ─────────────────────────────────────────────────
          _buildPhotoCard(
            title: 'Photo Before',
            icon: Icons.camera_alt_outlined,
            existingUrl: podBeforeUrl,
            newFile: _newPhotoBefore,
            noteController: _noteBeforeController,
            isUploading: _isUploadingBefore,
            onPick: _pickPhotoBefore,
            onUpload: _uploadPhotoBefore,
            onCancel: () => setState(() {
              _newPhotoBefore = null;
              _noteBeforeController.clear();
            }),
          ),
          const SizedBox(height: 8),

          // ── Photo After ──────────────────────────────────────────────────
          _buildPhotoCard(
            title: 'Photo After',
            icon: Icons.add_photo_alternate_outlined,
            existingUrl: podAfterUrl,
            newFile: _newPhotoAfter,
            noteController: _noteAfterController,
            isUploading: _isUploadingAfter,
            onPick: _pickPhotoAfter,
            onUpload: _uploadPhotoAfter,
            onCancel: () => setState(() {
              _newPhotoAfter = null;
              _noteAfterController.clear();
            }),
          ),
          const SizedBox(height: 8),

          // ── Survey Photo (quotationImage) ────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSectionHeader(
                      Icons.photo_library_outlined,
                      'Survey Photo',
                    ),
                    const Spacer(),
                    if (surveyPhotoUrls.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showPhotoViewer(surveyPhotoUrls, 0),
                        child: _buildTextButton('Lihat Semua'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (surveyPhotoUrls.isEmpty)
                  // ✅ Tampilkan placeholder + debug info jika kosong
                  Column(
                    children: [
                      _buildPhotoPlaceholder('Belum ada foto survey'),
                      const SizedBox(height: 8),
                      // DEBUG: tampilkan raw data untuk cek
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Debug: quotationImage count = ${(_data?['quotationImage'] as List? ?? []).length}\n'
                          'Cek Debug Console untuk URL foto.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: surveyPhotoUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showPhotoViewer(surveyPhotoUrls, i),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              surveyPhotoUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF5F7FA),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              loadingBuilder: (_, child, prog) => prog == null
                                  ? child
                                  : const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF7BCEF5),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (surveyPhotoUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${surveyPhotoUrls.length} foto survey',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Catatan Teknisi ──────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.description_outlined,
                  'Catatan Teknisi',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan detail pekerjaan...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    icon: _isSavingNotes
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSavingNotes ? 'Menyimpan...' : 'Simpan Catatan',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
          ),
          const SizedBox(height: 8),

          // ── Comment ──────────────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(Icons.chat_bubble_outline, 'Comment'),
                const SizedBox(height: 10),
                if (comments.isNotEmpty) ...[
                  ...comments.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['created_by']?.toString() ?? 'User',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['comment']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                TextField(
                  controller: _commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar singkat',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Checklist ────────────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(Icons.checklist, 'Checklist'),
                const SizedBox(height: 8),
                _buildChecklistItem(
                  'Area kerja dibersihkan',
                  _checkAreaDibersihkan,
                  (v) => setState(() => _checkAreaDibersihkan = v ?? false),
                ),
                _buildChecklistItem(
                  'Tanda tangan pelanggan',
                  _checkTandaTangan,
                  (v) => setState(() => _checkTandaTangan = v ?? false),
                ),
                _buildChecklistItem(
                  'Penutupan tiket di sistem',
                  _checkPenutupanTiket,
                  (v) => setState(() => _checkPenutupanTiket = v ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Main Button ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || hasCheckout)
                    ? null
                    : _handleMainButton,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        hasCheckout
                            ? Icons.check_circle
                            : hasCheckin
                            ? Icons.logout
                            : Icons.login,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Memproses...'
                      : hasCheckout
                      ? 'Tugas Selesai ✓'
                      : hasCheckin
                      ? 'Selesaikan Tugas (Checkout)'
                      : 'Tiba di Lokasi (Check-in)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCheckout
                      ? Colors.grey.shade400
                      : hasCheckin
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF7BCEF5),
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ─── Photo Card ───────────────────────────────────────────────────────────
  Widget _buildPhotoCard({
    required String title,
    required IconData icon,
    required String existingUrl,
    required File? newFile,
    required TextEditingController noteController,
    required bool isUploading,
    required VoidCallback onPick,
    required Future<void> Function() onUpload,
    required VoidCallback onCancel,
  }) {
    final bool hasExisting = existingUrl.isNotEmpty;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7BCEF5), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (hasExisting && newFile == null)
                GestureDetector(
                  onTap: () => _showPhotoViewer([existingUrl], 0),
                  child: _buildTextButton('Detail'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Existing photo ───────────────────────────────────────────────
          if (hasExisting && newFile == null)
            GestureDetector(
              onTap: () => _showPhotoViewer([existingUrl], 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  existingUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // ✅ Tampilkan URL yang gagal untuk debug
                    debugPrint('❌ Gagal load foto: $existingUrl — $error');
                    return _buildPhotoErrorWidget(existingUrl);
                  },
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : SizedBox(
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: prog.expectedTotalBytes != null
                                  ? prog.cumulativeBytesLoaded /
                                        prog.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF7BCEF5),
                            ),
                          ),
                        ),
                ),
              ),
            )
          else if (!hasExisting && newFile == null)
            _buildPhotoPlaceholder('Belum ada foto'),

          // ── New file preview ─────────────────────────────────────────────
          if (newFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                newFile,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tambahkan keterangan foto (opsional)...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
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
                    onPressed: onCancel,
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
                    onPressed: isUploading ? null : onUpload,
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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

          // ── Pick button ──────────────────────────────────────────────────
          if (newFile == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 18,
                  color: Color(0xFF7BCEF5),
                ),
                label: Text(
                  hasExisting ? 'Ganti Foto' : 'Pilih Foto',
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
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildMapSection() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD6EAF8), Color(0xFFEBF5FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: Colors.blueGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Maps',
              style: TextStyle(
                color: Colors.blueGrey.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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

  Widget _buildClockCard(String label, String time, String statusText) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7BCEF5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(String currentPriority) {
    final priorities = ['Low', 'Medium', 'High'];
    return Row(
      children: priorities.map((p) {
        final isSelected = p.toLowerCase() == currentPriority.toLowerCase();
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p != 'High' ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A3A6B)
                  : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              p,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7BCEF5), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildTextButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF7BCEF5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWoListItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String msg) {
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

  // ✅ Error widget yang tampilkan URL untuk membantu debug
  Widget _buildPhotoErrorWidget(String url) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.orange, size: 32),
          const SizedBox(height: 6),
          const Text(
            'Foto gagal dimuat',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: const TextStyle(color: Colors.grey, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          decoration: value ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF7BCEF5),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  String _formatTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return '-';
    }
  }
}

// ─── Full Screen Photo Viewer ─────────────────────────────────────────────────
class _PhotoViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PhotoViewerScreen({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
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
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7BCEF5),
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
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
          if (_current < widget.urls.length - 1)
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
