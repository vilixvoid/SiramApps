import 'dart:io';
import 'package:siram/data/datasources/remote/DetailWorkOrderRemoteDatasource.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';

class DetailWorkOrderRepository {
  final DetailWorkOrderRemoteDatasource _remote;

  DetailWorkOrderRepository(this._remote);

  Future<DetailWorkOrderModel> getDetail(int workOrderId) async {
    try {
      return await _remote.getDetail(workOrderId);
    } catch (e) {
      throw Exception('Gagal memuat detail: $e');
    }
  }

  Future<void> checkin(int workOrderId) async {
    try {
      await _remote.checkin(workOrderId);
    } catch (e) {
      throw Exception('Check-in gagal: $e');
    }
  }

  Future<void> checkout(int workOrderId) async {
    try {
      await _remote.checkout(workOrderId);
    } catch (e) {
      throw Exception('Checkout gagal: $e');
    }
  }

  Future<void> saveNotes(int workOrderId, String notes) async {
    try {
      await _remote.saveNotes(workOrderId, notes);
    } catch (e) {
      throw Exception('Gagal simpan catatan: $e');
    }
  }

  Future<void> uploadPhoto({
    required int workOrderId,
    required String type,
    required File photo,
    required String token,
    String? notes,
  }) async {
    try {
      await _remote.uploadPhoto(
        workOrderId: workOrderId,
        type: type,
        photo: photo,
        token: token,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Upload foto gagal: $e');
    }
  }
}
