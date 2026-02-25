import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          // 1. Blue Background Header
          Container(
            height: 300,
            decoration: const BoxDecoration(
              color: Color(0xFF7BCEF5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Profile & Notification Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Good Morning",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Mayhesta Gilang\nMaulana",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF7BCEF5),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Calendar Card
                  const CalendarWidget(),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Text(
                      "Daftar Kunjungan",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 4. List of Visits
                  const VisitCard(
                    name: "John Doe",
                    priority: "High Priority",
                    priorityColor: Color(0xFFFFC5C5),
                    textColor: Color(0xFFD32F2F),
                  ),
                  const VisitCard(
                    name: "John Doe",
                    priority: "Medium Priority",
                    priorityColor: Color(0xFFF0E199),
                    textColor: Color(0xFF8D7701),
                    showArrow: true,
                  ),
                  const SizedBox(
                    height: 100,
                  ), // Padding bawah agar tidak tertutup nav bar
                ],
              ),
            ),
          ),
        ],
      ),

      // 5. Custom Bottom Navigation Bar
      bottomNavigationBar: const CustomNavBar(),
    );
  }
}

// --- Widget Kalender Sederhana ---
class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.chevron_left, color: Colors.grey),
              Text(
                "September 2021",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          // Baris Hari (S M T W T F S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["SAN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          // Contoh Baris Angka (Hanya menampilkan baris terpilih sesuai gambar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDate("15"),
              _buildDate("16"),
              _buildDate("17"),
              _buildDate("18"),
              _buildDate("19", isSelected: true),
              _buildDate("20"),
              _buildDate("21"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDate(String date, {bool isSelected = false}) {
    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF25723) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        date,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- Widget Card Kunjungan ---
class VisitCard extends StatelessWidget {
  final String name;
  final String priority;
  final Color priorityColor;
  final Color textColor;
  final bool showArrow;

  const VisitCard({
    super.key,
    required this.name,
    required this.priority,
    required this.priorityColor,
    required this.textColor,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      "Assigned",
                      const Color(0xFFD3EAE7),
                      const Color(0xFF55938D),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.access_time, size: 16, color: Color(0xFF7BCEF5)),
                    SizedBox(width: 5),
                    Text(
                      "8:00 AM - 10:00 AM",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.location_on, size: 16, color: Color(0xFF7BCEF5)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Jl. Malabar 3 Tangerang: Berlokasi di Cibodasari,\nKec. Cibodas, Kota Tangerang, Banten",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
    );
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

// --- Widget Bottom Navigation ---
class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, "Home", true),
          _navItem(Icons.account_circle, "Profile", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 35,
          color: isActive
              ? const Color(0xFF7BCEF5)
              : Colors.grey.withOpacity(0.5),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFF7BCEF5)
                : Colors.grey.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
