import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siram/data/models/WorkOrderModel.dart';
import 'package:siram/data/repositories/HomeRepository.dart';

enum HomeState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;

  HomeViewModel(this._repository);

  HomeState _state = HomeState.idle;
  List<WorkOrderModel> _workOrders = [];
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  HomeState get state => _state;
  List<WorkOrderModel> get workOrders => _workOrders;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == HomeState.loading;
  DateTime get selectedDate => _selectedDate;

  // Format: dd-MM-yyyy sesuai API
  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  Future<void> fetchWorkOrders({DateTime? date}) async {
    _selectedDate = date ?? _selectedDate;
    _state = HomeState.loading;
    notifyListeners();

    try {
      final formatted = _formatDate(_selectedDate);
      _workOrders = await _repository.getMyWorkOrders(
        fromDate: formatted,
        toDate: formatted,
      );
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HomeState.error;
    }

    notifyListeners();
  }

  void selectDate(DateTime date) {
    fetchWorkOrders(date: date);
  }
}
