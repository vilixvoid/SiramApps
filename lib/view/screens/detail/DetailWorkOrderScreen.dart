import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/datasources/remote/DetailWorkOrderRemoteDatasource.dart';
import 'package:siram/data/models/DetailWorkOrderModel.dart';
import 'package:siram/data/repositories/DetailWorkOrderRepository.dart';
import 'package:siram/view/widgets/PhotoCarouselCardWidget.dart';
import 'package:siram/view/widgets/SurveyPhotoCardWidget.dart';
import 'package:siram/viewmodel/DetailWorkOrderViewModel.dart';

class DetailWorkOrderScreen extends StatelessWidget {
  final int workOrderId;
  final String token;

  const DetailWorkOrderScreen({
    super.key,
    required this.workOrderId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = DetailWorkOrderViewModel(
          repository: DetailWorkOrderRepository(
            DetailWorkOrderRemoteDatasource(ApiService()),
          ),
          workOrderId: workOrderId,
          token: token,
        );
        vm.fetchDetail();
        return vm;
      },
      child: const _DetailWorkOrderView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────
class _DetailWorkOrderView extends StatelessWidget {
  const _DetailWorkOrderView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetailWorkOrderViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () => vm.fetchDetail(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7BCEF5)),
            )
          : vm.state == DetailState.error
          ? _ErrorState(message: vm.errorMessage, onRetry: vm.fetchDetail)
          : const _DetailBody(),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BCEF5),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Body ──────────────────────────────────────────────────────────────
class _DetailBody extends StatefulWidget {
  const _DetailBody();

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _commentCtrl = TextEditingController();
  bool _notesInitialized = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF27AE60) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleCheckinCheckout(DetailWorkOrderViewModel vm) async {
    final msg = await vm.handleCheckinCheckout();
    if (msg != null && mounted)
      _showSnack(msg, success: true);
    else if (msg == null && mounted)
      _showSnack('Gagal, coba lagi');
  }

  Future<void> _openWhatsApp(String phone) async {
    String n = phone.replaceAll(RegExp(r'\D'), '');
    if (n.startsWith('0')) n = '62${n.substring(1)}';
    final url = Uri.parse('https://wa.me/$n');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetailWorkOrderViewModel>();
    final detail = vm.detail!;
    final wo = detail.workOrder;
    final customer = detail.customer;
    final address = detail.customerAddress;

    // Init notes once
    if (!_notesInitialized) {
      _notesCtrl.text = wo.notesTechnician;
      _notesInitialized = true;
    }

    final sourceList = detail.items.isNotEmpty ? detail.items : detail.products;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Map placeholder ──────────────────────────────────────────────
          _MapPlaceholder(),
          const SizedBox(height: 12),

          // ── Lokasi ───────────────────────────────────────────────────────
          _WoCard(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF7BCEF5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Tugas',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Clock In / Out ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ClockCard(
                    label: 'CLOCK IN',
                    time: wo.hasCheckin ? _fmtTime(wo.checkin!) : '-',
                    statusText: wo.status,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ClockCard(
                    label: 'CLOCK OUT',
                    time: wo.hasCheckout ? _fmtTime(wo.checkout!) : '-',
                    statusText: 'Status: OK',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Customer ──────────────────────────────────────────────────────
          _CustomerCard(
            customer: customer,
            wo: wo,
            quotation: detail.quotation,
            onWhatsApp: _openWhatsApp,
          ),
          const SizedBox(height: 8),

          // ── Priority ──────────────────────────────────────────────────────
          _WoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioritas Tugas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _PrioritySelector(current: wo.priority),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aktivitas Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── WO List ───────────────────────────────────────────────────────
          _WoListCard(woName: wo.woName, items: sourceList),
          const SizedBox(height: 8),

          // ── Photo Before ──────────────────────────────────────────────────
          const PhotoCarouselCard(
            title: 'Photo Before',
            icon: Icons.camera_alt_outlined,
            type: 'before',
          ),
          const SizedBox(height: 8),

          // ── Photo After ───────────────────────────────────────────────────
          const PhotoCarouselCard(
            title: 'Photo After',
            icon: Icons.add_photo_alternate_outlined,
            type: 'after',
          ),
          const SizedBox(height: 8),

          // ── Survey Photo (hanya tampil sebelum checkout) ──────────────────
          if (!wo.hasCheckout) ...[
            const SurveyPhotoCard(),
            const SizedBox(height: 8),
          ],

          // ── Catatan Teknisi ───────────────────────────────────────────────
          _WoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  icon: Icons.description_outlined,
                  title: 'Catatan Teknisi',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan detail pekerjaan...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: vm.isSavingNotes
                        ? null
                        : () async {
                            final ok = await vm.saveNotes(_notesCtrl.text);
                            if (mounted) {
                              _showSnack(
                                ok
                                    ? 'Catatan berhasil disimpan!'
                                    : 'Gagal simpan catatan',
                                success: ok,
                              );
                            }
                          },
                    icon: vm.isSavingNotes
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                    label: Text(
                      vm.isSavingNotes ? 'Menyimpan...' : 'Simpan Catatan',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BCEF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Comment ───────────────────────────────────────────────────────
          _CommentCard(comments: detail.comments, commentCtrl: _commentCtrl),
          const SizedBox(height: 8),

          // ── Checklist ─────────────────────────────────────────────────────
          _ChecklistCard(vm: vm),
          const SizedBox(height: 8),

          // ── Status Unit ───────────────────────────────────────────────────
          _StatusUnitCard(vm: vm),
          const SizedBox(height: 24),

          // ── Main Button ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (vm.isSubmitting || wo.hasCheckout)
                    ? null
                    : () => _handleCheckinCheckout(vm),
                icon: vm.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        wo.hasCheckout
                            ? Icons.check_circle
                            : wo.hasCheckin
                            ? Icons.logout
                            : Icons.login,
                        color: Colors.white,
                      ),
                label: Text(
                  vm.isSubmitting
                      ? 'Memproses...'
                      : wo.hasCheckout
                      ? 'Tugas Selesai ✓'
                      : wo.hasCheckin
                      ? 'Selesaikan Tugas (Checkout)'
                      : 'Tiba di Lokasi (Check-in)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wo.hasCheckout
                      ? Colors.grey.shade400
                      : wo.hasCheckin
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF7BCEF5),
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  String _fmtTime(String dt) {
    try {
      final d = DateTime.parse(dt);
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      return '${h.toString().padLeft(2, '0')}:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '-';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (private, only used inside this file)
// ══════════════════════════════════════════════════════════════════════════════

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD6EAF8), Color(0xFFEBF5FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: Colors.blueGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Maps',
              style: TextStyle(
                color: Colors.blueGrey.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WoCard extends StatelessWidget {
  final Widget child;
  const _WoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7BCEF5), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

class _ClockCard extends StatelessWidget {
  final String label;
  final String time;
  final String statusText;
  const _ClockCard({
    required this.label,
    required this.time,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerDetail customer;
  final WorkOrderDetail wo;
  final QuotationDetail? quotation;
  final Future<void> Function(String) onWhatsApp;

  const _CustomerCard({
    required this.customer,
    required this.wo,
    required this.quotation,
    required this.onWhatsApp,
  });

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7BCEF5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF7BCEF5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NAMA PELANGGAN',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      customer.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(
                Icons.category_outlined,
                quotation?.purchasingType ?? wo.woType,
              ),
              _chip(Icons.calendar_today, wo.woDate),
              _chip(Icons.access_time, wo.woTime),
              _chip(Icons.timer_outlined, wo.estTime),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Color(0xFF7BCEF5)),
              const SizedBox(width: 6),
              Text(
                customer.cpPhone,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const Spacer(),
              if (customer.cpPhone.isNotEmpty)
                GestureDetector(
                  onTap: () => onWhatsApp(customer.cpPhone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (wo.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Color(0xFFF9A825),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      wo.notes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String current;
  const _PrioritySelector({required this.current});

  @override
  Widget build(BuildContext context) {
    final opts = ['Low', 'Medium', 'High'];
    return Row(
      children: opts.map((p) {
        final sel = p.toLowerCase() == current.toLowerCase();
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p != 'High' ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF1A3A6B) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              p,
              style: TextStyle(
                color: sel ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WoListCard extends StatelessWidget {
  final String woName;
  final List<ProductItem> items;
  const _WoListCard({required this.woName, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.list_alt, title: 'Work Order List'),
          const SizedBox(height: 12),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Kode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Nama Material',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'Cek',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Scrollable rows: tampil penuh ≤10 item, scroll jika lebih ──
          Builder(
            builder: (context) {
              const double rowHeight = 36.0;
              const int maxVisible = 10;
              final bool needsScroll = items.length > maxVisible;
              final double listHeight =
                  rowHeight *
                  (needsScroll ? maxVisible : items.length).toDouble();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: listHeight,
                    child: ListView.builder(
                      physics: needsScroll
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final p = items[i];
                        return Container(
                          height: rowHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: i % 2 == 0
                                ? Colors.white
                                : const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  p.materialCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  p.materialDesc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  p.qty,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: p.stockCheck == 'y'
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF27AE60),
                                          size: 16,
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Info baris + hint scroll
                  const SizedBox(height: 6),
                  if (needsScroll)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.swipe_vertical,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${items.length} item · geser untuk lihat semua',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${items.length} item',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final List<CommentItem> comments;
  final TextEditingController commentCtrl;
  const _CommentCard({required this.comments, required this.commentCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.chat_bubble_outline,
            title: 'Comment',
          ),
          const SizedBox(height: 10),
          if (comments.isNotEmpty) ...[
            ...comments.map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.createdBy,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(c.comment, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const Divider(),
          ],
          TextField(
            controller: commentCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Tulis komentar singkat',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final DetailWorkOrderViewModel vm;
  const _ChecklistCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.checklist, title: 'Checklist'),
          const SizedBox(height: 8),
          _item(
            'Area kerja dibersihkan',
            vm.checkAreaDibersihkan,
            (v) => vm.toggleChecklist('area', v ?? false),
          ),
          _item(
            'Tanda tangan pelanggan',
            vm.checkTandaTangan,
            (v) => vm.toggleChecklist('ttd', v ?? false),
          ),
          _item(
            'Penutupan tiket di sistem',
            vm.checkPenutupanTiket,
            (v) => vm.toggleChecklist('tutup', v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _item(String text, bool val, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: val,
      onChanged: onChanged,
      title: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black87,
          decoration: val ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF7BCEF5),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _StatusUnitCard extends StatelessWidget {
  final DetailWorkOrderViewModel vm;
  const _StatusUnitCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.engineering_outlined,
            title: 'Status Unit Setelah Pengerjaan',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _btn(true, vm)),
              const SizedBox(width: 12),
              Expanded(child: _btn(false, vm)),
            ],
          ),
          if (vm.statusUnitBaik != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: vm.statusUnitBaik!
                    ? const Color(0xFFE8F8F0)
                    : const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    vm.statusUnitBaik!
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: vm.statusUnitBaik!
                        ? const Color(0xFF27AE60)
                        : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vm.statusUnitBaik!
                        ? 'Unit berfungsi dengan baik'
                        : 'Unit memerlukan perhatian lebih lanjut',
                    style: TextStyle(
                      fontSize: 12,
                      color: vm.statusUnitBaik!
                          ? const Color(0xFF27AE60)
                          : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn(bool baik, DetailWorkOrderViewModel vm) {
    final sel = vm.statusUnitBaik == baik;
    final color = baik ? const Color(0xFF27AE60) : Colors.redAccent;
    return GestureDetector(
      onTap: () => vm.setStatusUnit(baik),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? color : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              baik ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: sel ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              baik ? 'Baik' : 'Tidak Baik',
              style: TextStyle(
                color: sel ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
