import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';
import '../auth/login_screen.dart';

/// Screen 12: Premium Modern Farm History, Diagnostics & System Settings Screen.
class FarmHistorySettingsScreen extends StatefulWidget {
  const FarmHistorySettingsScreen({super.key});

  @override
  State<FarmHistorySettingsScreen> createState() =>
      _FarmHistorySettingsScreenState();
}

class _FarmHistorySettingsScreenState extends State<FarmHistorySettingsScreen> {
  Future<List<dynamic>>? _historyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyFuture ??= context
        .read<AppStateProvider>()
        .apiClient
        .getYieldHistory();
  }

  void _reloadHistory() {
    setState(
      () => _historyFuture = context
          .read<AppStateProvider>()
          .apiClient
          .getYieldHistory(),
    );
  }

  void _showLogoutDialog(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Confirm Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.forestPine,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your AgriVerse AI farmer profile?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(state.tr('farm_history_settings')),
        actions: [
          IconButton(
            onPressed: _reloadHistory,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: state.tr('refresh_history'),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Historical Crop Records Section
            SectionHeader(
              title: state.tr('farm_history'),
              subtitle: state.tr('yield_records_title'),
            ),
            const SizedBox(height: 4),
            AppCard(
              padding: const EdgeInsets.all(18.0),
              borderRadius: 22.0,
              child: FutureBuilder<List<dynamic>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: AppColors.error),
                        ),
                        TextButton(
                          onPressed: _reloadHistory,
                          child: Text(state.tr('retry')),
                        ),
                      ],
                    );
                  }
                  final history = snapshot.data ?? const [];
                  if (history.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          state.tr('no_saved_estimates'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: history.map((raw) {
                      final row = Map<String, dynamic>.from(raw as Map);
                      final when = DateTime.tryParse(
                        row['calculated_at'] as String? ?? '',
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF9FAF8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.mistMint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.agriculture_rounded,
                                color: AppColors.forestPine,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row['crop_name'] as String? ??
                                        state.tr('crop_estimate'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${row['estimated_yield_quintals']} ${state.tr('quintals')} · ${when != null ? "${when.toLocal().day}/${when.toLocal().month}/${when.toLocal().year}" : state.tr('date_unavailable')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${row['projected_net_profit_inr']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.forestPine,
                                  ),
                                ),
                                Text(
                                  '${state.tr('cost_label')} ₹${row['cost_of_cultivation_inr']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 22),

            // App Settings & Preferences
            SectionHeader(
              title: state.tr('app_configuration_title'),
              subtitle: state.tr('app_configuration_description'),
            ),
            const SizedBox(height: 4),
            AppCard(
              padding: const EdgeInsets.all(18.0),
              borderRadius: 22.0,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mistMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.forestPine,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      state.tr('select_language'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      state.tr(switch (state.currentLanguage) {
                        'te' => 'telugu',
                        'hi' => 'hindi',
                        _ => 'english',
                      }),
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: DropdownButton<String>(
                      value: state.currentLanguage,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(state.tr('english')),
                        ),
                        DropdownMenuItem(
                          value: 'te',
                          child: Text(state.tr('telugu')),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Text(state.tr('hindi')),
                        ),
                      ],
                      onChanged: (language) {
                        if (language != null) state.setLanguage(language);
                      },
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        color: AppColors.forestPine,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      state.tr('simple_mode'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      state.tr('simple_mode_on'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Switch(
                      value: state.isSimpleMode,
                      activeThumbColor: AppColors.forestPine,
                      onChanged: (_) => state.toggleSimpleMode(),
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: Color(0xFF0284C7),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      state.tr('backend_api_host'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      state.apiClient.effectiveBaseUrl,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 100.ms),

            const SizedBox(height: 26),

            // Logout Action Button
            AppButton(
              text: state.tr('logout'),
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              expanded: true,
              isPill: true,
              height: 52,
              onPressed: () => _showLogoutDialog(context, state),
            ).animate().fadeIn(duration: 350.ms, delay: 150.ms),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
