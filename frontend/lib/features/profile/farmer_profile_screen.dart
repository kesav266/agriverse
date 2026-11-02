import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/farm_land.dart';
import '../farms/crop_cycle_management_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/state_views.dart';
import '../../widgets/tts_button.dart';

/// Screen 3: Farmer Profile & Land Parcels Management Screen.
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Future<void> _editProfile() async {
    final state = context.read<AppStateProvider>();
    final profile = state.currentProfile;
    if (profile == null) return;
    final name = TextEditingController(text: profile.fullName);
    final village = TextEditingController(text: profile.village ?? '');
    final district = TextEditingController(text: profile.district);
    final region = TextEditingController(text: profile.state);
    final formKey = GlobalKey<FormState>();
    var saving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(state.tr('edit_profile')),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: state.tr('full_name'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? state.tr('enter_name')
                          : null,
                    ),
                    TextFormField(
                      controller: village,
                      decoration: InputDecoration(
                        labelText: state.tr('village_optional'),
                      ),
                    ),
                    TextFormField(
                      controller: district,
                      decoration: InputDecoration(
                        labelText: state.tr('district'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? state.tr('enter_district')
                          : null,
                    ),
                    TextFormField(
                      controller: region,
                      decoration: InputDecoration(labelText: state.tr('state')),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? state.tr('enter_state')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(state.tr('cancel')),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        setDialogState(() => saving = true);
                        final saved = await state.updatePersonalProfile({
                          'full_name': name.text.trim(),
                          'village': village.text.trim().isEmpty
                              ? null
                              : village.text.trim(),
                          'district': district.text.trim(),
                          'state': region.text.trim(),
                        });
                        if (!dialogContext.mounted) return;
                        if (saved) {
                          Navigator.pop(dialogContext);
                        } else {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.profileState.errorMessage ??
                                    'Could not update profile.',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(state.tr(saving ? 'saving' : 'save')),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      village.dispose();
      district.dispose();
      region.dispose();
    }
  }

  Future<void> _confirmDeleteFarm(BuildContext context, FarmLand farm) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(state.tr('delete_farm')),
        content: Text(state.tr('delete_farm_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(state.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(state.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await state.deleteFarm(farm.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? state.tr('farm_deleted')
              : state.farmsState.errorMessage ?? state.tr('farm_delete_failed'),
        ),
      ),
    );
  }

  void _showFarmDialog(BuildContext context, {FarmLand? farm}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: farm?.farmName ?? '');
    final areaCtrl = TextEditingController(
      text: farm?.landAreaAcres.toString() ?? '',
    );
    final surveyCtrl = TextEditingController(text: farm?.surveyNumber ?? '');
    String? selectedSoil = farm?.soilType;
    String? selectedIrrigation = farm?.irrigationSource;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appState.tr(
                              farm == null ? 'add_farm_land' : 'edit_farm',
                            ),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: nameCtrl,
                        label: appState.tr('farm_name'),
                        hint: appState.tr('enter_farm_name'),
                        prefixIcon: Icons.landscape_rounded,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? appState.tr('required_field')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: areaCtrl,
                              label: appState.tr('area_acres'),
                              hint: appState.tr('acres'),
                              prefixIcon: Icons.square_foot_rounded,
                              keyboardType: TextInputType.number,
                              validator: (val) =>
                                  val == null ||
                                      double.tryParse(val) == null ||
                                      double.parse(val) <= 0
                                  ? appState.tr('area_positive')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: surveyCtrl,
                              label: appState.tr('survey_number'),
                              hint: appState.tr('survey_number'),
                              prefixIcon: Icons.tag_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSoil,
                        decoration: InputDecoration(
                          labelText: appState.tr('soil_classification'),
                          prefixIcon: const Icon(
                            Icons.layers_rounded,
                            color: AppColors.emerald,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: ['Black Cotton', 'Red Sandy', 'Alluvial', 'Clay']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(_soilLabel(appState, s)),
                              ),
                            )
                            .toList(),
                        validator: (val) =>
                            val == null ? appState.tr('select_soil') : null,
                        onChanged: (val) =>
                            setModalState(() => selectedSoil = val),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedIrrigation,
                        decoration: InputDecoration(
                          labelText: appState.tr('irrigation_method'),
                          prefixIcon: const Icon(
                            Icons.water_drop_rounded,
                            color: AppColors.emerald,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: ['Borewell', 'Canal', 'Rainfed', 'Drip']
                            .map(
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text(_irrigationLabel(appState, i)),
                              ),
                            )
                            .toList(),
                        validator: (val) => val == null
                            ? appState.tr('select_irrigation')
                            : null,
                        onChanged: (val) =>
                            setModalState(() => selectedIrrigation = val),
                      ),
                      const SizedBox(height: 22),
                      AppButton(
                        text: saving
                            ? appState.tr('saving')
                            : farm == null
                            ? appState.tr('save_farm')
                            : appState.tr('save_changes'),
                        icon: Icons.check_circle_rounded,
                        expanded: true,
                        height: 50,
                        onPressed: saving
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                setModalState(() => saving = true);
                                final state = Provider.of<AppStateProvider>(
                                  context,
                                  listen: false,
                                );
                                final saved = farm == null
                                    ? await state.addFarm(
                                        FarmLand(
                                          id: '',
                                          farmerId: '',
                                          farmName: nameCtrl.text.trim(),
                                          landAreaAcres: double.parse(
                                            areaCtrl.text,
                                          ),
                                          soilType: selectedSoil!,
                                          irrigationSource: selectedIrrigation!,
                                          surveyNumber:
                                              surveyCtrl.text.trim().isEmpty
                                              ? null
                                              : surveyCtrl.text.trim(),
                                        ),
                                      )
                                    : await state.updateFarm(farm.id, {
                                        'farm_name': nameCtrl.text.trim(),
                                        'land_area_acres': double.parse(
                                          areaCtrl.text,
                                        ),
                                        'soil_type': selectedSoil!,
                                        'irrigation_source':
                                            selectedIrrigation!,
                                        'survey_number':
                                            surveyCtrl.text.trim().isEmpty
                                            ? null
                                            : surveyCtrl.text.trim(),
                                      });
                                if (!ctx.mounted) return;
                                if (saved) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        farm == null
                                            ? appState.tr('farm_saved')
                                            : appState.tr('farm_updated'),
                                      ),
                                    ),
                                  );
                                } else {
                                  setModalState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        state.farmsState.errorMessage ??
                                            appState.tr('farm_save_failed'),
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final profile = state.currentProfile;
    final farms = state.farms;

    final totalAcres = farms.fold<double>(0, (sum, f) => sum + f.landAreaAcres);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(state.tr('farmer_profile')),
        actions: [
          TtsButton(
            textToSpeak:
                '${state.tr('farmer_profile')}. ${profile?.fullName ?? state.tr('farmer')}. ${state.tr('registered_farms')}: ${farms.length}. ${state.tr('total_land')}: ${totalAcres.toStringAsFixed(1)} ${state.tr('acres')}.',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer Identity Profile Card
            HeroDarkCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeAccent,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? state.tr('farmer'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                    profile?.village,
                                    profile?.district,
                                    profile?.state,
                                  ]
                                  .whereType<String>()
                                  .where((value) => value.trim().isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.tr('mobile')}: ${profile?.phoneNumber ?? state.tr('not_available')}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: state.tr('edit_profile'),
                        onPressed: _editProfile,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricChip(
                          state.tr('total_land'),
                          '${totalAcres.toStringAsFixed(1)} ${state.tr('acres_short')}',
                        ),
                        _metricChip(
                          state.tr('fields'),
                          '${farms.length} ${state.tr('parcels')}',
                        ),
                        _metricChip(
                          state.tr('language_label'),
                          state.tr(switch (state.currentLanguage) {
                            'te' => 'telugu',
                            'hi' => 'hindi',
                            _ => 'english',
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 18),

            // Registered Farm Lands Header
            SectionHeader(
              title: state.tr('registered_farm_lands'),
              subtitle: state.tr('farm_details_subtitle'),
              trailing: AppButton(
                text: state.tr('add_farm'),
                icon: Icons.add_rounded,
                height: 38,
                variant: AppButtonVariant.primary,
                onPressed: () => _showFarmDialog(context),
              ),
            ),

            const SizedBox(height: 10),

            if (state.farmsState.isLoading)
              LoadingView(message: state.tr('loading_farms'))
            else if (state.farmsState.hasError)
              ErrorStateView(
                errorMessage:
                    state.farmsState.errorMessage ??
                    state.tr('farm_records_unavailable'),
                onRetry: state.loadDashboardData,
              )
            else if (farms.isEmpty)
              EmptyStateView(
                title: state.tr('no_farm_lands'),
                subtitle: state.tr('register_farm_help'),
                actionLabel: state.tr('register_farm'),
                onAction: () => _showFarmDialog(context),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: farms.length,
                itemBuilder: (context, idx) {
                  final farm = farms[idx];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.landscape_rounded,
                                color: AppColors.emerald,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farm.farmName,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (farm.surveyNumber != null &&
                                      farm.surveyNumber!.isNotEmpty) ...[
                                    Text(
                                      farm.surveyNumber!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            FarmStatusBadge(
                              label:
                                  '${farm.landAreaAcres} ${state.tr('acres')}',
                              icon: Icons.crop_square_rounded,
                              color: AppColors.emerald,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showFarmDialog(context, farm: farm);
                                } else if (action == 'delete') {
                                  _confirmDeleteFarm(context, farm);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(state.tr('edit_farm')),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(state.tr('delete_farm')),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _farmProperty(
                              state.tr('soil'),
                              _soilLabel(state, farm.soilType),
                              Icons.layers_rounded,
                            ),
                            _farmProperty(
                              state.tr('irrigation'),
                              _irrigationLabel(state, farm.irrigationSource),
                              Icons.water_drop_rounded,
                            ),
                            _farmProperty(
                              state.tr('survey_no'),
                              farm.surveyNumber ?? state.tr('registered'),
                              Icons.tag_rounded,
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CropCycleManagementScreen(farm: farm),
                                ),
                              );
                              if (context.mounted) {
                                await context
                                    .read<AppStateProvider>()
                                    .loadDashboardData();
                              }
                            },
                            icon: const Icon(Icons.grass_outlined),
                            label: Text(state.tr('manage_crop_cycles')),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms, delay: (idx * 50).ms);
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _farmProperty(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.emerald),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _soilLabel(AppStateProvider state, String value) =>
    switch (value.toLowerCase()) {
      'black cotton' || 'black cotton soil' => state.tr('soil_black'),
      'red sandy' || 'red sandy soil' => state.tr('soil_red'),
      'alluvial' || 'alluvial soil' => state.tr('soil_alluvial'),
      'clay' || 'clay soil' => state.tr('soil_clay'),
      _ => value,
    };

String _irrigationLabel(AppStateProvider state, String value) =>
    switch (value.toLowerCase()) {
      'borewell' => state.tr('irrigation_borewell'),
      'canal' => state.tr('irrigation_canal'),
      'rainfed' => state.tr('irrigation_rainfed'),
      'drip' => state.tr('irrigation_drip'),
      _ => value,
    };
