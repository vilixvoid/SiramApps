import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/WorkOrderModel.dart';

class HomeRemoteDatasource {
  final ApiService _apiService;

  HomeRemoteDatasource(this._apiService);

  // ─── By Date (default, calendar tap) ─────────────────────────────────────
  Future<List<WorkOrderModel>> getMyWorkOrders({
    required String fromDate,
    required String toDate,
    String status = 'All',
    String district = 'All',
  }) async {
    await _apiService.loadToken();
    final response = await _apiService.post('data/myWorkOrderByDate', {
      'date': fromDate,
    });
    return _parseWorkOrders(response);
  }

  // ─── With Filter (FilterBottomSheet) ─────────────────────────────────────
  Future<List<WorkOrderModel>> getFilteredWorkOrders({
    required String fromDate,
    required String toDate,
    String status = 'All',
    String district = 'All',
    String search = '',
  }) async {
    await _apiService.loadToken();
    final response = await _apiService.post('data/myWorkOrderFilter', {
      'from_date': fromDate,
      'to_date': toDate,
      'status': status,
      'district': district,
      if (search.isNotEmpty) 'search': search,
    });
    return _parseWorkOrders(response);
  }

  List<WorkOrderModel> _parseWorkOrders(Map<String, dynamic> response) {
    final raw = response['workOrder'];
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => WorkOrderModel.fromJson(e))
        .toList();
  }
}
