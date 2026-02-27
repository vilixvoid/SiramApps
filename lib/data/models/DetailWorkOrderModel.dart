// ─── DetailWorkOrderModel ─────────────────────────────────────────────────────
/// Seluruh data dari endpoint detailWorkOrder/:id

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
        json['workOrder'] as Map<String, dynamic>? ?? {},
      ),
      customer: CustomerDetail.fromJson(
        json['customer'] as Map<String, dynamic>? ?? {},
      ),
      customerAddress: CustomerAddress.fromJson(
        json['customerAddress'] as Map<String, dynamic>? ?? {},
      ),
      quotation: json['quotation'] != null
          ? QuotationDetail.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
      products: (json['product'] as List? ?? [])
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['item'] as List? ?? [])
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

// ─── WorkOrderDetail ──────────────────────────────────────────────────────────
class WorkOrderDetail {
  final int workOrderId;
  final String woName;
  final String woDate;
  final String woTime;
  final String estTime;
  final String priority;
  final String status;
  final String? checkin;
  final String? checkout;
  final String notes;
  final String notesTechnician;
  final String woType;

  const WorkOrderDetail({
    required this.workOrderId,
    required this.woName,
    required this.woDate,
    required this.woTime,
    required this.estTime,
    required this.priority,
    required this.status,
    this.checkin,
    this.checkout,
    required this.notes,
    required this.notesTechnician,
    required this.woType,
  });

  bool get hasCheckin => checkin != null;
  bool get hasCheckout => checkout != null;

  factory WorkOrderDetail.fromJson(Map<String, dynamic> json) {
    return WorkOrderDetail(
      workOrderId: (json['work_order_id'] as num?)?.toInt() ?? 0,
      woName: json['wo_name']?.toString() ?? '',
      woDate: json['wo_date']?.toString() ?? '',
      woTime: json['wo_time']?.toString() ?? '',
      estTime: json['est_time']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? '',
      checkin: json['checkin']?.toString(),
      checkout: json['checkout']?.toString(),
      notes: json['notes']?.toString() ?? '',
      notesTechnician: json['notes_technician']?.toString() ?? '',
      woType: json['wo_type']?.toString() ?? '',
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
      customerName: json['customer_name']?.toString() ?? '',
      cpPhone: json['cp_phone']?.toString() ?? '',
    );
  }
}

// ─── CustomerAddress ──────────────────────────────────────────────────────────
class CustomerAddress {
  final String address;
  final String district;
  final String city;

  const CustomerAddress({
    required this.address,
    required this.district,
    required this.city,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
    );
  }
}

// ─── QuotationDetail ─────────────────────────────────────────────────────────
class QuotationDetail {
  final String purchasingType;

  const QuotationDetail({required this.purchasingType});

  factory QuotationDetail.fromJson(Map<String, dynamic> json) {
    return QuotationDetail(
      purchasingType: json['purchasing_type']?.toString() ?? '',
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
      materialCode: json['material_code']?.toString() ?? '-',
      materialDesc: json['material_desc']?.toString() ?? '-',
      qty: json['qty']?.toString() ?? '1',
      stockCheck: json['stock_check']?.toString().toLowerCase() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

// ─── WorkOrderPod ─────────────────────────────────────────────────────────────
class WorkOrderPod {
  final String type; // 'before' | 'after'
  final String? s3Url;
  final String? url;
  final String? fileUrl;
  final String? s3Path;
  final String? podData; // base64 fallback
  final String notes;
  final String createdAt;

  const WorkOrderPod({
    required this.type,
    this.s3Url,
    this.url,
    this.fileUrl,
    this.s3Path,
    this.podData,
    required this.notes,
    required this.createdAt,
  });

  /// Ambil URL terbaik yang tersedia
  String get bestUrl {
    for (final v in [s3Url, url, fileUrl, s3Path]) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  factory WorkOrderPod.fromJson(Map<String, dynamic> json) {
    return WorkOrderPod(
      type: json['type']?.toString().toLowerCase().trim() ?? '',
      s3Url: json['s3_url']?.toString(),
      url: json['url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      s3Path: json['s3_path']?.toString(),
      podData: json['pod_data']?.toString(),
      notes: json['notes']?.toString() ?? json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

// ─── QuotationImage ───────────────────────────────────────────────────────────
class QuotationImage {
  final String imageId;
  final String s3Path;
  final String podName;
  final String podType;
  final int podSize;
  final String? podData;

  const QuotationImage({
    required this.imageId,
    required this.s3Path,
    required this.podName,
    required this.podType,
    required this.podSize,
    this.podData,
  });

  bool get isValid {
    if (s3Path.isEmpty) return false;
    final lower = s3Path.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif'))
      return true;
    return podType.startsWith('image/');
  }

  factory QuotationImage.fromJson(Map<String, dynamic> json) {
    return QuotationImage(
      imageId: json['quotation_image_id']?.toString() ?? '',
      s3Path: json['s3_path']?.toString() ?? '',
      podName: json['pod_name']?.toString() ?? '',
      podType: json['pod_type']?.toString() ?? '',
      podSize: (json['pod_size'] as num?)?.toInt() ?? 0,
      podData: json['pod_data']?.toString(),
    );
  }
}

// ─── CommentItem ─────────────────────────────────────────────────────────────
class CommentItem {
  final String createdBy;
  final String comment;

  const CommentItem({required this.createdBy, required this.comment});

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      createdBy: json['created_by']?.toString() ?? 'User',
      comment: json['comment']?.toString() ?? '',
    );
  }
}
