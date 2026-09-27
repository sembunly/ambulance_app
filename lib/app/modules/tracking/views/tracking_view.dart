import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/map_route.dart';
import '../../../data/models/tracked_location.dart';
import '../../../theme/app_theme.dart';
import '../controllers/tracking_controller.dart';

// ── Live tracking view ────────────────────────────────────────────────────

class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('liveMapScreen'),
      appBar: AppBar(
        title: const Text(
          'Live Ambulance Tracking',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: context.appColors.surface,
        foregroundColor: context.appColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildMap(context),
      floatingActionButton: Obx(() {
        final patient = controller.patientLocation.value;
        if (patient == null) return const SizedBox.shrink();
        return FloatingActionButton(
          key: const Key('centerMapButton'),
          tooltip: 'Fit ambulance and patient',
          onPressed: controller.fitAllLocations,
          backgroundColor: context.appColors.surface,
          foregroundColor: context.appColors.primary,
          child: const Icon(Icons.my_location_rounded),
        );
      }),
    );
  }

  Widget _buildMap(BuildContext context) {
    return Obx(() {
      final patient = controller.patientLocation.value;
      final ambulance = controller.ambulanceLocation.value;
      final errorMessage = controller.gpsError.value;
      final realtimeStatus = controller.realtimeStatus.value;
      final initialCamera = controller.initialCameraPosition;

      return Stack(
        children: [
          if (initialCamera == null)
            _MapEmptyState(
              isLoading: controller.isGpsLoading,
              errorMessage: errorMessage,
            )
          else
            GoogleMap(
              key: const Key('ambulanceGoogleMap'),
              initialCameraPosition: initialCamera,
              onMapCreated: controller.onMapCreated,
              markers: controller.markers,
              polylines: controller.polylines(context.appColors.primary),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: _MapOverlayStatus(
              children: [
                _LocationStatusCard(
                  isLocating: controller.isGpsLoading,
                  location: patient,
                ),
                _RealtimeStatusCard(
                  status: realtimeStatus,
                  hasAmbulanceLocation: ambulance != null,
                  onRetry: controller.subscribe,
                ),
                _RouteStatusCard(
                  isLoading: controller.isRouteLoading.value,
                  hasAmbulanceLocation: ambulance != null,
                  route: controller.route.value,
                  errorMessage: controller.routeError.value,
                ),
              ],
            ),
          ),
          if (controller.route.value != null &&
              !controller.route.value!.isEmpty &&
              errorMessage == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _EtaPanel(route: controller.route.value!),
            ),
          if (errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _LocationErrorCard(
                message: errorMessage,
                actionLabel: switch (controller.gpsAction.value) {
                  GpsTrackingAction.retry => 'Try again',
                  GpsTrackingAction.locationSettings => 'Open settings',
                  GpsTrackingAction.appSettings => 'App settings',
                },
                onPressed: controller.requestGpsAction,
              ),
            ),
        ],
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Private widgets
// ══════════════════════════════════════════════════════════════════════════

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.isLoading, required this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? 'Waiting for your real GPS location...';
    return ColoredBox(
      color: context.appColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: context.appColors.primary)
              else
                Icon(
                  Icons.location_off_rounded,
                  size: 42,
                  color: context.appColors.textSecondary,
                ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Turn on GPS and allow location permission to load the map.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapOverlayStatus extends StatelessWidget {
  const _MapOverlayStatus({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children) ...[child, const SizedBox(height: 6)],
        ],
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.isLocating, required this.location});

  final bool isLocating;
  final TrackedLocation? location;

  @override
  Widget build(BuildContext context) {
    final accuracy = location?.accuracy.round();
    return _MapStatusCard(
      icon: isLocating
          ? const SizedBox.square(
              dimension: 13,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            )
          : Icon(
              location == null
                  ? Icons.location_off_rounded
                  : Icons.gps_fixed_rounded,
              size: 15,
              color: location == null
                  ? context.appColors.textSecondary
                  : context.appColors.success,
            ),
      message: isLocating
          ? 'Finding your location...'
          : location == null
          ? 'Location unavailable'
          : 'Live location · ±$accuracy m',
    );
  }
}

class _RealtimeStatusCard extends StatelessWidget {
  const _RealtimeStatusCard({
    required this.status,
    required this.hasAmbulanceLocation,
    required this.onRetry,
  });

  final RealtimeEventsStatus status;
  final bool hasAmbulanceLocation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == RealtimeEventsStatus.error) {
      return _MapStatusCard(
        icon: Icon(
          Icons.cloud_off_rounded,
          size: 15,
          color: context.appColors.error,
        ),
        message: 'Realtime disconnected · tap to retry',
        onTap: onRetry,
      );
    }
    if (hasAmbulanceLocation) {
      return _MapStatusCard(
        icon: Icon(
          Icons.local_shipping_rounded,
          size: 15,
          color: context.appColors.primary,
        ),
        message: 'Ambulance location is live',
      );
    }
    if (status == RealtimeEventsStatus.initial ||
        status == RealtimeEventsStatus.loading) {
      return const _MapStatusCard(
        icon: SizedBox.square(
          dimension: 13,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
        message: 'Connecting to ambulance...',
      );
    }
    return _MapStatusCard(
      icon: Icon(
        Icons.local_shipping_outlined,
        size: 15,
        color: context.appColors.textSecondary,
      ),
      message: 'Driver location not available',
    );
  }
}

class _RouteStatusCard extends StatelessWidget {
  const _RouteStatusCard({
    required this.isLoading,
    required this.hasAmbulanceLocation,
    required this.route,
    required this.errorMessage,
  });

  final bool isLoading;
  final bool hasAmbulanceLocation;
  final MapRoute? route;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _MapStatusCard(
        icon: SizedBox.square(
          dimension: 13,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
        message: 'Loading ambulance route...',
      );
    }

    if (errorMessage != null) {
      return _MapStatusCard(
        icon: Icon(
          Icons.route_rounded,
          size: 15,
          color: context.appColors.error,
        ),
        message: errorMessage!,
        maxLines: 2,
      );
    }

    if (route != null && !route!.isEmpty) {
      final details = [
        if (route!.distanceText != null) route!.distanceText,
        if (route!.durationText != null) route!.durationText,
      ].whereType<String>().join(' · ');
      return _MapStatusCard(
        icon: Icon(
          Icons.alt_route_rounded,
          size: 15,
          color: context.appColors.primary,
        ),
        message: details.isEmpty ? 'Route ready' : 'Route · $details',
      );
    }

    if (!hasAmbulanceLocation) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}

class _MapStatusCard extends StatelessWidget {
  const _MapStatusCard({
    required this.icon,
    required this.message,
    this.maxLines = 1,
    this.onTap,
  });

  final Widget icon;
  final String message;
  final int maxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Material(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.appColors.border),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.textPrimary.withValues(alpha: 0.14),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      message,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EtaPanel extends StatelessWidget {
  const _EtaPanel({required this.route});

  final MapRoute route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: context.appColors.primarySoft,
              foregroundColor: context.appColors.primary,
              child: const Icon(Icons.local_shipping_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Ambulance arriving in ${route.durationText ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Distance: ${route.distanceText ?? '—'}',
                    style: TextStyle(color: context.appColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationErrorCard extends StatelessWidget {
  const _LocationErrorCard({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      elevation: 4,
      shadowColor: context.appColors.textPrimary.withValues(alpha: 0.19),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded, color: context.appColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
