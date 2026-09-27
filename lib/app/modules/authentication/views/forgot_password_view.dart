import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';

// ── Password recovery page ────────────────────────────────────────────────
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _contactFocus = FocusNode();
  String? _message;

  @override
  void dispose() {
    _contactController.dispose();
    _contactFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _message = 'Password recovery is not available yet.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgotPasswordScreen'),
      backgroundColor: context.appColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: context.appColors.background,
        leading: IconButton(
          tooltip: 'Back to login',
          onPressed: () => Get.offAllNamed(Routes.authentication),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 570,
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: context.appColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: context.appColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter the email or phone number tied to your account.',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const Key('forgotPasswordContactField'),
                              controller: _contactController,
                              focusNode: _contactFocus,
                              enabled: true,
                              readOnly: false,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.email,
                                AutofillHints.telephoneNumber,
                              ],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Email or phone number',
                                hintText: 'Enter email or phone number',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                final contact = value?.trim() ?? '';
                                if (contact.isEmpty) {
                                  return 'Email or phone number is required';
                                }
                                if (_looksLikeEmail(contact) ||
                                    _looksLikePhone(contact)) {
                                  return null;
                                }
                                return 'Enter a valid email address or phone number';
                              },
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _message!,
                                key: const Key('forgotPasswordMessage'),
                                style: TextStyle(
                                  color: context.appColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                key: const Key('sendRecoveryButton'),
                                onPressed: _submit,
                                child: const Text('Send OTP / reset link'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

bool _looksLikePhone(String value) {
  final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  return RegExp(r'^\+?[0-9]{6,15}$').hasMatch(digits);
}
