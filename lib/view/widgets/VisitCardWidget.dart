import 'package:flutter/material.dart';
import 'package:siram/view/screens/detail/DetailWorkOrderScreen.dart'; // ✅ Import screen detail

class VisitCard extends StatelessWidget {
  final String name;
  final String priority;
  final Color priorityColor;
  final Color textColor;
  final String status;
  final String timeStart;
  final String timeEnd;
  final String address;
  final String woDate;
  final String woName;
  final bool showArrow;

  // ✅ Tambahkan 2 parameter baru ini
  final int workOrderId;
  final String token;

  const VisitCard({
    super.key,
    required this.name,
    required this.priority,
    required this.priorityColor,
    required this.textColor,
    required this.workOrderId, // ✅ required
    required this.token, // ✅ required
    this.status = '',
    this.timeStart = '',
    this.timeEnd = '',
    this.address = '',
    this.woDate = '',
    this.woName = '',
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Wrap Container dengan GestureDetector
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailWorkOrderScreen(workOrderId: workOrderId, token: token),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLabel(priority, priorityColor, textColor),
                      const SizedBox(width: 8),
                      _buildLabel(
                        status.isNotEmpty ? status : 'Assigned',
                        _getStatusBgColor(status),
                        _getStatusTextColor(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (woName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        woName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (woDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF7BCEF5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            woDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF7BCEF5),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeStart.isNotEmpty ? "$timeStart ($timeEnd)" : "-",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF7BCEF5),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address.isNotEmpty ? address : "-",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'finished':
        return const Color(0xFFD3EAE7);
      case 'assigned':
        return const Color(0xFFD3EAE7);
      case 'on progress':
        return const Color(0xFFD6EAF8);
      case 'pending':
        return const Color(0xFFF0E199);
      default:
        return const Color(0xFFD3EAE7);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'finished':
        return const Color(0xFF55938D);
      case 'assigned':
        return const Color(0xFF55938D);
      case 'on progress':
        return const Color(0xFF1A5276);
      case 'pending':
        return const Color(0xFF8D7701);
      default:
        return const Color(0xFF55938D);
    }
  }

  Widget _buildLabel(String text, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textC,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
