import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/state/app_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/welcome/welcome_language_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final state = AppStateProvider();
        state.onSessionExpired = () async {
          appNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeLanguageScreen()),
            (_) => false,
          );
        };
        return state;
      },
      child: const AgriVerseApp(),
    ),
  );
}

class AgriVerseApp extends StatelessWidget {
  const AgriVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'AgriVerse AI',
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(isSimpleMode: state.isSimpleMode),
          darkTheme: AppTheme.darkTheme(isSimpleMode: state.isSimpleMode),
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: state.isRestoringSession
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : state.isLoggedIn
              ? const DashboardScreen()
              : const WelcomeLanguageScreen(),
        );
      },
    );
  }
}
