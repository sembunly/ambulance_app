import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (icon == null || isLoading) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: child,
    );
  }
}
