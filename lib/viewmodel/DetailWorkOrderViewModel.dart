import 'dart:io';
import 'package:flutter/material.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';
import 'package:siram/data/repositories/DetailWorkOrderRepository.dart';

enum DetailState { idle, loading, success, error }

enum ActionState { idle, loading, success, error }

class DetailWorkOrderViewModel extends ChangeNotifier {
  final DetailWorkOrderRepository _repository;
  final int workOrderId;
  final String token;

  DetailWorkOrderViewModel({
    required DetailWorkOrderRepository repository,
    required this.workOrderId,
    required this.token,
  }) : _repository = repository;

  // ── Data state ─────────────────────────────────────────────────────────────
  DetailState _state = DetailState.idle;
  DetailWorkOrderModel? _detail;
  String _errorMessage = '';

  DetailState get state => _state;
  DetailWorkOrderModel? get detail => _detail;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == DetailState.loading;

  // ── Action states (checkin/checkout/upload/saveNotes) ──────────────────────
  ActionState _checkinOutState = ActionState.idle;
  ActionState _uploadBeforeState = ActionState.idle;
  ActionState _uploadAfterState = ActionState.idle;
  ActionState _saveNotesState = ActionState.idle;

  bool get isSubmitting => _checkinOutState == ActionState.loading;
  bool get isUploadingBefore => _uploadBeforeState == ActionState.loading;
  bool get isUploadingAfter => _uploadAfterState == ActionState.loading;
  bool get isSavingNotes => _saveNotesState == ActionState.loading;

  // ── Checklist state (local UI only) ───────────────────────────────────────
  bool checkAreaDibersihkan = false;
  bool checkTandaTangan = false;
  bool checkPenutupanTiket = false;
  bool? statusUnitBaik;

  void toggleChecklist(String key, bool value) {
    switch (key) {
      case 'area':
        checkAreaDibersihkan = value;
        break;
      case 'ttd':
        checkTandaTangan = value;
        break;
      case 'tutup':
        checkPenutupanTiket = value;
        break;
    }
    notifyListeners();
  }

  void setStatusUnit(bool baik) {
    statusUnitBaik = baik;
    notifyListeners();
  }

  // ── Derived getters ────────────────────────────────────────────────────────
  List<WorkOrderPod> getPodsOfType(String type) {
    return (_detail?.workOrderPods ?? [])
        .where((p) => p.type == type.toLowerCase())
        .toList();
  }

  List<QuotationImage> get validSurveyImages {
    return (_detail?.quotationImages ?? [])
        .where((img) => img.isValid)
        .toList();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchDetail() async {
    _state = DetailState.loading;
    _errorMessage = '';
    notifyListeners();
    try {
      _detail = await _repository.getDetail(workOrderId);
      _state = DetailState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = DetailState.error;
    }
    notifyListeners();
  }

  // ── Checkin / Checkout ─────────────────────────────────────────────────────
  Future<String?> handleCheckinCheckout() async {
    final wo = _detail?.workOrder;
    if (wo == null || wo.hasCheckout) return null;

    _checkinOutState = ActionState.loading;
    notifyListeners();
    try {
      if (!wo.hasCheckin) {
        await _repository.checkin(workOrderId);
      } else {
        await _repository.checkout(workOrderId);
      }
      _checkinOutState = ActionState.success;
      notifyListeners();
      await fetchDetail();
      return wo.hasCheckin
          ? 'Tugas berhasil diselesaikan!'
          : 'Check-in berhasil!';
    } catch (e) {
      _checkinOutState = ActionState.error;
      notifyListeners();
      return null;
    }
  }

  // ── Save Notes ─────────────────────────────────────────────────────────────
  Future<bool> saveNotes(String notes) async {
    _saveNotesState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.saveNotes(workOrderId, notes);
      _saveNotesState = ActionState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _saveNotesState = ActionState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Upload Photo Before ────────────────────────────────────────────────────
  Future<bool> uploadPhotoBefore(File photo, {String? notes}) async {
    _uploadBeforeState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.uploadPhoto(
        workOrderId: workOrderId,
        type: 'before',
        photo: photo,
        token: token,
        notes: notes,
      );
      _uploadBeforeState = ActionState.success;
      notifyListeners();
      await fetchDetail();
      return true;
    } catch (e) {
      _uploadBeforeState = ActionState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Upload Photo After ─────────────────────────────────────────────────────
  Future<bool> uploadPhotoAfter(File photo, {String? notes}) async {
    _uploadAfterState = ActionState.loading;
    notifyListeners();
    try {
      await _repository.uploadPhoto(
        workOrderId: workOrderId,
        type: 'after',
        photo: photo,
        token: token,
        notes: notes,
      );
      _uploadAfterState = ActionState.success;
      notifyListeners();
      await fetchDetail();
      return true;
    } catch (e) {
      _uploadAfterState = ActionState.error;
      notifyListeners();
      return false;
    }
  }
}
