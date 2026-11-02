import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/app_state_provider.dart';
import '../core/theme/app_colors.dart';

/// Speaker Button Widget supporting Text-to-Speech (TTS) reading for accessibility.
class TtsButton extends StatelessWidget {
  final String textToSpeak;
  final double iconSize;
  final Color? color;

  const TtsButton({
    super.key,
    required this.textToSpeak,
    this.iconSize = 22.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    return IconButton(
      icon: Icon(
        Icons.volume_up_rounded,
        size: iconSize,
        color: color ?? AppColors.limeAccent,
      ),
      tooltip: state.tr('listen_speak'),
      onPressed: () async {
        final supported = await state.ttsService.isSupported();
        if (!context.mounted) return;

        if (supported) {
          await state.speakText(textToSpeak);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.tr('reading_aloud')} (${state.currentLanguage.toUpperCase()}): "$textToSpeak"',
              ),
              backgroundColor: AppColors.forestGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.tr('text_to_speech_unavailable')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
    );
  }
}
