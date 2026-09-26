import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ambulance_app/app/theme/app_theme.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({
    super.key,
    required this.onActiveBooking,
    required this.onNearbyHospitals,
    required this.onEmergencyHotline,
    required this.onBookingHistory,
  });

  final VoidCallback onActiveBooking;
  final VoidCallback onNearbyHospitals;
  final VoidCallback onEmergencyHotline;
  final VoidCallback onBookingHistory;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem(
        Icons.emergency_share_outlined,
        'ACTIVE_BOOKING'.tr,
        'CURRENT_REQUEST'.tr,
        context.appColors.primary,
        onActiveBooking,
      ),
      _QuickItem(
        Icons.local_hospital_outlined,
        'NEARBY_HOSPITALS'.tr,
        'CARE_NEAR_YOU'.tr,
        const Color(0xFF388E3C),
        onNearbyHospitals,
      ),
      _QuickItem(
        Icons.phone_in_talk_outlined,
        'EMERGENCY_HOTLINE'.tr,
        'CALL_FOR_HELP'.tr,
        const Color(0xFFE99819),
        onEmergencyHotline,
      ),
      _QuickItem(
        Icons.history_rounded,
        'BOOKING_HISTORY'.tr,
        'PAST_REQUESTS'.tr,
        const Color(0xFFD92D2D),
        onBookingHistory,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final minWidth = 82.0 * scale.clamp(1.0, 2.0);
        final width = (constraints.maxWidth / 4).clamp(
          minWidth,
          double.infinity,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => SizedBox(width: width, child: _QuickCard(item)))
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _QuickItem {
  const _QuickItem(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  );

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _QuickCard extends StatelessWidget {
  const _QuickCard(this.item);

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 27),
                ),
                const SizedBox(height: 9),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
