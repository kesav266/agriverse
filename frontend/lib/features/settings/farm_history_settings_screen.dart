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

/// Screen 10: Farm History, Diagnostics & System Settings Screen.
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
        title: const Text(
          'Confirm Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.forestGreen,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your AgriVerse AI farmer profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(state.tr('farm_history_settings')),
        actions: [
          IconButton(
            onPressed: _reloadHistory,
            icon: const Icon(Icons.refresh),
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
            // Historical Crop Records Card
            SectionHeader(
              title: state.tr('farm_history'),
              subtitle: state.tr('yield_records_title'),
            ),
            AppCard(
              padding: const EdgeInsets.all(18.0),
              child: FutureBuilder<List<dynamic>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                    return Text(state.tr('no_saved_estimates'));
                  }
                  return Column(
                    children: history.map((raw) {
                      final row = Map<String, dynamic>.from(raw as Map);
                      final when = DateTime.tryParse(
                        row['calculated_at'] as String? ?? '',
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.agriculture_outlined,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row['crop_name'] as String? ??
                                        state.tr('crop_estimate'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${row['estimated_yield_quintals']} ${state.tr('quintals')} · ${when?.toLocal() ?? state.tr('date_unavailable')}',
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${state.tr('cost_label')} ₹${row['cost_of_cultivation_inr']}',
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

            const SizedBox(height: 18),

            // App Settings & Preferences
            SectionHeader(
              title: state.tr('app_configuration_title'),
              subtitle: state.tr('app_configuration_description'),
            ),
            AppCard(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.emerald,
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
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        color: AppColors.forestGreen,
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
                      activeThumbColor: AppColors.emerald,
                      onChanged: (_) => state.toggleSimpleMode(),
                    ),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0277BD).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: Color(0xFF0277BD),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      state.tr('backend_api_host'),
                      style: TextStyle(
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

            const SizedBox(height: 24),

            // Logout Action
            AppButton(
              text: state.tr('logout'),
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              expanded: true,
              height: 50,
              onPressed: () => _showLogoutDialog(context, state),
            ).animate().fadeIn(duration: 350.ms, delay: 150.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
