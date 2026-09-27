import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/settings_controller.dart';
import '../widgets/logout_confirmation.dart';
import '../widgets/settings_widgets.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return _SettingsView(
      onLogout: () => confirmLogout(context, controller.logout),
      onBack: () => Get.back(),
      onPassword: () => Get.toNamed(Routes.passwordSettings),
      settingsController: controller,
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView({
    required this.onLogout,
    required this.settingsController,
    this.onBack,
    this.onPassword,
  });

  final VoidCallback onLogout;
  final VoidCallback? onBack;
  final VoidCallback? onPassword;
  final SettingsController settingsController;

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late final Worker _settingsErrorWorker;

  @override
  void initState() {
    super.initState();
    _settingsErrorWorker = ever<String?>(
      widget.settingsController.errorMessage,
      (message) => _scheduleError(message),
    );
  }

  @override
  void dispose() {
    _settingsErrorWorker.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final language = widget.settingsController.language.value;
    final palette = MoreSettingsPalette.of(context);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.groupSurface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  trailing: language == 'en'
                      ? Icon(Icons.check_rounded, color: palette.primary)
                      : null,
                  onTap: () => Navigator.pop(context, 'en'),
                ),
                ListTile(
                  title: const Text('ភាសាខ្មែរ'),
                  trailing: language == 'km'
                      ? Icon(Icons.check_rounded, color: palette.primary)
                      : null,
                  onTap: () => Navigator.pop(context, 'km'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await widget.settingsController.setLanguage(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final language = widget.settingsController.language.value;
      final notificationsEnabled =
          widget.settingsController.notificationsEnabled.value;
      final palette = MoreSettingsPalette.of(context);
      return Scaffold(
        key: const Key('moreSettingsPage'),
        backgroundColor: palette.background,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsHeader(onBack: widget.onBack),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('moreSettingsScrollView'),
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SettingsProfileHeader(),
                            const SizedBox(height: 32),
                            const SettingsSectionLabel('Preferences'),
                            const SizedBox(height: 10),
                            SettingsGroup(
                              children: [
                                SettingsToggleRow(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Notifications and sounds',
                                  value: notificationsEnabled,
                                  onChanged: widget
                                      .settingsController
                                      .setNotificationsEnabled,
                                ),
                                const SettingsDivider(),
                                SettingsRow(
                                  icon: Icons.translate_rounded,
                                  title: 'Language',
                                  trailingValue: language == 'km'
                                      ? 'ភាសាខ្មែរ'
                                      : 'English',
                                  onTap: () => _selectLanguage(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 27),
                            const SettingsSectionLabel('Account'),
                            const SizedBox(height: 10),
                            SettingsGroup(
                              children: [
                                SettingsRow(
                                  icon: Icons.lock_outline_rounded,
                                  title: 'Password',
                                  onTap: widget.onPassword,
                                ),
                                // const SettingsDivider(),
                                // SettingsToggleRow(
                                //   icon: Icons.face_retouching_natural_rounded,
                                //   title: 'Login with Face ID',
                                //   value: _faceIdEnabled,
                                //   onChanged: (value) {
                                //     setState(() => _faceIdEnabled = value);
                                //   },
                                // ),
                                // const SettingsDivider(),
                                // SettingsRow(
                                //   icon: Icons.info_outline_rounded,
                                //   title: 'Support',
                                //   onTap: widget.onSupport,
                                // ),
                                // const SettingsDivider(),
                                // SettingsRow(
                                //   icon: Icons.cleaning_services_outlined,
                                //   title: 'Clear cache',
                                //   onTap: widget.onClearCache,
                                // ),
                                // const SettingsDivider(),
                                // SettingsRow(
                                //   icon: Icons.privacy_tip_outlined,
                                //   title: 'Terms and Privacy Policy',
                                //   onTap: widget.onTermsAndPrivacy,
                                // ),
                                const SettingsDivider(),
                                SettingsRow(
                                  key: const Key('moreSignOutButton'),
                                  icon: Icons.logout_rounded,
                                  title: 'Logout',
                                  onTap: widget.onLogout,
                                  danger: true,
                                  showChevron: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _scheduleError(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showError(message);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = MoreSettingsPalette.of(context);
    final handleBack = onBack ?? () => Navigator.of(context).maybePop();
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            child: IconButton(
              key: const Key('settingsBackButton'),
              tooltip: 'Back',
              onPressed: handleBack,
              color: palette.text,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            ),
          ),
          Text(
            'Settings',
            key: const Key('moreSettingsTitle'),
            style: TextStyle(
              color: palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }
}
