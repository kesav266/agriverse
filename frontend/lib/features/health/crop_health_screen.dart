import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/health_diagnosis.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';

/// Screen 8: Premium Modern AI Crop Disease Diagnosis & Treatment Screen.
class CropHealthScreen extends StatefulWidget {
  const CropHealthScreen({super.key});

  @override
  State<CropHealthScreen> createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  final _picker = ImagePicker();
  final _cropController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  HealthDiagnosis? _diagnosis;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _error = null;
      _diagnosis = null;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _image = image;
            _imageBytes = bytes;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not open the selected image source. Check app permissions and try again.',
        );
      }
    }
  }

  String _mimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  Future<void> _analyze() async {
    final crop = _cropController.text.trim();
    if (_image == null || crop.isEmpty || _busy) {
      setState(
        () => _error = _image == null
            ? 'Choose or take a crop image first.'
            : 'Enter the crop name to continue.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _diagnosis = null;
    });
    final provider = context.read<AppStateProvider>();
    try {
      final bytes = await _image!.readAsBytes();
      final result = await provider.diagnoseCrop(
        imageBytes: bytes,
        fileName: _image!.name,
        mimeType: _mimeType(bytes),
        cropName: crop,
      );
      if (mounted) setState(() => _diagnosis = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(title: Text(state.tr('crop_health'))),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Crop Image Screening Card
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _cropController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: state.tr('crop_name'),
                    hintText: state.tr('enter_crop_image_hint'),
                    prefixIcon: const Icon(Icons.grass_rounded, color: AppColors.forestPine),
                  ),
                ),
                const SizedBox(height: 16),

                // Image Preview Box (matching modern card)
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF4F7F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE5),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.mistMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 36,
                                color: AppColors.forestPine,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.tr('choose_clear_image'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Text(state.tr('preview_unavailable')),
                        ),
                ),

                const SizedBox(height: 16),

                // Pick from Camera / Gallery Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(state.tr('take_photo')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(state.tr('upload_gallery')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Primary Analyze Pill Button
                AppButton(
                  text: state.tr(_busy ? 'analyzing_image' : 'screen_image'),
                  icon: Icons.search_rounded,
                  isLoading: _busy,
                  isPill: true,
                  height: 52,
                  onPressed: _busy ? null : _analyze,
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            _MessageCard(message: _error!, error: true),
          ],

          if (_diagnosis != null) ...[
            const SizedBox(height: 14),
            _DiagnosisCard(
              diagnosis: _diagnosis!,
              language: context.read<AppStateProvider>().currentLanguage,
            ),
          ],

          const SizedBox(height: 14),

          _MessageCard(message: state.tr('diagnosis_caution')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.diagnosis, required this.language});
  final HealthDiagnosis diagnosis;
  final String language;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateProvider>();
    final isHealthy = diagnosis.detectedDisease.toLowerCase().contains('healthy');
    final isHigh = diagnosis.severity.toLowerCase() == 'high';

    final Color statusColor = isHealthy
        ? AppColors.forestPine
        : (isHigh ? AppColors.error : AppColors.warning);

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  diagnosis.detectedDisease.replaceAll('___', ' — ').replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              FarmStatusBadge(
                label: state.tr(_severityKey(diagnosis.severity)),
                icon: isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.tr('crop_prefix')}: ${diagnosis.cropName}',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (diagnosis.confidenceScore != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: diagnosis.confidenceScore!,
                      backgroundColor: const Color(0xFFE5EDE7),
                      color: statusColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(diagnosis.confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
          if (diagnosis.topPredictions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Top model predictions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            for (final prediction in diagnosis.topPredictions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prediction.label.replaceAll('___', ' — ').replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.healing_rounded, size: 18, color: AppColors.forestPine),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  language == 'te' ? diagnosis.treatmentTe : diagnosis.treatmentEn,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _severityKey(String severity) => switch (severity.toLowerCase()) {
  'low' => 'severity_low',
  'moderate' => 'severity_moderate',
  'high' => 'severity_high',
  _ => 'severity_unknown',
};

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFEDEA) : const Color(0xFFF0F5F2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: error ? const Color(0xFFFFB4AB) : const Color(0xFFD4E3D9),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
          color: error ? AppColors.error : AppColors.forestPine,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: error ? AppColors.error : AppColors.textPrimary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
