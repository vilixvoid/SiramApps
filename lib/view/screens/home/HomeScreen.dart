import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siram/view/navigation/NavigationBottom.dart';
import 'package:siram/view/screens/profile/ProfileScreen.dart';
import 'package:siram/view/widgets/CalendarWidget.dart';
import 'package:siram/view/widgets/HeaderWidget.dart';
import 'package:siram/view/widgets/VisitCardWidget.dart';
import 'package:siram/viewmodel/HomeViewModel.dart';
import 'package:siram/viewmodel/LoginViewModel.dart'; // ✅ Import LoginViewModel

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [_HomePage(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBottom(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeViewModel>().fetchWorkOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Ambil token dari LoginViewModel → currentUser
    // Jika nama field di UserModel berbeda, ganti .token → .accessToken / .authToken
    final String token =
        context.read<LoginViewModel>().currentUser?.token ?? '';

    return Stack(
      children: [
        Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Color(0xFF7BCEF5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderWidget(),
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
                Consumer<HomeViewModel>(
                  builder: (_, viewModel, __) {
                    if (viewModel.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFF7BCEF5),
                          ),
                        ),
                      );
                    }

                    if (viewModel.state == HomeState.error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Text(
                                viewModel.errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => viewModel.fetchWorkOrders(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7BCEF5),
                                ),
                                child: const Text(
                                  "Coba Lagi",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (viewModel.workOrders.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Tidak ada kunjungan\npada tanggal ini",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: viewModel.workOrders
                          .map(
                            (wo) => VisitCard(
                              name: wo.customerName,
                              priority: wo.priority,
                              priorityColor: _getPriorityColor(wo.priority),
                              textColor: _getPriorityTextColor(wo.priority),
                              status: wo.status,
                              timeStart: wo.woTime,
                              timeEnd: wo.estTime,
                              address: wo.address,
                              woDate: wo.woDate,
                              woName: wo.woName,
                              showArrow: true,
                              workOrderId: wo.workOrderId, // ✅ dari WorkOrderModel
                              token: token,                // ✅ dari LoginViewModel
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFFC5C5);
      case 'medium':
        return const Color(0xFFF0E199);
      default:
        return const Color(0xFFD3EAE7);
    }
  }

  Color _getPriorityTextColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'medium':
        return const Color(0xFF8D7701);
      default:
        return const Color(0xFF55938D);
    }
  }
}