import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../settings/widgets/logout_confirmation.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileController _profileController = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Widget _buildPage(BuildContext context) {
    return Obx(() {
      return switch (_profileController.status.value) {
        ProfileStatus.initial || ProfileStatus.loading => Scaffold(
          key: const Key('profilePage'),
          backgroundColor: context.appColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
        ProfileStatus.empty => _ProfileMessagePage(
          message: 'No profile information is available.',
          onRetry: _profileController.loadProfile,
        ),
        ProfileStatus.error => _ProfileMessagePage(
          message:
              _profileController.errorMessage.value ??
              'Unable to load your profile.',
          onRetry: _profileController.loadProfile,
        ),
        ProfileStatus.success => _buildProfile(
          context,
          _profileController.profile.value!,
        ),
      };
    });
  }

  Widget _buildProfile(BuildContext context, UserProfile profile) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 14.0
        : 18.0;

    String formatDate(DateTime? value) {
      if (value == null) return 'Not available';
      return '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/'
          '${value.year}';
    }

    return Scaffold(
      key: const Key('profilePage'),
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(
              key: const Key('profileContent'),
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding - 8,
                      4,
                      horizontalPadding,
                      0,
                    ),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              key: const Key('profileBackButton'),
                              tooltip: 'Back',
                              padding: EdgeInsets.zero,
                              onPressed: () => Get.back(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Profile',
                                key: const Key('profileTitle'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appColors.textPrimary,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.35,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('profileScrollView'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: _ProfileAvatar(
                              avatarUrl: profile.avatar,
                              fullName: profile.fullName,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              profile.fullName,
                              style: TextStyle(
                                color: context.appColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ProfileInfoCard(
                            title: 'Personal details',
                            actionLabel: null,
                            onAction: null,
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Full name',
                                value: profile.fullName,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: profile.email.isNotEmpty
                                    ? profile.email
                                    : 'Not available',
                              ),
                              _ProfileInfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: profile.phone.isNotEmpty
                                    ? profile.phone
                                    : 'Not available',
                              ),
                              _ProfileInfoRow(
                                icon: Icons.wc_outlined,
                                label: 'Gender',
                                value: profile.gender.isNotEmpty
                                    ? profile.gender
                                    : 'Not available',
                              ),
                              _ProfileInfoRow(
                                icon: Icons.cake_outlined,
                                label: 'Date of birth',
                                value: formatDate(profile.dateOfBirth),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              key: const Key('profileSignOutButton'),
                              onPressed: () => confirmLogout(
                                context,
                                _profileController.logout,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.appColors.error,
                                backgroundColor: context.appColors.errorSoft,
                                side: BorderSide(
                                  color: context.appColors.error.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: const Text(
                                'Sign out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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
  }
}

class _ProfileMessagePage extends StatelessWidget {
  const _ProfileMessagePage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('profilePage'),
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl, required this.fullName});

  final String avatarUrl;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.trim().isNotEmpty;
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appColors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl.trim(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null ? child : _avatarFallback(context),
                errorBuilder: (context, error, stackTrace) =>
                    _avatarFallback(context),
              )
            : _avatarFallback(context),
      ),
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      color: context.appColors.primary,
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: context.appColors.onPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border),
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              if (actionLabel != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    TextButton(
                      key: const Key('profileEditButton'),
                      onPressed: onAction ?? () {},
                      style: TextButton.styleFrom(
                        foregroundColor: context.appColors.textPrimary,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 11),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(icon, color: context.appColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
