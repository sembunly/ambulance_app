import 'package:flutter/material.dart';

import 'package:ambulance_app/app/theme/app_theme.dart';
import 'package:ambulance_app/app/data/models/ambulance_request_model.dart';
import 'package:ambulance_app/app/data/models/hospital_model.dart';

class RequestAmbulanceHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const RequestAmbulanceHeader({
    super.key,
    required this.onBack,
    this.title = 'Request Ambulance',
  });

  final VoidCallback onBack;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        key: const Key('requestAmbulanceBackButton'),
        onPressed: onBack,
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      ),
      title: Text(title, key: const Key('requestAmbulanceTitle')),
      centerTitle: true,
    );
  }
}

class AmbulanceRequestStepIndicator extends StatelessWidget {
  const AmbulanceRequestStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  final int currentStep;
  final int totalSteps;
  final String label;

  static const List<({String label, IconData icon})> _steps = [
    (label: 'Patient', icon: Icons.person_outline_rounded),
    (label: 'Hospital', icon: Icons.local_hospital_outlined),
    (label: 'Pickup', icon: Icons.location_on_outlined),
    (label: 'Emergency', icon: Icons.emergency_outlined),
    (label: 'Review', icon: Icons.fact_check_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleSteps = _steps.take(totalSteps).toList(growable: false);

    return Semantics(
      label: 'Step $currentStep of $totalSteps: $label',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / visibleSteps.length;

          return SizedBox(
            height: 86,
            child: Stack(
              children: <Widget>[
                for (var index = 0; index < visibleSteps.length - 1; index++)
                  Positioned(
                    top: 24,
                    left: itemWidth * (index + .5),
                    width: itemWidth,
                    child: _StepConnector(reached: index + 1 < currentStep),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var index = 0; index < visibleSteps.length; index++)
                      Expanded(
                        child: _StepItem(
                          icon: visibleSteps[index].icon,
                          label: visibleSteps[index].label,
                          reached: index + 1 <= currentStep,
                          active: index + 1 == currentStep,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.reached});

  final bool reached;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 3,
      decoration: BoxDecoration(
        color: reached ? colors.errorSoft : colors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.label,
    required this.reached,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool reached;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? colors.errorSoft : colors.surface3,
            border: active
                ? Border.all(
                    color: colors.error.withValues(alpha: .22),
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            icon,
            color: reached ? colors.error : colors.textMuted,
            size: 27,
          ),
        ),
        const SizedBox(height: 9),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: reached ? colors.error : colors.textPrimary,
              fontSize: 12,
              height: 1.15,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class AmbulanceRequestFormCard extends StatelessWidget {
  const AmbulanceRequestFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AmbulanceRequestTextField extends StatelessWidget {
  const AmbulanceRequestTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.fieldKey,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}

class RequestForSelector extends StatelessWidget {
  const RequestForSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AmbulanceRequestFor value;
  final ValueChanged<AmbulanceRequestFor> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AmbulanceRequestFor>(
      key: const Key('requestForSelector'),
      segments: const <ButtonSegment<AmbulanceRequestFor>>[
        ButtonSegment<AmbulanceRequestFor>(
          value: AmbulanceRequestFor.myself,
          icon: Icon(Icons.person_outline_rounded),
          label: Text('For myself'),
        ),
        ButtonSegment<AmbulanceRequestFor>(
          value: AmbulanceRequestFor.someoneElse,
          icon: Icon(Icons.group_outlined),
          label: Text('Someone else'),
        ),
      ],
      selected: <AmbulanceRequestFor>{value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class HospitalSelectionCard extends StatelessWidget {
  const HospitalSelectionCard({
    super.key,
    required this.hospital,
    required this.selected,
    required this.onTap,
  });

  final HospitalModel hospital;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? context.appColors.primarySoft : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? context.appColors.primary
              : context.appColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('selectHospital_${hospital.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.local_hospital_rounded,
                color: selected
                    ? context.appColors.primary
                    : context.appColors.success,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hospital.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (hospital.address.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        hospital.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    if (hospital.distanceMeters != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        _distance(hospital.distanceMeters!),
                        style: TextStyle(
                          color: context.appColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? context.appColors.primary
                    : context.appColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _distance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

class PatientCountSelector extends StatelessWidget {
  const PatientCountSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: FieldLabel('Number of patients')),
        IconButton.filledTonal(
          key: const Key('decreasePatientCount'),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            key: const Key('patientCountValue'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          key: const Key('increasePatientCount'),
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class RequestErrorBanner extends StatelessWidget {
  const RequestErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ambulanceRequestError'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            semanticLabel: 'Error',
            size: 30,
            color: context.appColors.error,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AmbulanceRequestFormCard(
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
