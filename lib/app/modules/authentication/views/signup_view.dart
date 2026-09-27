import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../controllers/authentication_controller.dart';
import '../widgets/signup_form.dart';

// ── Signup page ────────────────────────────────────────────────────────────
class SignupView extends GetView<AuthenticationController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('signupScreen'),
      backgroundColor: context.appColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('signupScrollView'),
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          key: const Key('signupBackButton'),
                          tooltip: 'Back to login',
                          onPressed: () =>
                              Get.offAllNamed(Routes.authentication),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            foregroundColor: context.appColors.textPrimary,
                            backgroundColor: context.appColors.surface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SignupHeader(),
                      const SizedBox(height: 30),
                      Obx(
                        () => SignupForm(
                          isLoading: controller.isLoading.value,
                          errorMessage: controller.errorMessage.value,
                          onSubmit:
                              (
                                fullName,
                                phoneNumber,
                                email,
                                password,
                                gender,
                                dateOfBirth,
                              ) => controller.signup(
                                fullName,
                                phoneNumber,
                                email,
                                password,
                                gender: gender,
                                dateOfBirth: dateOfBirth,
                              ),
                          onLogin: () => Get.offAllNamed(Routes.authentication),
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

// ── Signup header ──────────────────────────────────────────────────────────
class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.surface3,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              Icons.emergency_rounded,
              color: context.appColors.primary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Create Account',
          key: const Key('signupTitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Join the ambulance care',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
