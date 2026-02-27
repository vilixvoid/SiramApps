import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterParams {
  final String fromDate;
  final String toDate;
  final String status;
  final String district;
  final String search;

  const FilterParams({
    required this.fromDate,
    required this.toDate,
    this.status = 'All',
    this.district = 'All',
    this.search = '',
  });

  bool get isActive =>
      status != 'All' ||
      district != 'All' ||
      search.isNotEmpty ||
      fromDate != toDate;

  FilterParams copyWith({
    String? fromDate,
    String? toDate,
    String? status,
    String? district,
    String? search,
  }) {
    return FilterParams(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      district: district ?? this.district,
      search: search ?? this.search,
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────
class FilterBottomSheet extends StatefulWidget {
  final FilterParams initialParams;
  final void Function(FilterParams) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialParams,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required FilterParams initialParams,
    required void Function(FilterParams) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          FilterBottomSheet(initialParams: initialParams, onApply: onApply),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late DateTime _fromDate;
  late DateTime _toDate;
  late String _status;
  late String _district;
  late TextEditingController _searchController;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;

  static const _statusOptions = [
    'All',
    'Assigned',
    'On Progress',
    'Finished',
    'Pending',
  ];
  static const _districtOptions = [
    'All',
    'Kebayoran Lama',
    'Setia Budi',
    'Menteng',
    'Tebet',
    'Pancoran',
    'Mampang',
    'Cilandak',
    'Pasar Minggu',
  ];

  final _fmt = DateFormat('dd-MM-yyyy');
  final _displayFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _fromDate = _parseDate(widget.initialParams.fromDate);
    _toDate = _parseDate(widget.initialParams.toDate);
    _status = widget.initialParams.status;
    _district = widget.initialParams.district;
    _searchController = TextEditingController(
      text: widget.initialParams.search,
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  DateTime _parseDate(String s) {
    try {
      return _fmt.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7BCEF5),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      } else {
        _toDate = picked;
        if (_fromDate.isAfter(_toDate)) _fromDate = _toDate;
      }
    });
  }

  void _reset() {
    final now = DateTime.now();
    setState(() {
      _fromDate = now;
      _toDate = now;
      _status = 'All';
      _district = 'All';
      _searchController.clear();
    });
  }

  void _apply() {
    widget.onApply(
      FilterParams(
        fromDate: _fmt.format(_fromDate),
        toDate: _fmt.format(_toDate),
        status: _status,
        district: _district,
        search: _searchController.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF7BCEF5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Kunjungan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Color(0xFF7BCEF5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Content ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    _buildLabel('Cari Pelanggan'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Nama pelanggan atau WO...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF7BCEF5),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() => _searchController.clear());
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7BCEF5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Date Range
                    _buildLabel('Rentang Tanggal'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Dari',
                            date: _fromDate,
                            onTap: () => _pickDate(isFrom: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            width: 20,
                            height: 1.5,
                            color: const Color(0xFFBBBBBB),
                          ),
                        ),
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Sampai',
                            date: _toDate,
                            onTap: () => _pickDate(isFrom: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status
                    _buildLabel('Status'),
                    const SizedBox(height: 8),
                    _buildChipSelector(
                      options: _statusOptions,
                      selected: _status,
                      onSelect: (v) => setState(() => _status = v),
                      activeColor: const Color(0xFF7BCEF5),
                    ),
                    const SizedBox(height: 20),

                    // District
                    _buildLabel('District'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _district,
                      options: _districtOptions,
                      onChanged: (v) => setState(() => _district = v ?? 'All'),
                    ),
                    const SizedBox(height: 28),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7BCEF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terapkan Filter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Color(0xFF7BCEF5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    _displayFmt.format(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
    required Color activeColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeColor : const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7BCEF5),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
