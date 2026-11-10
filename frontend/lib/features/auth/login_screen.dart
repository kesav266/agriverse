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

/// Screen 2: Premium Modern Farmer Sign In Screen.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Forest Green Header Banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A2E1B), Color(0xFF134A2C), Color(0xFF185A36)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          Text(
                            state.tr('login'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance spacing
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeAccent,
                            width: 2.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco_rounded,
                            size: 34,
                            color: AppColors.limeAccent,
                          ),
                        ),
                      ).animate().scale(duration: 350.ms),
                      const SizedBox(height: 12),
                      Text(
                        state.tr('login'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.tr('sign_in_description'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Content
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        _ErrorNotice(message: _errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      AppCard(
                        padding: const EdgeInsets.all(22),
                        borderRadius: 24,
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
                            const SizedBox(height: 24),
                            AppButton(
                              text: state.tr('sign_in'),
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              expanded: true,
                              height: 52,
                              isPill: true,
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
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
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
                                color: AppColors.forestPine,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFB4AB)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
