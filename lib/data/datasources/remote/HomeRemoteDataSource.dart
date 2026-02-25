import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/models/WorkOrderModel.dart';

class HomeRemoteDatasource {
  final ApiService _apiService;

  HomeRemoteDatasource(this._apiService);

  Future<List<WorkOrderModel>> getMyWorkOrders({
    required String fromDate,
    required String toDate,
    String status = 'All',
    String district = 'All',
  }) async {
    final body = {
      'from_date': fromDate,
      'to_date': toDate,
      'status': status,
      'district': district,
    };

    final response = await _apiService.post('data/myWorkOrderFilter', body);

    // Cek key yang ada di response
    final workOrderRaw = response['workOrder'];

    if (workOrderRaw == null) {
      return [];
    }

    final List<dynamic> data = workOrderRaw as List<dynamic>;

    return data.map((e) => WorkOrderModel.fromJson(e)).toList();
  }
}
