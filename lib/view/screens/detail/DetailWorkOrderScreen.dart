import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:siram/core/services/ApiServices.dart';

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

  // URL base untuk storage — sudah confirmed bisa diakses dengan Bearer token
  static const String _s3BaseUrl = 'https://siram.watercare.co.id/storage/';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchDetail();
  }

  // ─── Fetch ───────────────────────────────────────────────────────────────
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
        _notesController.text = (data['workOrder']?['notes_technician'] ?? '')
            .toString();
      });
      _debugPhotos(data);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _debugPhotos(Map<String, dynamic> data) {
    debugPrint('════ DEBUG FOTO WO #${widget.workOrderId} ════');
    final pods = data['workOrderPod'] as List? ?? [];
    debugPrint('workOrderPod count: ${pods.length}');
    for (final p in pods) {
      if (p is! Map) continue;
      debugPrint(
        '  pod id=${p['work_order_pod_id']} type=${p['type']} '
        's3_url="${p['s3_url']}" s3_path="${p['s3_path']}" '
        'pod_data_len=${(p['pod_data']?.toString().length ?? 0)}',
      );
    }
    final imgs = data['quotationImage'] as List? ?? [];
    debugPrint('quotationImage count: ${imgs.length}');
    debugPrint('════════════════════════════════════════');
  }

  // ─── URL / Pod helpers ────────────────────────────────────────────────────
  String _buildPhotoUrl(String? s3Path) {
    if (s3Path == null || s3Path.trim().isEmpty) return '';
    final t = s3Path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = _s3BaseUrl.endsWith('/') ? _s3BaseUrl : '$_s3BaseUrl/';
    return '$base${t.startsWith('/') ? t.substring(1) : t}';
  }

  /// Cari URL (s3_url atau s3_path) dari workOrderPod berdasarkan type.
  /// Return '' jika tidak ada URL tapi ada pod_data — pakai _findPodBase64.
  String _findPodUrl(String type) {
    final List pods = _data?['workOrderPod'] as List? ?? [];
    final String t = type.toLowerCase().trim();
    for (final pod in pods) {
      if (pod is! Map) continue;
      if ((pod['type']?.toString().toLowerCase().trim() ?? '') != t) continue;
      for (final key in ['s3_url', 'url', 'file_url', 'full_url', 's3_path']) {
        final val = pod[key]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          debugPrint('pod "$type" URL via "$key": $val');
          return _buildPhotoUrl(val);
        }
      }
      // Pod ada tapi semua URL kosong → ada pod_data, return '' agar pakai base64
      return '';
    }
    return '';
  }

  /// Ambil pod_data (base64 JPEG) — primary source ketika s3_url kosong.
  String? _findPodBase64(String type) {
    final List pods = _data?['workOrderPod'] as List? ?? [];
    final String t = type.toLowerCase().trim();
    for (final pod in pods) {
      if (pod is! Map) continue;
      if ((pod['type']?.toString().toLowerCase().trim() ?? '') != t) continue;
      final data = pod['pod_data']?.toString().trim() ?? '';
      if (data.isNotEmpty) return data;
    }
    return null;
  }

  /// Apakah ada pod (before/after) di workOrderPod?
  bool _hasPod(String type) {
    final List pods = _data?['workOrderPod'] as List? ?? [];
    final String t = type.toLowerCase().trim();
    for (final pod in pods) {
      if (pod is! Map) continue;
      if ((pod['type']?.toString().toLowerCase().trim() ?? '') == t)
        return true;
    }
    return false;
  }

  bool _isValidImage(Map img) {
    final s3Path = img['s3_path']?.toString() ?? '';
    if (s3Path.isEmpty) return false;
    final podSize = int.tryParse(img['pod_size']?.toString() ?? '0') ?? 0;
    final podType = img['pod_type']?.toString() ?? '';
    if (podSize == 0 && !podType.startsWith('image/')) return false;
    return true;
  }

  // ─── Upload Before ───────────────────────────────────────────────────────
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/data/uploadPhotoBefore'),
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

  // ─── Upload After ────────────────────────────────────────────────────────
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/data/uploadPhotoAfter'),
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
    if (wo['checkout'] != null) return;
    setState(() => _isSubmitting = true);
    try {
      if (wo['checkin'] == null) {
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
    String n = phone.replaceAll(RegExp(r'\D'), '');
    if (n.startsWith('0')) n = '62${n.substring(1)}';
    final url = Uri.parse('https://wa.me/$n');
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

  void _showPhotoViewer(List<String> urls, int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewerScreen(
          urls: urls,
          initialIndex: idx,
          token: widget.token,
        ),
      ),
    );
  }

  void _showBase64Viewer(String base64Data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _Base64ViewerScreen(base64Data: base64Data),
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
    final String checkInTime = hasCheckin ? _formatTime(wo['checkin']) : '-';
    final String checkOutTime = hasCheckout ? _formatTime(wo['checkout']) : '-';

    // Survey Photos dari quotationImage
    final List rawImgs = _data?['quotationImage'] as List? ?? [];
    final List<String> surveyUrls = rawImgs
        .where((img) => img is Map && _isValidImage(img as Map))
        .map<String>((img) => _buildPhotoUrl(img['s3_path'] as String))
        .where((u) => u.isNotEmpty)
        .toList();

    // Photo Before / After dari workOrderPod
    final bool hasBefore = _hasPod('before');
    final bool hasAfter = _hasPod('after');
    final String beforeUrl = _findPodUrl('before');
    final String? beforeB64 = _findPodBase64('before');
    final String afterUrl = _findPodUrl('after');
    final String? afterB64 = _findPodBase64('after');

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMapSection(),
          const SizedBox(height: 12),

          // Lokasi
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

          // Clock
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

          // Customer
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

          // Priority
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

          // WO List
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

          // Photo Before
          _buildPhotoCard(
            title: 'Photo Before',
            icon: Icons.camera_alt_outlined,
            hasPod: hasBefore,
            podUrl: beforeUrl,
            podBase64: beforeB64,
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

          // Photo After
          _buildPhotoCard(
            title: 'Photo After',
            icon: Icons.add_photo_alternate_outlined,
            hasPod: hasAfter,
            podUrl: afterUrl,
            podBase64: afterB64,
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

          // Survey Photo
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
                    if (surveyUrls.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showPhotoViewer(surveyUrls, 0),
                        child: _buildTextButton('Lihat Semua'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (surveyUrls.isEmpty)
                  _buildPhotoPlaceholder('Belum ada foto survey')
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: surveyUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showPhotoViewer(surveyUrls, i),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _AuthImage(
                              url: surveyUrls[i],
                              token: widget.token,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (surveyUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${surveyUrls.length} foto survey',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Catatan Teknisi
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

          // Comment
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

          // Checklist
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

          // Main Button
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
    required bool hasPod,
    required String podUrl,
    required String? podBase64,
    required File? newFile,
    required TextEditingController noteController,
    required bool isUploading,
    required VoidCallback onPick,
    required Future<void> Function() onUpload,
    required VoidCallback onCancel,
  }) {
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
              if (hasPod && newFile == null)
                GestureDetector(
                  onTap: () {
                    if (podUrl.isNotEmpty) {
                      _showPhotoViewer([podUrl], 0);
                    } else if (podBase64 != null) {
                      _showBase64Viewer(podBase64);
                    }
                  },
                  child: _buildTextButton('Detail'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Existing photo
          if (hasPod && newFile == null)
            GestureDetector(
              onTap: () {
                if (podUrl.isNotEmpty) {
                  _showPhotoViewer([podUrl], 0);
                } else if (podBase64 != null) {
                  _showBase64Viewer(podBase64);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: podUrl.isNotEmpty
                    ? _AuthImage(
                        url: podUrl,
                        token: widget.token,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        base64Fallback: podBase64,
                      )
                    : podBase64 != null
                    ? _Base64Image(
                        base64Data: podBase64,
                        height: 160,
                        width: double.infinity,
                      )
                    : _buildPhotoPlaceholder('Gagal memuat foto'),
              ),
            )
          else if (!hasPod && newFile == null)
            _buildPhotoPlaceholder('Belum ada foto'),

          // New file preview
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
                  hasPod ? 'Ganti Foto' : 'Pilih Foto',
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

  // ─── Widget Helpers ───────────────────────────────────────────────────────
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

// ─── _AuthImage ───────────────────────────────────────────────────────────────
/// Image dengan Authorization Bearer token. Fallback ke base64 jika URL gagal.
class _AuthImage extends StatelessWidget {
  final String url;
  final String token;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? base64Fallback;

  const _AuthImage({
    required this.url,
    required this.token,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.base64Fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      if (base64Fallback != null && base64Fallback!.isNotEmpty) {
        return _Base64Image(
          base64Data: base64Fallback!,
          height: height,
          width: width,
          fit: fit,
        );
      }
      return SizedBox(height: height, width: width);
    }

    return Image(
      image: NetworkImage(url, headers: {'Authorization': 'Bearer $token'}),
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (_, child, prog) => prog == null
          ? child
          : SizedBox(
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: prog.expectedTotalBytes != null
                      ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF7BCEF5),
                  strokeWidth: 2,
                ),
              ),
            ),
      errorBuilder: (_, err, __) {
        debugPrint('❌ _AuthImage error: $url — $err');
        if (base64Fallback != null && base64Fallback!.isNotEmpty) {
          return _Base64Image(
            base64Data: base64Fallback!,
            height: height,
            width: width,
            fit: fit,
          );
        }
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
      },
    );
  }
}

// ─── _Base64Image ─────────────────────────────────────────────────────────────
/// Render gambar langsung dari base64 string (pod_data dari API).
class _Base64Image extends StatelessWidget {
  final String base64Data;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _Base64Image({
    required this.base64Data,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final Uint8List bytes = base64Decode(base64Data);
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

  Widget _broken() => SizedBox(
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

// ─── _Base64ViewerScreen ──────────────────────────────────────────────────────
class _Base64ViewerScreen extends StatelessWidget {
  final String base64Data;
  const _Base64ViewerScreen({required this.base64Data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Foto',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _Base64Image(base64Data: base64Data, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ─── _PhotoViewerScreen ───────────────────────────────────────────────────────
class _PhotoViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String token;

  const _PhotoViewerScreen({
    required this.urls,
    required this.initialIndex,
    required this.token,
  });

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
                child: Image(
                  image: NetworkImage(
                    widget.urls[i],
                    headers: {'Authorization': 'Bearer ${widget.token}'},
                  ),
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
