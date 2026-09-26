import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ambulance_app/app/language/app_translations.dart';

import 'package:ambulance_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:ambulance_app/app/theme/app_theme.dart';
import 'package:ambulance_app/app/data/models/dashboard_model.dart';

class ActiveBookingCard extends StatelessWidget {
  const ActiveBookingCard({
    super.key,
    required this.status,
    required this.booking,
    required this.errorMessage,
    required this.onRetry,
    this.onView,
    required this.onTrack,
  });

  final DashboardLoadStatus status;
  final DashboardBooking? booking;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback? onView;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    if (status == DashboardLoadStatus.initial ||
        status == DashboardLoadStatus.loading) {
      return DashboardStateCard(
        key: Key('activeBookingLoading'),
        icon: Icons.sync_rounded,
        title: 'ACTIVE_LOADING'.tr,
        loading: true,
      );
    }

    if (status == DashboardLoadStatus.error) {
      return DashboardStateCard(
        key: const Key('activeBookingError'),
        icon: Icons.cloud_off_rounded,
        title: 'ACTIVE_ERROR'.tr,
        message: errorMessage,
        actionLabel: 'RETRY'.tr,
        onAction: onRetry,
      );
    }

    if (booking == null) {
      return DashboardStateCard(
        key: Key('activeBookingEmpty'),
        icon: Icons.event_available_rounded,
        title: 'NO_ACTIVE'.tr,
        message: 'NEXT_REQUEST'.tr,
      );
    }

    return Container(
      key: const Key('activeBookingCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    AppTranslations.displayValue(booking!.displayStatus),
                    style: TextStyle(
                      color: context.appColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTranslations.displayValue(booking!.etaLabel),
                  key: const Key('activeBookingEta'),
                  semanticsLabel: 'ETA_LABEL'.trParams({
                    'eta': AppTranslations.displayValue(booking!.etaLabel),
                  }),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: context.appColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            booking!.canTrackAmbulance
                ? 'Ambulance assigned'
                : 'Waiting for ambulance/driver',
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            booking!.canTrackAmbulance
                ? 'Live tracking is available.'
                : 'Tracking will appear after a driver is assigned.',
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BOOKING_REFERENCE'.trParams({
              'code': booking!.code.isEmpty ? booking!.id : booking!.code,
            }),
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  key: const Key('viewActiveBookingButton'),
                  onPressed: onView,
                  child: const Text('View Booking'),
                ),
              ),
              if (booking!.canTrackAmbulance && onTrack != null) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('trackAmbulanceButton'),
                    onPressed: onTrack,
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      size: 19,
                    ),
                    label: Text('TRACK_AMBULANCE'.tr),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardStateCard extends StatelessWidget {
  const DashboardStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.surface2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: context.appColors.primary,
                    ),
                  )
                : Icon(icon, color: context.appColors.textSecondary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
