import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siram/viewmodel/HomeViewModel.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // 0=Mon ... 6=Sun, kita pakai Sun=0
    int startWeekday = firstDay.weekday % 7; // Minggu = 0
    final days = <DateTime?>[];

    for (int i = 0; i < startWeekday; i++) {
      days.add(null); // padding kosong
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    return days;
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.watch<HomeViewModel>().selectedDate;
    final days = _buildCalendarDays();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: const Icon(Icons.chevron_left, color: Colors.grey),
              ),
              Text(
                "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Label hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
                .map(
                  (d) => SizedBox(
                    width: 35,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),

          // Grid tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 0,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();

              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;

              final isToday =
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () {
                  context.read<HomeViewModel>().selectDate(date);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF25723)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF7BCEF5), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
