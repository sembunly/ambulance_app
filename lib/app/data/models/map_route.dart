import 'package:equatable/equatable.dart';

import 'tracked_location.dart';

// ── Map route ─────────────────────────────────────────────────────────────

class MapRoute extends Equatable {
  const MapRoute({required this.points, this.distanceText, this.durationText});

  final List<TrackedLocation> points;
  final String? distanceText;
  final String? durationText;

  bool get isEmpty => points.isEmpty;

  @override
  List<Object?> get props => [points, distanceText, durationText];
}
