import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/settings_controller.dart';

enum PasswordSettingsMode { changePassword, forgotPassword }

class PasswordSettingsView extends StatefulWidget {
  const PasswordSettingsView({super.key});

  @override
  State<PasswordSettingsView> createState() => _PasswordSettingsViewState();
}

class _PasswordSettingsViewState extends State<PasswordSettingsView> {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final _changePasswordFormKey = GlobalKey<FormState>();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();

  PasswordSettingsMode _mode = PasswordSettingsMode.changePassword;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmittingChangePassword = false;
  final bool _isSubmittingForgotPassword = false;
  String? _changePasswordError;
  String? _forgotPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_changePasswordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmittingChangePassword = true;
      _changePasswordError = null;
    });

    try {
      await _settingsController.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );
      if (!mounted) return;
      _clearChangePasswordForm();
      _showSuccess('Password updated successfully.');
      Get.back();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _changePasswordError = _readableError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmittingChangePassword = false);
      }
    }
  }

  Future<void> _submitForgotPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_forgotPasswordFormKey.currentState?.validate() ?? false)) return;

    setState(
      () => _forgotPasswordError = 'Password recovery is not available yet.',
    );
  }

  void _clearChangePasswordForm() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _changePasswordFormKey.currentState?.reset();
    setState(() {
      _hideCurrentPassword = true;
      _hideNewPassword = true;
      _hideConfirmPassword = true;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _readableError(Object error) {
    if (error is StateError && error.message.isNotEmpty) {
      return error.message;
    }
    final message = error.toString().replaceFirst('Exception: ', '');
    final match = RegExp(r'^[A-Za-z]+Exception: (.+)$').firstMatch(message);
    if (match != null) return match.group(1)!;
    return message;
  }

  bool get _isBusy =>
      _isSubmittingChangePassword || _isSubmittingForgotPassword;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Password Settings'),
        centerTitle: false,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('passwordSettingsBackButton'),
          tooltip: 'Back',
          onPressed: _isBusy ? null : () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(colorTokens: colors),
                  const SizedBox(height: 18),
                  _ModeSelector(
                    mode: _mode,
                    onChanged: _isBusy
                        ? null
                        : (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _mode == PasswordSettingsMode.changePassword
                        ? _ChangePasswordForm(
                            key: const ValueKey('changePasswordForm'),
                            formKey: _changePasswordFormKey,
                            currentPasswordController:
                                _currentPasswordController,
                            newPasswordController: _newPasswordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            hideCurrentPassword: _hideCurrentPassword,
                            hideNewPassword: _hideNewPassword,
                            hideConfirmPassword: _hideConfirmPassword,
                            isLoading: _isSubmittingChangePassword,
                            errorMessage: _changePasswordError,
                            onToggleCurrentPassword: () {
                              setState(
                                () => _hideCurrentPassword =
                                    !_hideCurrentPassword,
                              );
                            },
                            onToggleNewPassword: () {
                              setState(
                                () => _hideNewPassword = !_hideNewPassword,
                              );
                            },
                            onToggleConfirmPassword: () {
                              setState(
                                () => _hideConfirmPassword =
                                    !_hideConfirmPassword,
                              );
                            },
                            onSubmit: _submitChangePassword,
                          )
                        : _ForgotPasswordForm(
                            key: const ValueKey('forgotPasswordForm'),
                            formKey: _forgotPasswordFormKey,
                            contactController: _contactController,
                            isLoading: _isSubmittingForgotPassword,
                            errorMessage: _forgotPasswordError,
                            onSubmit: _submitForgotPassword,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.colorTokens});

  final AppColorTokens colorTokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorTokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorTokens.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.password_rounded,
              color: colorTokens.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure your account',
                  style: TextStyle(
                    color: colorTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Change your password or request a reset using the contact tied to your account.',
                  style: TextStyle(
                    color: colorTokens.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final PasswordSettingsMode mode;
  final ValueChanged<PasswordSettingsMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SegmentedButton<PasswordSettingsMode>(
      segments: const [
        ButtonSegment<PasswordSettingsMode>(
          value: PasswordSettingsMode.changePassword,
          label: Text('Change Password'),
          icon: Icon(Icons.lock_reset_rounded),
        ),
        ButtonSegment<PasswordSettingsMode>(
          value: PasswordSettingsMode.forgotPassword,
          label: Text('Forgot Password'),
          icon: Icon(Icons.mark_email_read_outlined),
        ),
      ],
      selected: <PasswordSettingsMode>{mode},
      onSelectionChanged: onChanged == null
          ? null
          : (selection) => onChanged!(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.textSecondary,
        selectedForegroundColor: colors.background,
        selectedBackgroundColor: colors.primary,
        side: BorderSide(color: colors.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ChangePasswordForm extends StatelessWidget {
  const _ChangePasswordForm({
    super.key,
    required this.formKey,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.hideCurrentPassword,
    required this.hideNewPassword,
    required this.hideConfirmPassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool hideCurrentPassword;
  final bool hideNewPassword;
  final bool hideConfirmPassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Change Password',
      subtitle: 'Update the password you use to sign in to the app.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              key: const Key('currentPasswordField'),
              controller: currentPasswordController,
              label: 'Current password',
              hintText: 'Enter current password',
              obscureText: hideCurrentPassword,
              isLoading: isLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              onToggleVisibility: onToggleCurrentPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Current password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _PasswordField(
              key: const Key('newPasswordField'),
              controller: newPasswordController,
              label: 'New password',
              hintText: 'Create a new password',
              obscureText: hideNewPassword,
              isLoading: isLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onToggleVisibility: onToggleNewPassword,
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'New password is required';
                if (password.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
                    !RegExp(r'\d').hasMatch(password)) {
                  return 'Use at least one letter and one number';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _PasswordField(
              key: const Key('confirmNewPasswordField'),
              controller: confirmPasswordController,
              label: 'Confirm new password',
              hintText: 'Re-enter the new password',
              obscureText: hideConfirmPassword,
              isLoading: isLoading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onToggleVisibility: onToggleConfirmPassword,
              onFieldSubmitted: (_) {
                if (!isLoading) onSubmit();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Use a strong password with at least 8 characters, one letter, and one number.',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _InlineStatusMessage(
                key: const Key('changePasswordError'),
                message: errorMessage!,
                icon: Icons.error_outline_rounded,
                backgroundColor: context.appColors.errorSoft,
                foregroundColor: context.appColors.error,
              ),
            ],
            const SizedBox(height: 18),
            _ActionButton(
              key: const Key('savePasswordButton'),
              label: 'Save Password',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordForm extends StatelessWidget {
  const _ForgotPasswordForm({
    super.key,
    required this.formKey,
    required this.contactController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController contactController;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Forgot Password',
      subtitle: 'Send an OTP or reset link to the contact on your account.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TextFieldLabel(
              text: 'Email or phone number',
              color: context.appColors.textPrimary,
            ),
            const SizedBox(height: 9),
            TextFormField(
              key: const Key('forgotPasswordContactField'),
              controller: contactController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.telephoneNumber,
              ],
              onFieldSubmitted: (_) {
                if (!isLoading) onSubmit();
              },
              decoration: const InputDecoration(
                hintText: 'Enter email or phone number',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final contact = value?.trim() ?? '';
                if (contact.isEmpty) {
                  return 'Email or phone number is required';
                }
                if (_looksLikeEmail(contact) || _looksLikePhone(contact)) {
                  return null;
                }
                return 'Enter a valid email address or phone number';
              },
            ),
            const SizedBox(height: 10),
            Text(
              'We’ll use this contact to send recovery instructions.',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _InlineStatusMessage(
                key: const Key('forgotPasswordError'),
                message: errorMessage!,
                icon: Icons.error_outline_rounded,
                backgroundColor: context.appColors.errorSoft,
                foregroundColor: context.appColors.error,
              ),
            ],
            const SizedBox(height: 18),
            _ActionButton(
              key: const Key('sendRecoveryButton'),
              label: 'Send OTP / reset link',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TextFieldLabel extends StatelessWidget {
  const _TextFieldLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.obscureText,
    required this.isLoading,
    required this.textInputAction,
    required this.autofillHints,
    required this.onToggleVisibility,
    required this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final bool isLoading;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TextFieldLabel(text: label, color: context.appColors.textPrimary),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          enabled: !isLoading,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Show $label' : 'Hide $label',
              onPressed: isLoading ? null : onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : () => onPressed(),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.background,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: colors.background,
                  strokeWidth: 2.3,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _InlineStatusMessage extends StatelessWidget {
  const _InlineStatusMessage({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _looksLikeEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

bool _looksLikePhone(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  return RegExp(r'^\+?[0-9]{6,15}$').hasMatch(digitsOnly);
}
