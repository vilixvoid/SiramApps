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
}
