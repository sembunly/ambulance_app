import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../controllers/authentication_controller.dart';

class AuthenticationView extends GetView<AuthenticationController> {
  const AuthenticationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('loginScreen'),
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final keyboardOpen =
              View.of(context).viewInsets.bottom > 0 ||
              MediaQuery.viewInsetsOf(context).bottom > 0;
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 14.5;
          final allowScroll = keyboardOpen || height < 820 || largeText;
          final sheetTop = keyboardOpen
              ? 160.0
              : math.min(
                  (height * 0.35).clamp(220.0, 330.0),
                  math.max(220.0, height - 575),
                );
          final horizontalPadding = constraints.maxWidth < 360 ? 20.0 : 28.0;
          final contentHeight = allowScroll
              ? math.max(height, sheetTop + 575)
              : height;
          final content = SizedBox(
            height: contentHeight,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: sheetTop + 34,
                  child: _LoginHero(compactForKeyboard: keyboardOpen),
                ),
                Positioned(
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      32,
                      horizontalPadding,
                      34,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 570),
                        child: Obx(
                          () => _LoginForm(
                            controller: controller,
                            isLoading: controller.isLoading.value,
                            errorMessage: controller.errorMessage.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          return SingleChildScrollView(
            key: const Key('loginScrollView'),
            physics: allowScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: content,
          );
        },
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.compactForKeyboard});

  final bool compactForKeyboard;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_ambulance_hero.png',
          key: const Key('loginHeroImage'),
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.34),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryDim.withValues(alpha: 0.62),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (compactForKeyboard) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                  child: Row(
                    children: [
                      const _MedicalLogo(size: 60),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Ambulance Booking',
                          key: Key('loginTitle'),
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final compact = constraints.maxHeight < 330;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  compact ? 16 : 34,
                  20,
                  compact ? 44 : 58,
                ),
                child: Column(
                  children: [
                    _MedicalLogo(size: compact ? 90 : 110),
                    const Spacer(),
                    Text(
                      'Ambulance Booking',
                      key: const Key('loginTitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: compact ? 34 : 40,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryDim.withValues(alpha: 0.45),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MedicalLogo extends StatelessWidget {
  const _MedicalLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loginMedicalLogo'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppColors.border2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        Icons.emergency_rounded,
        color: AppColors.primary,
        size: size * 0.61,
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
  });

  final AuthenticationController controller;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.login(
      _phoneNumberController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compactForError = widget.errorMessage != null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Label('Phone Number'),
          const SizedBox(height: 9),
          TextFormField(
            key: const Key('phoneNumberField'),
            controller: _phoneNumberController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: _fieldTextStyle,
            decoration: _inputDecoration(hintText: 'Enter phone number'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Phone number is required'
                : null,
          ),
          SizedBox(height: compactForError ? 16 : 24),
          const _Label('Password'),
          const SizedBox(height: 9),
          TextFormField(
            key: const Key('passwordField'),
            controller: _passwordController,
            enabled: !widget.isLoading,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) {
              if (!widget.isLoading) _submit();
            },
            style: _fieldTextStyle,
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                onPressed: widget.isLoading
                    ? null
                    : () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 23,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required' : null,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              key: const Key('loginError'),
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: compactForError ? 4 : 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('forgotPasswordButton'),
              onPressed: widget.isLoading
                  ? null
                  : () => Get.toNamed(Routes.forgotPassword),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: compactForError ? 16 : 22),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: widget.isLoading ? 0.12 : 0.28,
                  ),
                  blurRadius: 11,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('signInButton'),
                onPressed: widget.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.55,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        key: Key('loginProgress'),
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          color: AppColors.onPrimary,
                          strokeWidth: 2.3,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: compactForError ? 14 : 28),
          const _SocialDivider(),
          SizedBox(height: compactForError ? 10 : 22),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              key: const Key('googleSignInButton'),
              onPressed: null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                key: const Key('loginSignupButton'),
                onPressed: widget.isLoading
                    ? null
                    : () => Get.toNamed(Routes.signup),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _fieldTextStyle => const TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
  );

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: AppColors.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
      suffixIcon: suffixIcon,
      suffixIconColor: AppColors.textSecondary,
      suffixIconConstraints: suffixIcon == null
          ? null
          : const BoxConstraints(minWidth: 54, minHeight: 56),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      disabledBorder: _inputBorder(
        color: AppColors.border.withValues(alpha: 0.7),
      ),
      focusedBorder: _inputBorder(color: AppColors.primary),
      errorBorder: _inputBorder(color: AppColors.error),
      focusedErrorBorder: _inputBorder(color: AppColors.error),
    );
  }

  OutlineInputBorder _inputBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color ?? AppColors.border, width: 1.2),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
