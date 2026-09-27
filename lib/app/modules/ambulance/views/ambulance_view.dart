import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/ambulance_request_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/ambulance_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/request_ambulance_widgets.dart';
import 'confirm_ambulance_booking_view.dart';

// ── Request Ambulance Screen ─────────────────────────────────────────────
class AmbulanceView extends StatefulWidget {
  const AmbulanceView({super.key});

  @override
  State<AmbulanceView> createState() => _AmbulanceViewState();
}

class _AmbulanceViewState extends State<AmbulanceView> {
  late final AmbulanceController _controller = Get.find<AmbulanceController>();
  bool _showValidation = false;
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  static const List<String> _stepLabels = <String>[
    'Patient',
    'Hospital',
    'Pickup',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_initializeForm());
  }

  Future<void> _initializeForm() async {
    await _controller.initialize();
    if (!mounted) return;
    final phone = _controller.profilePhone;
    if (phone.isNotEmpty && _phoneController.text.isEmpty) {
      _phoneController.text = phone;
      _syncContactNote();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = _controller.currentStep.value;
      return Scaffold(
        key: const Key('requestAmbulanceScreen'),
        backgroundColor: context.appColors.background,
        appBar: RequestAmbulanceHeader(onBack: () => _goBack(context)),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _controller.isInitializing.value
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: <Widget>[
                        Expanded(
                          child: SingleChildScrollView(
                            key: const Key('ambulanceRequestScrollView'),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                AmbulanceRequestStepIndicator(
                                  currentStep: step + 1,
                                  totalSteps: _stepLabels.length + 1,
                                  label: _stepLabels[step],
                                ),
                                const SizedBox(height: 20),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(step),
                                    child: _stepContent(step),
                                  ),
                                ),
                                if (_controller.errorMessage.value !=
                                    null) ...<Widget>[
                                  const SizedBox(height: 14),
                                  RequestErrorBanner(
                                    message: _controller.errorMessage.value!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _bottomBar(context, step),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── Step Content ─────────────────────────────────────────────────────
  Widget _stepContent(int step) => switch (step) {
    0 => _patientStep(),
    1 => _hospitalStep(),
    2 => _pickupStep(),
    _ => _emergencyStep(),
  };

  // ── Patient Step ─────────────────────────────────────────────────────
  Widget _patientStep() {
    final draft = _controller.draft.value;
    return Form(
      key: _controller.patientFormKey,
      autovalidateMode: _showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _StepHeading(
            title: 'Patient details',
            subtitle: 'Enter the patient and contact information.',
          ),
          const SizedBox(height: 16),
          AmbulanceRequestFormCard(
            children: <Widget>[
              AppTextField(
                key: const Key('patientNameField'),
                controller: _controller.patientNameController,
                label: 'Patient name',
                hintText: 'Enter the patient name',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: _controller.validatePatientName,
                onChanged: _controller.updatePatientName,
                maxLength: 200,
              ),
              const SizedBox(height: 14),
              AppTextField(
                key: const Key('phoneNumberField'),
                controller: _phoneController,
                label: 'Phone number',
                hintText: 'Enter a phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: _validatePhoneNumber,
                onChanged: (_) => _syncContactNote(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ReportedGender>(
                key: const Key('patientGenderField'),
                initialValue: _reportedGender(draft.patientGender),
                decoration: const InputDecoration(
                  labelText: 'Patient gender',
                  hintText: 'Select patient gender',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
                items: ReportedGender.values
                    .map(
                      (gender) => DropdownMenuItem<ReportedGender>(
                        value: gender,
                        child: Text(gender.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _controller.updatePatientGender,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  void _syncContactNote() {
    final phone = _phoneController.text.trim();
    final emergencyContact = _emergencyContactController.text.trim();
    _controller.updateNote(
      <String>[
        if (phone.isNotEmpty) 'Phone: $phone',
        if (emergencyContact.isNotEmpty) 'Emergency contact: $emergencyContact',
      ].join('\n'),
    );
  }

  // ── Reported Gender ─────────────────────────────────
  ReportedGender? _reportedGender(String value) {
    for (final gender in ReportedGender.values) {
      if (gender.apiValue == value.toUpperCase()) return gender;
    }
    return null;
  }

  String? _emergencyLevel(String value) {
    const levels = <String>{'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'};
    return levels.contains(value) ? value : null;
  }

  // ── Hospital Step ───────────────────────────────────────────────────
  Widget _hospitalStep() {
    final nearby = _controller.hospitalController;
    final selected = _controller.draft.value.hospital;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _StepHeading(
          title: 'Destination / Hospital',
          subtitle: 'Hospitals are ordered using your current location.',
        ),
        const SizedBox(height: 14),
        if (nearby.status.value == NearbyHospitalsStatus.loading ||
            nearby.status.value == NearbyHospitalsStatus.locating ||
            nearby.status.value == NearbyHospitalsStatus.initial)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (nearby.hospitals.isEmpty)
          _HospitalLoadState(
            message: nearby.errorMessage.value ?? 'No hospitals are available.',
            onRetry: nearby.refreshHospitals,
          )
        else ...<Widget>[
          for (final hospital in nearby.hospitals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HospitalSelectionCard(
                hospital: hospital,
                selected: selected?.id == hospital.id,
                onTap: () => _controller.selectHospital(hospital),
              ),
            ),
          if (nearby.hasMore.value)
            OutlinedButton(
              onPressed: nearby.isLoadingMore.value ? null : nearby.loadMore,
              child: nearby.isLoadingMore.value
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more hospitals'),
            ),
        ],
      ],
    );
  }

  // ── Pickup Step ─────────────────────────────────────────────────────
  Widget _pickupStep() {
    final draft = _controller.draft.value;
    final locating =
        _controller.locationStatus.value == PickupLocationStatus.locating;
    final hasCoordinates = draft.latitude != null && draft.longitude != null;
    return Form(
      key: _controller.pickupFormKey,
      autovalidateMode: _showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _StepHeading(
            title: 'Pickup location',
            subtitle:
                'Use GPS to fill your pickup location, then confirm the address.',
          ),
          const SizedBox(height: 16),
          AmbulanceRequestFormCard(
            children: <Widget>[
              AppButton(
                key: const Key('capturePickupLocationButton'),
                onPressed: locating ? null : _controller.handleLocationAction,
                icon: Icons.my_location_rounded,
                isLoading: locating,
                label: hasCoordinates
                    ? 'Refresh current location'
                    : 'Use current location',
              ),
              if (hasCoordinates) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  key: const Key('pickupCoordinates'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${draft.latitude!.toStringAsFixed(6)}, '
                    '${draft.longitude!.toStringAsFixed(6)}\n'
                    'Accuracy: ${draft.locationAccuracyMeters?.toStringAsFixed(1) ?? '—'} m',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('pickupAddressField'),
                controller: _controller.pickupAddressController,
                label: 'Pickup location',
                hintText: 'Street, village, district, or full address',
                prefixIcon: Icons.location_on_outlined,
                textInputAction: TextInputAction.done,
                validator: _controller.validatePickupAddress,
                onChanged: _controller.updatePickupAddress,
                maxLines: 2,
                maxLength: 255,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Emergency Step ─────────────────────────────────────────────────
  Widget _emergencyStep() {
    final draft = _controller.draft.value;
    return Form(
      key: _controller.emergencyFormKey,
      autovalidateMode: _showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _StepHeading(
            title: 'Emergency details',
            subtitle: 'Share what responders need before they arrive.',
          ),
          const SizedBox(height: 16),
          AmbulanceRequestFormCard(
            children: <Widget>[
              const FieldLabel('Ambulance type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('emergencyTypeCodeField'),
                initialValue: draft.typeCode.isEmpty ? null : draft.typeCode,
                decoration: const InputDecoration(
                  hintText: 'Select ambulance type',
                  prefixIcon: Icon(Icons.emergency_outlined),
                ),
                items: AmbulanceController.emergencyTypeLabels.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Emergency type is required'
                    : null,
                onChanged: _controller.selectTypeCode,
              ),
              const SizedBox(height: 16),
              const FieldLabel('Emergency level'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('emergencyLevelField'),
                initialValue: _emergencyLevel(draft.priorityCode),
                decoration: const InputDecoration(
                  hintText: 'Select emergency level',
                  prefixIcon: Icon(Icons.priority_high_rounded),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: _controller.selectPriorityCode,
              ),
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('emergencyNoteField'),
                controller: _controller.symptomsController,
                label: 'Emergency note / symptoms (optional)',
                hintText: 'Describe symptoms or what happened',
                prefixIcon: Icons.monitor_heart_outlined,
                onChanged: _controller.updateSymptoms,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('emergencyContactField'),
                controller: _emergencyContactController,
                label: 'Emergency contact (optional)',
                hintText: 'Name and phone number',
                prefixIcon: Icons.contact_phone_outlined,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _syncContactNote(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────
  Widget _bottomBar(BuildContext context, int step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: Row(
        children: <Widget>[
          if (step > 0) ...<Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goBack(context),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: step > 0 ? 2 : 1,
            child: FilledButton(
              key: const Key('ambulanceRequestContinueButton'),
              onPressed: () => _continue(context),
              child: Text(step == 3 ? 'Review booking' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Continue ─────────────────────────────────────────────────────────
  void _continue(BuildContext context) {
    setState(() => _showValidation = true);
    final wasLastStep = _controller.currentStep.value == 3;
    if (!_controller.goNext()) return;
    setState(() => _showValidation = false);
    if (_controller.currentStep.value == 2 &&
        _controller.locationStatus.value == PickupLocationStatus.initial) {
      unawaited(_controller.useCurrentLocation());
    }
    if (!wasLastStep) return;
    Get.to<void>(() => ConfirmAmbulanceBookingView(controller: _controller));
  }

  void _goBack(BuildContext context) {
    if (_controller.goBack()) {
      setState(() => _showValidation = false);
      return;
    }
    Get.back<void>();
  }
}

// ── Step Heading ─────────────────────────────────────────────────────
class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: context.appColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

// ── Hospital Load State ─────────────────────────────────────────────────
class _HospitalLoadState extends StatelessWidget {
  const _HospitalLoadState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return AmbulanceRequestFormCard(
      children: <Widget>[
        const Icon(Icons.local_hospital_outlined, size: 38),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
