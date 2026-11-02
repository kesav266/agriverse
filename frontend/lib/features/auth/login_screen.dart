import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final state = context.read<AppStateProvider>();
    final success = await state.login(
      _phoneController.text.trim(),
      _passwordController.text,
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
            state.profileState.errorMessage ?? state.tr('login_failed');
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(state.tr('login'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Center(
                  child: Icon(
                    Icons.eco_rounded,
                    size: 54,
                    color: AppColors.emerald,
                  ),
                ).animate().scale(duration: 350.ms),
                const SizedBox(height: 16),
                Text(
                  state.tr('login'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.tr('sign_in_description'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  _ErrorNotice(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                AppCard(
                  padding: const EdgeInsets.all(22),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _phoneController,
                        label: state.tr('phone_number'),
                        hint: '+91 98765 43210',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                          return digits.length < 10 || digits.length > 15
                              ? state.tr('valid_phone')
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: state.tr('password'),
                        hint: state.tr('enter_password'),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? state.tr('enter_password')
                            : null,
                        onSubmitted: (_) => _submitLogin(),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        text: state.tr('sign_in'),
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        expanded: true,
                        height: 50,
                        onPressed: _submitLogin,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.tr('no_account_yet'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                      child: Text(
                        state.tr('register'),
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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
