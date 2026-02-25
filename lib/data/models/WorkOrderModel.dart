class WorkOrderModel {
  final String customerName;
  final String address;
  final String district;
  final int workOrderId;
  final String woType;
  final String woName;
  final String woDate;
  final String woTime;
  final String estTime;
  final String priority;
  final String status;

  WorkOrderModel({
    required this.customerName,
    required this.address,
    required this.district,
    required this.workOrderId,
    required this.woType,
    required this.woName,
    required this.woDate,
    required this.woTime,
    required this.estTime,
    required this.priority,
    required this.status,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      customerName: json['customer_name'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      workOrderId: json['work_order_id'] ?? 0,
      woType: json['wo_type'] ?? '',
      woName: json['wo_name'] ?? '',
      woDate: json['wo_date'] ?? '',
      woTime: json['wo_time'] ?? '',
      estTime: json['est_time'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
