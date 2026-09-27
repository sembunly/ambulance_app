import 'package:equatable/equatable.dart';
import 'hospital_model.dart';

class AmbulanceBookingResult {
  const AmbulanceBookingResult({
    required this.id,
    required this.code,
    required this.status,
  });

  final String id;
  final String code;
  final String status;
}

extension AmbulanceBookingStatus on String {
  String get normalizedBookingStatus =>
      trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

  bool get hasAssignedAmbulance => const <String>{
    'assigned',
    'accepted',
    'dispatched',
    'en_route',
    'arriving',
    'arrived',
    'picked_up',
    'in_progress',
  }.contains(normalizedBookingStatus);

  String get displayBookingStatus {
    final words = trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty);
    if (words.isEmpty) return 'Submitted';
    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

// ── Ambulance Request For ─────────────────────────────────────────────────────
enum AmbulanceRequestFor { myself, someoneElse }

// ── Ambulance Request For Label ───────────────────────────────────────────────
extension AmbulanceRequestForLabel on AmbulanceRequestFor {
  String get label => switch (this) {
    AmbulanceRequestFor.myself => 'For myself',
    AmbulanceRequestFor.someoneElse => 'Someone else',
  };
}

enum ReportedGender { male, female, other }

extension ReportedGenderValue on ReportedGender {
  String get label => switch (this) {
    ReportedGender.male => 'Male',
    ReportedGender.female => 'Female',
    ReportedGender.other => 'Other',
  };

  String get apiValue => name.toUpperCase();
}

/// The complete client-side booking state collected before submission.
class AmbulanceRequestDraft extends Equatable {
  const AmbulanceRequestDraft({
    this.requestFor = AmbulanceRequestFor.myself,
    this.patientId = '',
    this.patientName = '',
    this.patientAge,
    this.patientGender = '',
    this.hospital,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationName = '',
    this.locationAddress = '',
    this.landmark = '',
    this.typeCode = '',
    this.priorityCode = '',
    this.numberOfPatients = 1,
    this.chiefComplaint = '',
    this.symptoms = '',
    this.incidentDescription = '',
    this.note = '',
  });

  final AmbulanceRequestFor requestFor;
  final String patientId;
  final String patientName;
  final int? patientAge;
  final String patientGender;
  final HospitalModel? hospital;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final String locationName;
  final String locationAddress;
  final String landmark;
  final String typeCode;
  final String priorityCode;
  final int numberOfPatients;
  final String chiefComplaint;
  final String symptoms;
  final String incidentDescription;
  final String note;

  // ── Copy With ─────────────────────────────────────────────────────────
  AmbulanceRequestDraft copyWith({
    AmbulanceRequestFor? requestFor,
    String? patientId,
    String? patientName,
    int? patientAge,
    bool clearPatientAge = false,
    String? patientGender,
    HospitalModel? hospital,
    bool clearHospital = false,
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
    String? locationName,
    String? locationAddress,
    String? landmark,
    String? typeCode,
    String? priorityCode,
    int? numberOfPatients,
    String? chiefComplaint,
    String? symptoms,
    String? incidentDescription,
    String? note,
  }) {
    return AmbulanceRequestDraft(
      requestFor: requestFor ?? this.requestFor,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: clearPatientAge ? null : patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      hospital: clearHospital ? null : hospital ?? this.hospital,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracyMeters:
          locationAccuracyMeters ?? this.locationAccuracyMeters,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      landmark: landmark ?? this.landmark,
      typeCode: typeCode ?? this.typeCode,
      priorityCode: priorityCode ?? this.priorityCode,
      numberOfPatients: numberOfPatients ?? this.numberOfPatients,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      symptoms: symptoms ?? this.symptoms,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      note: note ?? this.note,
    );
  }

  // ── Properties ─────────────────────────────────────────────────────────
  @override
  List<Object?> get props => <Object?>[
    requestFor,
    patientId,
    patientName,
    patientAge,
    patientGender,
    hospital,
    latitude,
    longitude,
    locationAccuracyMeters,
    locationName,
    locationAddress,
    landmark,
    typeCode,
    priorityCode,
    numberOfPatients,
    chiefComplaint,
    symptoms,
    incidentDescription,
    note,
  ];
}
