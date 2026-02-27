import 'package:siram/data/datasources/remote/HomeRemoteDataSource.dart';
import 'package:siram/data/models/WorkOrderModel.dart';

class HomeRepository {
  final HomeRemoteDatasource _remoteDataSource;

  HomeRepository(this._remoteDataSource);

  Future<List<WorkOrderModel>> getMyWorkOrders({
    required String fromDate,
    required String toDate,
    String status = 'All',
    String district = 'All',
  }) async {
    try {
      return await _remoteDataSource.getMyWorkOrders(
        fromDate: fromDate,
        toDate: toDate,
        status: status,
        district: district,
      );
    } catch (e) {
      throw Exception('Gagal mengambil data work order: $e');
    }
  }

  // ✅ Method baru untuk filter
  Future<List<WorkOrderModel>> getFilteredWorkOrders({
    required String fromDate,
    required String toDate,
    String status = 'All',
    String district = 'All',
    String search = '',
  }) async {
    try {
      return await _remoteDataSource.getFilteredWorkOrders(
        fromDate: fromDate,
        toDate: toDate,
        status: status,
        district: district,
        search: search,
      );
    } catch (e) {
      throw Exception('Gagal filter work order: $e');
    }
  }
}
