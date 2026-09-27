import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

// ── Signup form ───────────────────────────────────────────────────────────
class SignupForm extends StatefulWidget {
  const SignupForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(
    String fullName,
    String phoneNumber,
    String email,
    String password,
    String gender,
    String dateOfBirth,
  )
  onSubmit;
  final VoidCallback onLogin;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

// ── Signup form state ─────────────────────────────────────────────────────
class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _dateOfBirthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Submit handling ─────────────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await widget.onSubmit(
      _fullNameController.text.trim(),
      _phoneController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _gender ?? '',
      _dateOfBirthController.text.trim(),
    );
  }

  // ── iPhone-style pickers ─────────────────────────────────────────────────
  Future<void> _selectGender() async {
    FocusScope.of(context).unfocus();

    const genders = [
      (value: 'MALE', label: 'Male'),
      (value: 'FEMALE', label: 'Female'),
      (value: 'OTHER', label: 'Other'),
    ];
    var selectedIndex = _gender == null
        ? 0
        : genders.indexWhere((gender) => gender.value == _gender);
    if (selectedIndex < 0) selectedIndex = 0;

    final scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (pickerContext) => _CupertinoPickerSheet(
        title: 'Gender',
        onDone: () {
          final selectedGender = genders[selectedIndex];
          setState(() {
            _gender = selectedGender.value;
            _genderController.text = selectedGender.label;
          });
          Navigator.of(pickerContext).pop();
        },
        child: CupertinoPicker(
          key: const Key('signupGenderWheel'),
          scrollController: scrollController,
          itemExtent: 44,
          useMagnifier: true,
          magnification: 1.08,
          onSelectedItemChanged: (index) => selectedIndex = index,
          children: [
            for (final gender in genders)
              Center(
                child: Text(
                  gender.label,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    scrollController.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initialDate =
        DateTime.tryParse(_dateOfBirthController.text) ??
        DateTime(now.year - 18, now.month, now.day);
    var selectedDate = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (pickerContext) => _CupertinoPickerSheet(
        title: 'Date of Birth',
        onDone: () {
          setState(() {
            _dateOfBirthController.text =
                '${selectedDate.year.toString().padLeft(4, '0')}-'
                '${selectedDate.month.toString().padLeft(2, '0')}-'
                '${selectedDate.day.toString().padLeft(2, '0')}';
          });
          Navigator.of(pickerContext).pop();
        },
        child: CupertinoDatePicker(
          key: const Key('signupDateOfBirthWheel'),
          mode: CupertinoDatePickerMode.date,
          dateOrder: DatePickerDateOrder.mdy,
          initialDateTime: initialDate,
          minimumDate: DateTime(1900),
          maximumDate: now,
          onDateTimeChanged: (date) => selectedDate = date,
        ),
      ),
    );
  }

  // ── Form UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SignupField(
            label: 'Full Name',
            child: TextFormField(
              key: const Key('signupFullNameField'),
              controller: _fullNameController,
              enabled: !widget.isLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
          ),
          _SignupField(
            label: 'Phone Number',
            child: TextFormField(
              key: const Key('signupPhoneField'),
              controller: _phoneController,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Phone number is required';
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 8 || digits.length > 15) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
          ),
          _SignupField(
            label: 'Email',
            child: TextFormField(
              key: const Key('signupEmailField'),
              controller: _emailController,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
          ),
          _SignupField(
            label: 'Password',
            child: TextFormField(
              key: const Key('signupPasswordField'),
              controller: _passwordController,
              enabled: !widget.isLoading,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: widget.isLoading
                      ? null
                      : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Password is required';
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
          ),
          _SignupField(
            label: 'Confirm Password',
            child: TextFormField(
              key: const Key('signupConfirmPasswordField'),
              controller: _confirmPasswordController,
              enabled: !widget.isLoading,
              obscureText: _hideConfirmPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hideConfirmPassword
                      ? 'Show confirm password'
                      : 'Hide confirm password',
                  onPressed: widget.isLoading
                      ? null
                      : () => setState(
                          () => _hideConfirmPassword = !_hideConfirmPassword,
                        ),
                  icon: Icon(
                    _hideConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ),
          _SignupField(
            label: 'Gender (optional)',
            child: TextFormField(
              key: const Key('signupGenderField'),
              controller: _genderController,
              enabled: !widget.isLoading,
              readOnly: true,
              onTap: widget.isLoading ? null : _selectGender,
              decoration: const InputDecoration(
                hintText: 'Select your gender',
                prefixIcon: Icon(Icons.wc_outlined),
                suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
          ),
          _SignupField(
            label: 'Date of Birth (optional)',
            child: TextFormField(
              key: const Key('signupDateOfBirthField'),
              controller: _dateOfBirthController,
              enabled: !widget.isLoading,
              readOnly: true,
              onTap: widget.isLoading ? null : _selectDateOfBirth,
              decoration: const InputDecoration(
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),
          ),
          if (widget.errorMessage != null) ...[
            Container(
              key: const Key('signupError'),
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appColors.surface3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.errorMessage!,
                style: TextStyle(
                  color: context.appColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(
            height: 54,
            child: FilledButton(
              key: const Key('signUpButton'),
              onPressed: widget.isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: context.appColors.onPrimary,
                disabledBackgroundColor: context.appColors.primary.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: context.appColors.primary.withValues(alpha: 0.35),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      key: const Key('signupProgress'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: context.appColors.onPrimary,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              InkWell(
                key: const Key('signupLoginLink'),
                onTap: widget.isLoading ? null : widget.onLogin,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 2,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: context.appColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Signup field wrapper ──────────────────────────────────────────────────
class _SignupField extends StatelessWidget {
  const _SignupField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Cupertino picker bottom sheet ─────────────────────────────────────────
class _CupertinoPickerSheet extends StatelessWidget {
  const _CupertinoPickerSheet({
    required this.title,
    required this.onDone,
    required this.child,
  });

  final String title;
  final VoidCallback onDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;

    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.primary,
        scaffoldBackgroundColor: colors.surface,
      ),
      child: Container(
        height: 330,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 54,
                child: Row(
                  children: [
                    CupertinoButton(
                      key: Key('cancel$title-picker'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      key: Key('done$title-picker'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onPressed: onDone,
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: colors.border),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
