import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';

class DetailWorkOrderRemoteDatasource {
  final ApiService _apiService;

  DetailWorkOrderRemoteDatasource(this._apiService);

  Future<DetailWorkOrderModel> getDetail(int workOrderId) async {
    await _apiService.loadToken();
    final json = await _apiService.get('data/detailWorkOrder/$workOrderId');
    return DetailWorkOrderModel.fromJson(json);
  }

  Future<void> checkin(int workOrderId) async {
    await _apiService.loadToken();
    await _apiService.post('data/checkin', {'work_order_id': workOrderId});
  }

  Future<void> checkout(int workOrderId) async {
    await _apiService.loadToken();
    await _apiService.post('data/checkout', {'work_order_id': workOrderId});
  }

  Future<void> saveNotes(int workOrderId, String notes) async {
    await _apiService.loadToken();
    await _apiService.post('data/editNotes', {
      'work_order_id': workOrderId,
      'notes_technician': notes,
    });
  }

  Future<void> uploadPhoto({
    required int workOrderId,
    required String type, // 'before' | 'after'
    required File photo,
    required String token,
    String? notes,
  }) async {
    await _apiService.loadToken();
    final endpoint = type == 'before'
        ? 'uploadPhotoBefore'
        : 'uploadPhotoAfter';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_apiService.baseUrl}/data/$endpoint'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['work_order_id'] = workOrderId.toString();
    if (notes != null && notes.isNotEmpty) {
      request.fields['notes'] = notes;
    }
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    final resp = await request.send();
    if (resp.statusCode != 200) {
      throw Exception('Upload gagal (${resp.statusCode})');
    }
  }
}
