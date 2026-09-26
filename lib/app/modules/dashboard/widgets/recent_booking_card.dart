import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ambulance_app/app/language/app_translations.dart';

import 'package:ambulance_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:ambulance_app/app/theme/app_theme.dart';
import 'package:ambulance_app/app/data/models/dashboard_model.dart';
import 'active_booking_card.dart';

class RecentBookings extends StatelessWidget {
  const RecentBookings({
    super.key,
    required this.status,
    required this.bookings,
    required this.errorMessage,
    required this.onRetry,
  });

  final DashboardLoadStatus status;
  final List<DashboardBooking> bookings;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == DashboardLoadStatus.initial ||
        status == DashboardLoadStatus.loading) {
      return DashboardStateCard(
        key: Key('recentBookingsLoading'),
        icon: Icons.sync_rounded,
        title: 'RECENT_LOADING'.tr,
        loading: true,
      );
    }
    if (status == DashboardLoadStatus.error) {
      return DashboardStateCard(
        key: const Key('recentBookingsError'),
        icon: Icons.cloud_off_rounded,
        title: 'HISTORY_ERROR'.tr,
        message: errorMessage,
        actionLabel: 'RETRY'.tr,
        onAction: onRetry,
      );
    }
    if (bookings.isEmpty) {
      return DashboardStateCard(
        key: Key('recentBookingsEmpty'),
        icon: Icons.history_rounded,
        title: 'NO_RECENT'.tr,
        message: 'COMPLETED_BOOKINGS_HINT'.tr,
      );
    }
    return Column(
      children: bookings
          .map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecentBookingCard(booking: booking),
            ),
          )
          .toList(growable: false),
    );
  }
}

class RecentBookingCard extends StatelessWidget {
  const RecentBookingCard({super.key, required this.booking});

  final DashboardBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.surface2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: context.appColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.code.isEmpty ? booking.id : booking.code,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(booking.requestedAt),
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppTranslations.displayValue(booking.displayStatus),
            style: TextStyle(
              color: booking.status.toLowerCase() == 'completed'
                  ? context.appColors.success
                  : context.appColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'DATE_UNAVAILABLE'.tr;
    final months = <String>[
      'MONTH_1'.tr,
      'MONTH_2'.tr,
      'MONTH_3'.tr,
      'MONTH_4'.tr,
      'MONTH_5'.tr,
      'MONTH_6'.tr,
      'MONTH_7'.tr,
      'MONTH_8'.tr,
      'MONTH_9'.tr,
      'MONTH_10'.tr,
      'MONTH_11'.tr,
      'MONTH_12'.tr,
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
