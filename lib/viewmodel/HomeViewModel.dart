import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siram/data/models/WorkOrderModel.dart';
import 'package:siram/data/repositories/HomeRepository.dart';
import 'package:siram/view/widgets/FilterWidget.dart'; // ✅ import FilterParams

enum HomeState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;

  HomeViewModel(this._repository);

  HomeState _state = HomeState.idle;
  List<WorkOrderModel> _workOrders = [];
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  // ✅ Filter state
  FilterParams? _activeFilter;
  bool get isFiltered => _activeFilter != null && _activeFilter!.isActive;
  FilterParams? get activeFilter => _activeFilter;

  HomeState get state => _state;
  List<WorkOrderModel> get workOrders => _workOrders;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == HomeState.loading;
  DateTime get selectedDate => _selectedDate;

  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  // ─── Fetch by date (calendar) ─────────────────────────────────────────────
  Future<void> fetchWorkOrders({DateTime? date}) async {
    _selectedDate = date ?? _selectedDate;
    _activeFilter = null; // reset filter saat tap calendar
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

  // ─── Fetch with filter ────────────────────────────────────────────────────
  Future<void> applyFilter(FilterParams params) async {
    _activeFilter = params;
    _state = HomeState.loading;
    notifyListeners();

    try {
      _workOrders = await _repository.getFilteredWorkOrders(
        fromDate: params.fromDate,
        toDate: params.toDate,
        status: params.status,
        district: params.district,
        search: params.search,
      );
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = HomeState.error;
    }

    notifyListeners();
  }

  // ─── Clear filter → kembali ke tanggal hari ini ───────────────────────────
  Future<void> clearFilter() async {
    _activeFilter = null;
    await fetchWorkOrders(date: _selectedDate);
  }

  void selectDate(DateTime date) {
    fetchWorkOrders(date: date);
  }
}
