import 'package:flutter/material.dart';
import 'personal_assistant_screen.dart';

/// Legacy alias router forwarding to PersonalAssistantScreen.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonalAssistantScreen();
  }
}
