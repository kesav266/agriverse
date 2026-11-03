import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/health_diagnosis.dart';
import '../../widgets/app_card.dart';
import '../../widgets/main_drawer.dart';

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
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(state.tr('crop_health'))),
      drawer: const MainDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _cropController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: state.tr('crop_name'),
                    hintText: state.tr('enter_crop_image_hint'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? Text(state.tr('choose_clear_image'))
                      : Image.memory(
                          // The selected image is only uploaded for inference; the API does not retain it.
                          _imageBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Text(state.tr('preview_unavailable')),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(state.tr('take_photo')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(state.tr('upload_gallery')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _analyze,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    state.tr(_busy ? 'analyzing_image' : 'screen_image'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _MessageCard(message: _error!, error: true),
          ],
          if (_diagnosis != null) ...[
            const SizedBox(height: 12),
            _DiagnosisCard(
              diagnosis: _diagnosis!,
              language: context.read<AppStateProvider>().currentLanguage,
            ),
          ],
          const SizedBox(height: 12),
          _MessageCard(message: state.tr('diagnosis_caution')),
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
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnosis.detectedDisease,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${context.read<AppStateProvider>().tr('crop_prefix')}: ${diagnosis.cropName} · ${context.read<AppStateProvider>().tr('diagnosis_result')}: ${context.read<AppStateProvider>().tr(_severityKey(diagnosis.severity))}',
        ),
        if (diagnosis.confidenceScore != null)
          Text(
            '${context.read<AppStateProvider>().tr('confidence')}: ${(diagnosis.confidenceScore! * 100).toStringAsFixed(1)}%',
          ),
        if (diagnosis.topPredictions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Top model predictions'),
          for (final prediction in diagnosis.topPredictions)
            Text(
              '${prediction.label}: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
            ),
        ],
        const SizedBox(height: 12),
        Text(language == 'te' ? diagnosis.treatmentTe : diagnosis.treatmentEn),
      ],
    ),
  );
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
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Text(
      message,
      style: TextStyle(color: error ? AppColors.error : null),
    ),
  );
}
