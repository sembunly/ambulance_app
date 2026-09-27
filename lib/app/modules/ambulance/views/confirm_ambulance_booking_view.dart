import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/ambulance_request_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/ambulance_controller.dart';
import '../bindings/ambulance_binding.dart';
import '../widgets/request_ambulance_widgets.dart';
import 'booking_status_view.dart';

// ── Confirm Ambulance Booking Screen ─────────────────────────────────────────
class ConfirmAmbulanceBookingView extends StatelessWidget {
  const ConfirmAmbulanceBookingView({super.key, required this.controller});

  final AmbulanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = controller.draft.value;
      final submitting = controller.isSubmitting;
      return PopScope(
        canPop: !submitting,
        child: Scaffold(
          key: const Key('confirmAmbulanceBookingScreen'),
          backgroundColor: context.appColors.background,
          appBar: RequestAmbulanceHeader(
            title: 'Review Booking',
            onBack: submitting ? () {} : () => Get.back<void>(),
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('bookingSummaryScrollView'),
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const AmbulanceRequestStepIndicator(
                              currentStep: 5,
                              totalSteps: 5,
                              label: 'Review',
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Check every detail',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your booking will be sent after you confirm.',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _patientSummary(draft),
                            const SizedBox(height: 12),
                            _hospitalSummary(draft),
                            const SizedBox(height: 12),
                            _pickupSummary(draft),
                            const SizedBox(height: 12),
                            _emergencySummary(draft),
                            if (controller.errorMessage.value !=
                                null) ...<Widget>[
                              const SizedBox(height: 14),
                              RequestErrorBanner(
                                message: controller.errorMessage.value!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _actions(context, submitting),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Patient Summary ─────────────────────────────────────────────────────────
  Widget _patientSummary(AmbulanceRequestDraft draft) {
    return SummarySection(
      title: 'Patient',
      children: <Widget>[
        SummaryRow(label: 'Request for', value: draft.requestFor.label),
        SummaryRow(label: 'Name', value: draft.patientName),
        SummaryRow(label: 'Age', value: draft.patientAge?.toString() ?? ''),
        SummaryRow(label: 'Gender', value: draft.patientGender),
        if (draft.requestFor == AmbulanceRequestFor.myself &&
            draft.patientId.trim().isNotEmpty)
          SummaryRow(label: 'Patient ID', value: draft.patientId),
      ],
    );
  }

  // ── Hospital Summary ───────────────────────────────────────────────────────
  Widget _hospitalSummary(AmbulanceRequestDraft draft) {
    return SummarySection(
      title: 'Hospital',
      children: <Widget>[
        SummaryRow(label: 'Hospital', value: draft.hospital?.displayName ?? ''),
        SummaryRow(label: 'Address', value: draft.hospital?.address ?? ''),
        SummaryRow(label: 'Phone', value: draft.hospital?.phone ?? ''),
      ],
    );
  }

  // ── Pickup Summary ─────────────────────────────────────────────────────────
  Widget _pickupSummary(AmbulanceRequestDraft draft) {
    final coordinates = draft.latitude == null || draft.longitude == null
        ? ''
        : '${draft.latitude!.toStringAsFixed(6)}, '
              '${draft.longitude!.toStringAsFixed(6)}';
    return SummarySection(
      title: 'Pickup location',
      children: <Widget>[
        SummaryRow(label: 'Location name', value: draft.locationName),
        SummaryRow(label: 'Address', value: draft.locationAddress),
        SummaryRow(label: 'Landmark', value: draft.landmark),
        SummaryRow(label: 'Coordinates', value: coordinates),
        SummaryRow(
          label: 'GPS accuracy',
          value: draft.locationAccuracyMeters == null
              ? ''
              : '${draft.locationAccuracyMeters!.toStringAsFixed(1)} m',
        ),
      ],
    );
  }

  // ── Emergency Summary ─────────────────────────────────────────────────────
  Widget _emergencySummary(AmbulanceRequestDraft draft) {
    return SummarySection(
      title: 'Emergency details',
      children: <Widget>[
        SummaryRow(label: 'Type', value: controller.emergencyTypeLabel),
        SummaryRow(label: 'Type code', value: draft.typeCode),
        SummaryRow(
          label: 'Patient count',
          value: draft.numberOfPatients.toString(),
        ),
        SummaryRow(label: 'Chief complaint', value: draft.chiefComplaint),
        SummaryRow(label: 'Symptoms', value: draft.symptoms),
        SummaryRow(label: 'Incident', value: draft.incidentDescription),
        SummaryRow(label: 'Note', value: draft.note),
        SummaryRow(
          label: 'Priority',
          value: draft.priorityCode.isEmpty
              ? 'Assigned automatically by EMS'
              : '${draft.priorityCode} (system default)',
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Widget _actions(BuildContext context, bool submitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('editAmbulanceBookingButton'),
              onPressed: submitting ? null : () => Get.back<void>(),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              key: const Key('confirmAmbulanceBookingButton'),
              onPressed: submitting ? null : () => _confirm(context),
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.local_hospital_rounded),
              label: Text(submitting ? 'Submitting…' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm Booking ─────────────────────────────────────────────────────
  Future<void> _confirm(BuildContext context) async {
    if (controller.isSubmitting || controller.hasSubmitted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('ambulanceBookingConfirmationDialog'),
        title: const Text('Confirm ambulance booking?'),
        content: const Text(
          'Your request and current pickup location will be sent to emergency services.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('submitAmbulanceBookingButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final draft = controller.draft.value;
    final result = await controller.submit();
    if (result == null || !context.mounted) return;
    Get.offAll<void>(
      () => BookingStatusView(result: result, draft: draft),
      binding: AmbulanceBinding(),
    );
  }
}
