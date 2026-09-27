import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/hospital_model.dart';

class HospitalCard extends StatelessWidget {
  const HospitalCard({
    super.key,
    required this.hospital,
    required this.onCall,
    required this.onOpenMaps,
  });

  final HospitalModel hospital;
  final VoidCallback onCall;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HospitalLogo(logo: hospital.logo),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.displayName,
                        style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (hospital.khmerName.isNotEmpty &&
                          hospital.khmerName != hospital.displayName) ...[
                        const SizedBox(height: 3),
                        Text(
                          hospital.khmerName,
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          if (hospital.type.isNotEmpty)
                            _Tag(
                              icon: Icons.local_hospital_outlined,
                              label: hospital.type,
                            ),
                          if (hospital.distanceMeters != null)
                            _Tag(
                              icon: Icons.near_me_outlined,
                              label: _distanceLabel(hospital.distanceMeters!),
                              highlighted: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hospital.address.isNotEmpty) ...[
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.location_on_outlined,
                value: hospital.address,
              ),
            ],
            if (hospital.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(icon: Icons.phone_outlined, value: hospital.phone),
            ],
            if (hospital.website.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.language_outlined,
                value: hospital.website,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hospital.hasCoordinates ? onOpenMaps : null,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Open Maps'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hospital.phone.trim().isNotEmpty ? onCall : null,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call Hospital'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _distanceLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(3)} km away';
  }
}

class _HospitalLogo extends StatelessWidget {
  const _HospitalLogo({required this.logo});

  final String logo;

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl(logo);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 60,
        height: 60,
        color: context.appColors.successSoft,
        child: url == null
            ? _fallback(context)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(context),
              ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Icon(
      Icons.local_hospital_rounded,
      color: context.appColors.success,
      size: 30,
    );
  }

  String? _resolveUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) return uri.toString();
    return Uri.tryParse(AppConfig.apiBaseUrl)?.resolve(trimmed).toString();
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted
        ? context.appColors.success
        : context.appColors.textSecondary;
    final background = highlighted
        ? context.appColors.successSoft
        : context.appColors.surface2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, color: context.appColors.textMuted, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
