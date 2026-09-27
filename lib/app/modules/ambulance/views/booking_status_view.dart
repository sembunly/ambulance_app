import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/ambulance_request_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_pages.dart';
import '../controllers/ambulance_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../widgets/request_ambulance_widgets.dart';

// ── Booking Status Screen ─────────────────────────────────────────────────────
class BookingStatusView extends StatefulWidget {
  const BookingStatusView({
    super.key,
    required this.result,
    required this.draft,
    this.openedFromDashboard = false,
  });

  final AmbulanceBookingResult result;
  final AmbulanceRequestDraft draft;
  final bool openedFromDashboard;

  @override
  State<BookingStatusView> createState() => _BookingStatusViewState();
}

class _BookingStatusViewState extends State<BookingStatusView> {
  late final AmbulanceController _controller = Get.find<AmbulanceController>();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.refreshBookingStatus(widget.result));
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_controller.refreshBookingStatus(widget.result));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = _controller;
      final currentBooking = controller.currentBooking.value;
      final currentStatus = currentBooking?.status ?? widget.result.status;
      final ambulanceFound =
          currentBooking?.canTrackAmbulance ??
          currentStatus.hasAssignedAmbulance;
      return PopScope(
        canPop: widget.openedFromDashboard,
        child: Scaffold(
          key: const Key('bookingStatusScreen'),
          backgroundColor: context.appColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Semantics(
                          key: const Key('requestSuccessAnimation'),
                          image: true,
                          label: 'Request submitted successfully',
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 88,
                            color: context.appColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Booking successful',
                        key: Key('requestSubmittedTitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 18),
                      Semantics(
                        key: Key(
                          ambulanceFound
                              ? 'ambulanceFoundAnimation'
                              : 'findingAmbulanceAnimation',
                        ),
                        image: ambulanceFound,
                        label: ambulanceFound
                            ? 'Ambulance found'
                            : 'Finding an ambulance',
                        child: SizedBox.square(
                          dimension: 142,
                          child: Center(
                            child: ambulanceFound
                                ? Icon(
                                    Icons.emergency_rounded,
                                    size: 82,
                                    color: context.appColors.primary,
                                  )
                                : SizedBox.square(
                                    dimension: 62,
                                    child: CircularProgressIndicator(
                                      color: context.appColors.primary,
                                      strokeWidth: 5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ambulanceFound
                            ? 'Ambulance found'
                            : 'Waiting for ambulance/driver',
                        key: const Key('searchingForAmbulanceText'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ambulanceFound
                            ? 'Your ambulance has been assigned. Live tracking is now available.'
                            : 'Live tracking will become available after an ambulance or driver is assigned.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SummarySection(
                        title: 'Booking status',
                        children: <Widget>[
                          SummaryRow(
                            label: 'Booking ID',
                            value: widget.result.id,
                          ),
                          SummaryRow(
                            label: 'Booking code',
                            value: widget.result.code,
                          ),
                          SummaryRow(
                            label: 'Status',
                            value: currentStatus.displayBookingStatus,
                          ),
                          SummaryRow(
                            label: 'Hospital',
                            value: widget.draft.hospital?.displayName ?? '',
                          ),
                          SummaryRow(
                            label: 'Pickup',
                            value: widget.draft.locationAddress,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (_canCancel(currentStatus)) ...<Widget>[
                        OutlinedButton.icon(
                          key: const Key('cancelAmbulanceBookingButton'),
                          onPressed: controller.isCancellingBooking.value
                              ? null
                              : () => _cancelBooking(context, controller),
                          icon: controller.isCancellingBooking.value == true
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined),
                          label: Text(
                            controller.isCancellingBooking.value == true
                                ? 'Cancelling…'
                                : 'Cancel Booking',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.appColors.error,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (ambulanceFound) ...<Widget>[
                        FilledButton.icon(
                          key: const Key('trackAmbulanceButton'),
                          onPressed: () => Get.toNamed(Routes.tracking),
                          icon: const Icon(Icons.location_searching_rounded),
                          label: const Text('Track Ambulance'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      FilledButton(
                        key: const Key('returnToDashboardButton'),
                        onPressed: () => _close(context),
                        child: Text(
                          widget.openedFromDashboard
                              ? 'Back to Dashboard'
                              : 'Dashboard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _canCancel(String status) {
    return !const <String>{
      'cancelled',
      'canceled',
      'completed',
      'rejected',
      'closed',
      'failed',
    }.contains(status.normalizedBookingStatus);
  }

  Future<void> _cancelBooking(
    BuildContext context,
    AmbulanceController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('The ambulance request will be cancelled.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cancelled = await controller.cancelBooking(widget.result.id);
    if (!context.mounted) return;
    if (cancelled) {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().loadBookings();
      }
      if (!context.mounted) return;
      _close(context);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            controller.actionError.value ?? 'Unable to cancel this booking.',
          ),
        ),
      );
  }

  void _close(BuildContext context) {
    if (widget.openedFromDashboard) {
      Get.back<void>();
      return;
    }
    Get.offAllNamed(Routes.dashboard);
  }
}
