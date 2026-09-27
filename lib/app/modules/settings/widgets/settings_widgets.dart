import 'package:flutter/material.dart';
import 'package:get/get.dart';

final class MoreSettingsPalette {
  const MoreSettingsPalette({
    required this.primary,
    required this.background,
    required this.groupSurface,
    required this.iconSurface,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.danger,
    required this.dangerLight,
    required this.onPrimary,
  });

  factory MoreSettingsPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return MoreSettingsPalette(
      primary: colors.primary,
      background: theme.scaffoldBackgroundColor,
      groupSurface: colors.surface,
      iconSurface: colors.surfaceContainerHighest,
      text: colors.onSurface,
      textSecondary: colors.onSurfaceVariant,
      border: colors.outlineVariant,
      divider: colors.outlineVariant,
      danger: colors.error,
      dangerLight: colors.errorContainer,
      onPrimary: colors.onPrimary,
    );
  }

  final Color primary;
  final Color background;
  final Color groupSurface;
  final Color iconSurface;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color danger;
  final Color dangerLight;
  final Color onPrimary;
}

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _ProfileAvatar(),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMERGENCY_RESPONDER'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: palette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      child: Icon(Icons.person_rounded, color: palette.onPrimary, size: 39),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Text(
      label,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.groupSurface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 53,
      endIndent: 16,
      color: palette.divider,
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailingValue,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? trailingValue;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SettingsIcon(icon: icon, danger: danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: danger ? palette.danger : palette.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                    ),
                  ),
                ),
                if (trailingValue != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailingValue!,
                    maxLines: 1,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textSecondary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 11, 0),
        child: Row(
          children: [
            SettingsIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.12,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.82,
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: danger ? palette.dangerLight : palette.iconSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: danger ? palette.danger : palette.textSecondary,
        size: 18,
      ),
    );
  }
}
