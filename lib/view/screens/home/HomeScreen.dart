import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:siram/view/navigation/NavigationBottom.dart';
import 'package:siram/view/screens/profile/ProfileScreen.dart';
import 'package:siram/view/widgets/CalendarWidget.dart';
import 'package:siram/view/widgets/FilterWidget.dart';
import 'package:siram/view/widgets/HeaderWidget.dart';
import 'package:siram/view/widgets/VisitCardWidget.dart';
import 'package:siram/viewmodel/HomeViewModel.dart';
import 'package:siram/viewmodel/LoginViewModel.dart';

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

  void _openFilter(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    final fmt = DateFormat('dd-MM-yyyy');
    final today = fmt.format(vm.selectedDate);

    FilterBottomSheet.show(
      context,
      initialParams:
          vm.activeFilter ?? FilterParams(fromDate: today, toDate: today),
      onApply: (params) => vm.applyFilter(params),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String token =
        context.read<LoginViewModel>().currentUser?.token ?? '';

    return Stack(
      children: [
        // ── Background header biru ──────────────────────────────────────────
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
                const SizedBox(height: 8),

                // ── "Daftar Kunjungan" + tombol Filter ─────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        "Daftar Kunjungan",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // ── Tombol Filter ──────────────────────────────────
                      Consumer<HomeViewModel>(
                        builder: (_, vm, __) => GestureDetector(
                          onTap: () => _openFilter(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: vm.isFiltered
                                  ? const Color(0xFF7BCEF5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7BCEF5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7BCEF5,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: vm.isFiltered
                                      ? Colors.white
                                      : const Color(0xFF7BCEF5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: vm.isFiltered
                                        ? Colors.white
                                        : const Color(0xFF7BCEF5),
                                  ),
                                ),
                                // Badge count jika filter aktif
                                if (vm.isFiltered) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _countActiveFilters(vm.activeFilter!),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7BCEF5),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Active filter indicator ─────────────────────────────────
                Consumer<HomeViewModel>(
                  builder: (_, vm, __) {
                    if (!vm.isFiltered) return const SizedBox.shrink();
                    return _buildActiveFilterBanner(context, vm);
                  },
                ),

                // ── Work Order List ─────────────────────────────────────────
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
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
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
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                viewModel.isFiltered
                                    ? "Tidak ada hasil\nyang sesuai filter"
                                    : "Tidak ada kunjungan\npada tanggal ini",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (viewModel.isFiltered) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => viewModel.clearFilter(),
                                  child: const Text(
                                    'Hapus Filter',
                                    style: TextStyle(
                                      color: Color(0xFF7BCEF5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                              workOrderId: wo.workOrderId,
                              token: token,
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

  // ── Active filter banner ──────────────────────────────────────────────────
  Widget _buildActiveFilterBanner(BuildContext context, HomeViewModel vm) {
    final filter = vm.activeFilter!;
    final chips = <String>[];
    if (filter.status != 'All') chips.add(filter.status);
    if (filter.district != 'All') chips.add(filter.district);
    if (filter.search.isNotEmpty) chips.add('"${filter.search}"');
    if (filter.fromDate != filter.toDate) {
      chips.add('${filter.fromDate} → ${filter.toDate}');
    } else {
      chips.add(filter.fromDate);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7BCEF5).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Color(0xFF7BCEF5)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: chips
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7BCEF5).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1A6B8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => vm.clearFilter(),
            child: const Icon(Icons.close, size: 16, color: Color(0xFF7BCEF5)),
          ),
        ],
      ),
    );
  }

  String _countActiveFilters(FilterParams f) {
    int count = 0;
    if (f.status != 'All') count++;
    if (f.district != 'All') count++;
    if (f.search.isNotEmpty) count++;
    if (f.fromDate != f.toDate) count++;
    return count.toString();
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
