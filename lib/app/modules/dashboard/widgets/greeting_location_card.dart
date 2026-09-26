import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ambulance_app/app/language/app_translations.dart';

import 'package:ambulance_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:ambulance_app/app/theme/app_theme.dart';

class GreetingLocationCard extends StatelessWidget {
  const GreetingLocationCard({
    super.key,
    required this.greeting,
    required this.userName,
    required this.locationStatus,
    required this.locationLabel,
    required this.locationError,
    required this.onLocationAction,
    required this.onProfile,
  });

  final String greeting;
  final String userName;
  final DashboardLocationStatus locationStatus;
  final String locationLabel;
  final String? locationError;
  final VoidCallback onLocationAction;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final locationMessage = switch (locationStatus) {
      DashboardLocationStatus.initial ||
      DashboardLocationStatus.loading => 'FINDING_LOCATION'.tr,
      DashboardLocationStatus.success => locationLabel,
      DashboardLocationStatus.gpsDisabled => 'GPS_OFF'.tr,
      DashboardLocationStatus.permissionDenied => 'LOCATION_DENIED'.tr,
      DashboardLocationStatus.permissionDeniedForever => 'ALLOW_LOCATION'.tr,
      DashboardLocationStatus.empty => 'LOCATION_UNAVAILABLE'.tr,
      DashboardLocationStatus.error => locationError ?? 'LOCATION_ERROR'.tr,
    };
    final actionLabel = switch (locationStatus) {
      DashboardLocationStatus.gpsDisabled => 'TURN_ON'.tr,
      DashboardLocationStatus.permissionDeniedForever => 'SETTINGS'.tr,
      DashboardLocationStatus.permissionDenied ||
      DashboardLocationStatus.empty ||
      DashboardLocationStatus.error => 'RETRY'.tr,
      _ => null,
    };

    return Row(
      key: const Key('dashboardGreetingCard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.trim().isEmpty
                    ? AppTranslations.displayValue(greeting)
                    : 'GREETING_NAME'.trParams({
                        'greeting': AppTranslations.displayValue(greeting),
                        'name': userName,
                      }),
                key: const Key('dashboardUserName'),
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (locationStatus == DashboardLocationStatus.loading)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: context.appColors.textSecondary,
                    ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      locationMessage,
                      key: const Key('dashboardLocation'),
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onLocationAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          key: const Key('dashboardProfileButton'),
          tooltip: 'PROFILE'.tr,
          onPressed: onProfile,
          icon: const Icon(Icons.person_outline_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0F2F5),
            foregroundColor: context.appColors.textSecondary,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }
}
