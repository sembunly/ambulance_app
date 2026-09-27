import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/ambulance_request_model.dart';
import '../../ambulance/bindings/ambulance_binding.dart';
import '../../ambulance/views/booking_status_view.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/active_booking_card.dart';
import '../widgets/greeting_location_card.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/recent_booking_card.dart';
import '../widgets/request_ambulance_button.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _activeBookingKey = GlobalKey();
  late final DashboardController controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboardScreen'),
      backgroundColor: context.appColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Obx(() {
              final status = controller.bookingStatus.value;
              final locationStatus = controller.locationStatus.value;
              final active = controller.activeBooking;
              return RefreshIndicator(
                onRefresh: controller.refreshDashboard,
                child: SingleChildScrollView(
                  key: const Key('dashboardScrollView'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GreetingLocationCard(
                        onProfile: () => Get.toNamed(Routes.profile),
                        greeting: controller.greeting,
                        userName: controller.userName.value,
                        locationStatus: locationStatus,
                        locationLabel: controller.locationLabel,
                        locationError: controller.locationError.value,
                        onLocationAction: controller.handleLocationAction,
                      ),
                      const SizedBox(height: 24),
                      RequestAmbulanceButton(
                        onPressed: () => Get.toNamed(Routes.ambulance),
                      ),
                      const SizedBox(height: 18),
                      KeyedSubtree(
                        key: _activeBookingKey,
                        child: ActiveBookingCard(
                          status: status,
                          booking: active,
                          errorMessage: controller.bookingError.value,
                          onRetry: controller.loadBookings,
                          onView: active == null
                              ? null
                              : () => Get.to<void>(
                                  () => BookingStatusView(
                                    result: AmbulanceBookingResult(
                                      id: active.id,
                                      code: active.code,
                                      status: active.status,
                                    ),
                                    draft: AmbulanceRequestDraft(
                                      locationAddress: active.pickupAddress,
                                    ),
                                    openedFromDashboard: true,
                                  ),
                                  binding: AmbulanceBinding(),
                                ),
                          onTrack: active?.canTrackAmbulance == true
                              ? () => Get.toNamed(Routes.tracking)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SectionTitle('QUICK_ACCESS'.tr),
                      const SizedBox(height: 10),
                      QuickAccessSection(
                        onActiveBooking: _scrollToActiveBooking,
                        onNearbyHospitals: () => Get.toNamed(Routes.hospitals),
                        onEmergencyHotline: _openEmergencyHotline,
                        onBookingHistory: _showBookingHistory,
                      ),
                      const SizedBox(height: 23),
                      _SectionTitle(
                        'RECENT_BOOKINGS'.tr,
                        actionLabel: 'VIEW_ALL'.tr,
                        onAction: _showBookingHistory,
                      ),
                      const SizedBox(height: 8),
                      RecentBookings(
                        status: status,
                        bookings: controller.recentBookings,
                        errorMessage: controller.bookingError.value,
                        onRetry: controller.loadBookings,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.appColors.primary,
        unselectedItemColor: context.appColors.textMuted,
        backgroundColor: context.appColors.surface,
        onTap: (index) {
          switch (index) {
            case 1:
              Get.toNamed(Routes.notifications);
            case 2:
              Get.toNamed(Routes.profile);
            case 3:
              Get.toNamed(Routes.settings);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'HOME'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_outlined),
            label: 'NOTIFICATIONS'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: 'YOU'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: 'SETTINGS'.tr,
          ),
        ],
      ),
    );
  }

  void _scrollToActiveBooking() {
    final cardContext = _activeBookingKey.currentContext;
    if (cardContext == null) return;
    Scrollable.ensureVisible(
      cardContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  Future<void> _openEmergencyHotline() async {
    final opened = await controller.openEmergencyHotline();
    if (!mounted || opened) return;
    _showMessage(controller.actionError.value ?? 'PHONE_ERROR'.tr);
  }

  void _showBookingHistory() {
    final history = controller.bookingHistory;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BOOKING_HISTORY'.tr,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 42,
                          color: sheetContext.appColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text('NO_HISTORY'.tr),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          RecentBookingCard(booking: history[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
