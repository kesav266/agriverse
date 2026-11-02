import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  final _district = TextEditingController();
  final _state = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _simpleMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final state = context.read<AppStateProvider>();
    final success = await state.register(
      fullName: _name.text.trim(),
      phoneNumber: _phone.text.trim(),
      password: _password.text,
      village: _village.text.trim(),
      district: _district.text.trim(),
      state: _state.text.trim(),
      preferredLanguage: state.currentLanguage,
      simpleMode: _simpleMode,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } else {
      setState(() {
        _errorMessage =
            state.profileState.errorMessage ?? state.tr('registration_failed');
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _village.dispose();
    _district.dispose();
    _state.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(appState.tr('register'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 48,
                    color: AppColors.emerald,
                  ),
                ).animate().scale(duration: 350.ms),
                const SizedBox(height: 14),
                Text(
                  appState.tr('register'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appState.tr('register_description'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  _ErrorNotice(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                AppCard(
                  padding: const EdgeInsets.all(22),
                  borderRadius: 22,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _name,
                        label: appState.tr('full_name'),
                        hint: appState.tr('your_name'),
                        prefixIcon: Icons.badge_rounded,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? appState.tr('enter_full_name')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phone,
                        label: appState.tr('phone_number'),
                        hint: '+91 98765 43210',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                          return digits.length < 10 || digits.length > 15
                              ? appState.tr('valid_phone')
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _password,
                        label: appState.tr('password'),
                        hint: appState.tr('password_minimum'),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (value) => value == null || value.length < 12
                            ? appState.tr('password_too_short')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _confirmPassword,
                        label: appState.tr('confirm_password'),
                        hint: appState.tr('enter_password_again'),
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: true,
                        validator: (value) => value != _password.text
                            ? appState.tr('passwords_mismatch')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _village,
                        label: appState.tr('village'),
                        hint: appState.tr('village_optional'),
                        prefixIcon: Icons.location_city_rounded,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _district,
                        label: appState.tr('district'),
                        hint: appState.tr('district'),
                        prefixIcon: Icons.map_rounded,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? appState.tr('enter_district')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _state,
                        label: appState.tr('state'),
                        hint: appState.tr('state'),
                        prefixIcon: Icons.public_rounded,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? appState.tr('enter_state')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _simpleMode,
                        activeThumbColor: AppColors.emerald,
                        title: Text(appState.tr('simple_mode')),
                        subtitle: Text(appState.tr('simple_mode_on')),
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => _simpleMode = value),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        text: appState.tr('create_account'),
                        icon: Icons.check_circle_rounded,
                        isLoading: _isLoading,
                        expanded: true,
                        height: 50,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(appState.tr('login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;
  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.errorBorder),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
