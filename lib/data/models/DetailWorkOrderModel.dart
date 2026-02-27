import 'dart:convert';

// ─── Top-level model ──────────────────────────────────────────────────────────
class DetailWorkOrderModel {
  final WorkOrderDetail workOrder;
  final CustomerDetail customer;
  final CustomerAddress customerAddress;
  final QuotationDetail? quotation;
  final List<ProductItem> products;
  final List<ProductItem> items;
  final List<WorkOrderPod> workOrderPods;
  final List<QuotationImage> quotationImages;
  final List<CommentItem> comments;

  const DetailWorkOrderModel({
    required this.workOrder,
    required this.customer,
    required this.customerAddress,
    this.quotation,
    required this.products,
    required this.items,
    required this.workOrderPods,
    required this.quotationImages,
    required this.comments,
  });

  factory DetailWorkOrderModel.fromJson(Map<String, dynamic> json) {
    return DetailWorkOrderModel(
      workOrder: WorkOrderDetail.fromJson(
        (json['workOrder'] as Map<String, dynamic>? ?? {}),
      ),
      customer: CustomerDetail.fromJson(
        (json['customer'] as Map<String, dynamic>? ?? {}),
      ),
      customerAddress: CustomerAddress.fromJson(
        (json['customerAddress'] as Map<String, dynamic>? ?? {}),
      ),
      quotation: json['quotation'] != null
          ? QuotationDetail.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
      products: (json['product'] as List? ?? [])
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List? ?? [])
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      workOrderPods: (json['workOrderPod'] as List? ?? [])
          .map((e) => WorkOrderPod.fromJson(e as Map<String, dynamic>))
          .toList(),
      quotationImages: (json['quotationImage'] as List? ?? [])
          .map((e) => QuotationImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comment'] as List? ?? [])
          .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── WorkOrderPod ─────────────────────────────────────────────────────────────
class WorkOrderPod {
  final int id;
  final int workOrderId;
  final String podName;
  final int podSize;
  final String podType; // mime type e.g. "image/jpeg"
  final String podData; // base64 JPEG — sering terisi meski s3_url kosong
  final String podDate;
  final String type; // 'before' | 'after'
  final String notes; // field 'comment' atau 'remarks'
  final String s3Url; // bisa kosong
  final String s3Path; // bisa kosong
  final String createdAt;
  final String createdBy;

  static const String _baseUrl = 'https://siram.watercare.co.id/storage/';

  const WorkOrderPod({
    required this.id,
    required this.workOrderId,
    required this.podName,
    required this.podSize,
    required this.podType,
    required this.podData,
    required this.podDate,
    required this.type,
    required this.notes,
    required this.s3Url,
    required this.s3Path,
    required this.createdAt,
    required this.createdBy,
  });

  factory WorkOrderPod.fromJson(Map<String, dynamic> json) {
    return WorkOrderPod(
      id: _parseInt(json['work_order_pod_id']),
      workOrderId: _parseInt(json['work_order_id']),
      podName: json['pod_name']?.toString() ?? '',
      podSize: _parseInt(json['pod_size']),
      podType: json['pod_type']?.toString() ?? '',
      podData: json['pod_data']?.toString().trim() ?? '',
      podDate: json['pod_date']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase().trim() ?? '',
      // 'comment' field di API untuk keterangan foto, fallback ke 'remarks'
      notes: json['comment']?.toString().trim().isNotEmpty == true
          ? json['comment'].toString().trim()
          : json['remarks']?.toString().trim() ?? '',
      s3Url: json['s3_url']?.toString().trim() ?? '',
      s3Path: json['s3_path']?.toString().trim() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
    );
  }

  /// URL terbaik untuk load gambar via HTTP + Bearer token.
  /// Return '' jika tidak ada URL → gunakan [podBase64] sebagai gantinya.
  String get bestUrl {
    // Prioritas: s3_url → s3_path (gabung base)
    if (s3Url.isNotEmpty) {
      final u = s3Url.trim();
      if (u.startsWith('http://') || u.startsWith('https://')) return u;
      return '$_baseUrl$u';
    }
    if (s3Path.isNotEmpty) {
      final p = s3Path.trim();
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      return '$_baseUrl${p.startsWith('/') ? p.substring(1) : p}';
    }
    return ''; // kosong → pakai podBase64
  }

  /// Apakah foto tersedia (via URL atau base64)
  bool get hasPhoto => bestUrl.isNotEmpty || podData.isNotEmpty;

  /// Decode base64 ke bytes. Null jika podData kosong atau invalid.
  List<int>? get podBytes {
    if (podData.isEmpty) return null;
    try {
      return base64Decode(podData);
    } catch (_) {
      return null;
    }
  }

  static int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

// ─── QuotationImage ───────────────────────────────────────────────────────────
class QuotationImage {
  final int id;
  final String s3Path;
  final int podSize;
  final String podType;
  final String podName; // nama file asli, ditampilkan sebagai caption

  static const String _baseUrl = 'https://siram.watercare.co.id/storage/';

  const QuotationImage({
    required this.id,
    required this.s3Path,
    required this.podSize,
    required this.podType,
    required this.podName,
  });

  factory QuotationImage.fromJson(Map<String, dynamic> json) {
    return QuotationImage(
      id: int.tryParse(json['quotation_image_id']?.toString() ?? '0') ?? 0,
      s3Path: json['s3_path']?.toString().trim() ?? '',
      podSize: int.tryParse(json['pod_size']?.toString() ?? '0') ?? 0,
      podType: json['pod_type']?.toString() ?? '',
      podName: json['pod_name']?.toString() ?? '',
    );
  }

  /// ID sebagai string untuk cache key di _SurveyImageWidget
  String get imageId => id > 0 ? id.toString() : '';

  bool get isValid {
    if (s3Path.isEmpty) return false;
    if (podSize == 0 && !podType.startsWith('image/')) return false;
    return true;
  }

  String get url {
    if (s3Path.isEmpty) return '';
    if (s3Path.startsWith('http://') || s3Path.startsWith('https://')) {
      return s3Path;
    }
    return '$_baseUrl${s3Path.startsWith('/') ? s3Path.substring(1) : s3Path}';
  }
}

// ─── WorkOrderDetail ──────────────────────────────────────────────────────────
class WorkOrderDetail {
  final int id;
  final String woName;
  final String woDate;
  final String woTime;
  final String estTime;
  final String woType;
  final String priority;
  final String status;
  final String notes;
  final String notesTechnician;
  final String? checkin;
  final String? checkout;

  const WorkOrderDetail({
    required this.id,
    required this.woName,
    required this.woDate,
    required this.woTime,
    required this.estTime,
    required this.woType,
    required this.priority,
    required this.status,
    required this.notes,
    required this.notesTechnician,
    this.checkin,
    this.checkout,
  });

  bool get hasCheckin => checkin != null && checkin!.isNotEmpty;
  bool get hasCheckout => checkout != null && checkout!.isNotEmpty;

  factory WorkOrderDetail.fromJson(Map<String, dynamic> json) {
    return WorkOrderDetail(
      id: int.tryParse(json['work_order_id']?.toString() ?? '0') ?? 0,
      woName: json['wo_name']?.toString() ?? '-',
      woDate: json['wo_date']?.toString() ?? '-',
      woTime: json['wo_time']?.toString() ?? '-',
      estTime: json['est_time']?.toString() ?? '-',
      woType: json['wo_type']?.toString() ?? '-',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      notesTechnician: json['notes_technician']?.toString() ?? '',
      checkin: json['checkin']?.toString(),
      checkout: json['checkout']?.toString(),
    );
  }
}

// ─── CustomerDetail ───────────────────────────────────────────────────────────
class CustomerDetail {
  final String customerName;
  final String cpPhone;

  const CustomerDetail({required this.customerName, required this.cpPhone});

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      customerName: json['customer_name']?.toString() ?? '-',
      cpPhone: json['cp_phone']?.toString() ?? '',
    );
  }
}

// ─── CustomerAddress ──────────────────────────────────────────────────────────
class CustomerAddress {
  final String address;

  const CustomerAddress({required this.address});

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(address: json['address']?.toString() ?? '-');
  }
}

// ─── QuotationDetail ──────────────────────────────────────────────────────────
class QuotationDetail {
  final String purchasingType;

  const QuotationDetail({required this.purchasingType});

  factory QuotationDetail.fromJson(Map<String, dynamic> json) {
    return QuotationDetail(
      purchasingType: json['purchasing_type']?.toString() ?? '-',
    );
  }
}

// ─── ProductItem ──────────────────────────────────────────────────────────────
class ProductItem {
  final String materialCode;
  final String materialDesc;
  final String qty;
  final String stockCheck;
  final String remarks;

  const ProductItem({
    required this.materialCode,
    required this.materialDesc,
    required this.qty,
    required this.stockCheck,
    required this.remarks,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      materialCode:
          json['material_code']?.toString() ??
          json['kode_material']?.toString() ??
          '-',
      materialDesc:
          json['material_desc']?.toString() ??
          json['nama_material']?.toString() ??
          '-',
      qty: json['qty']?.toString() ?? '0',
      stockCheck: json['stock_check']?.toString() ?? 'n',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

// ─── CommentItem ──────────────────────────────────────────────────────────────
class CommentItem {
  final String comment;
  final String createdBy;
  final String createdAt;

  const CommentItem({
    required this.comment,
    required this.createdBy,
    required this.createdAt,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      comment: json['comment']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? 'User',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
