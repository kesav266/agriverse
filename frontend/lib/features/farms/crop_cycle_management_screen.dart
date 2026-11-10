import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crop_cycle.dart';
import '../../data/models/farm_land.dart';
import '../../data/models/farm_observation.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/state_views.dart';

class CropCycleManagementScreen extends StatefulWidget {
  const CropCycleManagementScreen({super.key, required this.farm});

  final FarmLand farm;

  @override
  State<CropCycleManagementScreen> createState() =>
      _CropCycleManagementScreenState();
}

class _CropCycleManagementScreenState extends State<CropCycleManagementScreen> {
  static const _pageSize = 50;
  List<CropCycle> _cycles = const [];
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final rows = await context
          .read<AppStateProvider>()
          .apiClient
          .getCropCycles(
            widget.farm.id,
            skip: reset ? 0 : _cycles.length,
            limit: _pageSize,
          );
      if (!mounted) return;
      final page = rows
          .map(
            (row) => CropCycle.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
      setState(() {
        if (reset) _cycles = [];
        _cycles.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _displayError(error);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String _displayError(Object error) => error is ApiException
      ? error.message
      : context.read<AppStateProvider>().tr('connection_error');

  Future<void> _openDetails(CropCycle cycle) async {
    final state = context.read<AppStateProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CropCycleDetailsScreen(farm: widget.farm, cycle: cycle),
      ),
    );
    if (mounted) {
      await _loadCycles();
      await state.loadDashboardData();
    }
  }

  Future<void> _editCycle({CropCycle? cycle}) async {
    final state = context.read<AppStateProvider>();
    final crop = TextEditingController(text: cycle?.cropName ?? '');
    final variety = TextEditingController(text: cycle?.variety ?? '');
    final sowing = TextEditingController(
      text: cycle?.sowingDate ?? _isoDate(DateTime.now()),
    );
    final harvest = TextEditingController(
      text: cycle?.expectedHarvestDate ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var stage = cycle?.stage ?? 'Sowing';
    var status = cycle?.status ?? 'Active';
    var saving = false;
    String? formError;

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(
              state.tr(cycle == null ? 'add_crop_cycle' : 'edit_crop_cycle'),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: crop,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: state.tr('crop_name'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? state.tr('required_field')
                          : null,
                    ),
                    TextFormField(
                      controller: variety,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: state.tr('variety'),
                      ),
                    ),
                    _dateInput(
                      context: dialogContext,
                      controller: sowing,
                      label: state.tr('sowing_date'),
                      requiredField: true,
                    ),
                    _dateInput(
                      context: dialogContext,
                      controller: harvest,
                      label: state.tr('expected_harvest_date'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: stage,
                      decoration: InputDecoration(labelText: state.tr('stage')),
                      items: [..._stages, if (!_stages.contains(stage)) stage]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                _optionLabel(state, _stageKey(value), value),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => stage = value ?? stage),
                    ),
                    if (cycle != null) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: InputDecoration(
                          labelText: state.tr('status'),
                        ),
                        items:
                            [
                                  ..._statuses,
                                  if (!_statuses.contains(status)) status,
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(
                                      _optionLabel(
                                        state,
                                        _statusKey(value),
                                        value,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setDialogState(() => status = value ?? status),
                      ),
                    ],
                    if (formError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        formError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: Text(state.tr('cancel')),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final sowingDate = DateTime.tryParse(
                          sowing.text.trim(),
                        );
                        final harvestDate = harvest.text.trim().isEmpty
                            ? null
                            : DateTime.tryParse(harvest.text.trim());
                        if (sowingDate == null ||
                            (harvest.text.trim().isNotEmpty &&
                                harvestDate == null)) {
                          setDialogState(
                            () => formError = state.tr('invalid_date'),
                          );
                          return;
                        }
                        if (harvestDate != null &&
                            harvestDate.isBefore(sowingDate)) {
                          setDialogState(
                            () =>
                                formError = state.tr('date_after_sowing_error'),
                          );
                          return;
                        }
                        setDialogState(() {
                          saving = true;
                          formError = null;
                        });
                        final data = <String, dynamic>{
                          'crop_name': crop.text.trim(),
                          'variety': variety.text.trim().isEmpty
                              ? 'Standard'
                              : variety.text.trim(),
                          'sowing_date': _isoDate(sowingDate),
                          'expected_harvest_date': harvestDate == null
                              ? null
                              : _isoDate(harvestDate),
                          'stage': stage,
                          if (cycle != null) 'status': status,
                        };
                        try {
                          if (cycle == null) {
                            await state.apiClient.createCropCycle({
                              ...data,
                              'farm_id': widget.farm.id,
                            });
                          } else {
                            await state.apiClient.updateCropCycle(cycle.id, {
                              'crop_name': data['crop_name'],
                              'variety': data['variety'],
                              'sowing_date': data['sowing_date'],
                              'stage': stage,
                              'status': status,
                              'expected_harvest_date':
                                  data['expected_harvest_date'],
                            });
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              saving = false;
                              formError = _dialogError(state, error);
                            });
                          }
                        }
                      },
                child: Text(state.tr(saving ? 'saving' : 'save')),
              ),
            ],
          ),
        ),
      );
      if (saved == true && mounted) {
        await _loadCycles();
        await state.loadDashboardData();
      }
    } finally {
      crop.dispose();
      variety.dispose();
      sowing.dispose();
      harvest.dispose();
    }
  }

  Future<void> _deleteCycle(CropCycle cycle) async {
    final state = context.read<AppStateProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(state.tr('delete_crop_cycle')),
        content: Text(state.tr('confirm_delete_cycle')),
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
    if (confirmed != true || !mounted) return;
    try {
      await state.apiClient.deleteCropCycle(cycle.id);
      if (!mounted) return;
      await _loadCycles();
      await state.loadDashboardData();
      _showMessage(state.tr('crop_cycle_deleted'));
    } catch (error) {
      _showMessage(_displayError(error), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(state.tr('crop_cycles'))),
      drawer: const MainDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCycle(),
        icon: const Icon(Icons.add),
        label: Text(state.tr('add_crop_cycle')),
      ),
      body: _loading
          ? LoadingView(message: state.tr('loading'))
          : _error != null
          ? ErrorStateView(errorMessage: _error!, onRetry: _loadCycles)
          : _cycles.isEmpty
          ? EmptyStateView(
              title: state.tr('no_crop_cycles'),
              subtitle: state.tr('no_crop_cycles_help'),
              actionLabel: state.tr('add_crop_cycle'),
              onAction: () => _editCycle(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadCycles(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: ListTile(
                      leading: const Icon(Icons.landscape_outlined),
                      title: Text(widget.farm.farmName),
                      subtitle: Text(
                        '${widget.farm.landAreaAcres} ${state.tr('acres')} · ${widget.farm.soilType}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final cycle in _cycles)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.grass_outlined),
                        ),
                        title: Text(cycle.cropName),
                        subtitle: Text(
                          '${_optionLabel(state, _stageKey(cycle.stage), cycle.stage)} · ${_optionLabel(state, _statusKey(cycle.status), cycle.status)}\n${state.tr('sowing_date')}: ${cycle.sowingDate}',
                        ),
                        isThreeLine: true,
                        onTap: () => _openDetails(cycle),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') _editCycle(cycle: cycle);
                            if (action == 'delete') _deleteCycle(cycle);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(state.tr('edit')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(state.tr('delete')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (_hasMore)
                    Center(
                      child: TextButton.icon(
                        onPressed: _loadingMore
                            ? null
                            : () => _loadCycles(reset: false),
                        icon: _loadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          state.tr(_error == null ? 'load_more' : 'retry'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class CropCycleDetailsScreen extends StatefulWidget {
  const CropCycleDetailsScreen({
    super.key,
    required this.farm,
    required this.cycle,
  });

  final FarmLand farm;
  final CropCycle cycle;

  @override
  State<CropCycleDetailsScreen> createState() => _CropCycleDetailsScreenState();
}

class _CropCycleDetailsScreenState extends State<CropCycleDetailsScreen> {
  static const _pageSize = 50;
  final List<FarmObservation> _observations = [];
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadObservations(reset: true);
  }

  Future<void> _loadObservations({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final rows = await context
          .read<AppStateProvider>()
          .apiClient
          .getFarmObservations(
            widget.cycle.id,
            skip: reset ? 0 : _observations.length,
            limit: _pageSize,
          );
      if (!mounted) return;
      final page = rows
          .map(
            (row) =>
                FarmObservation.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
      setState(() {
        if (reset) _observations.clear();
        _observations.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : context.read<AppStateProvider>().tr('connection_error');
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _editObservation({FarmObservation? observation}) async {
    final state = context.read<AppStateProvider>();
    final date = TextEditingController(
      text: observation?.observationDate ?? _isoDate(DateTime.now()),
    );
    final moisture = TextEditingController(
      text: observation?.soilMoisturePercentage?.toString() ?? '',
    );
    final pests = TextEditingController(text: observation?.pestSymptoms ?? '');
    final notes = TextEditingController(text: observation?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;
    String? errorText;
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(
              state.tr(
                observation == null ? 'add_observation' : 'edit_observation',
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dateInput(
                      context: dialogContext,
                      controller: date,
                      label: state.tr('observation_date'),
                      requiredField: true,
                    ),
                    TextFormField(
                      controller: moisture,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: state.tr('soil_moisture'),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final parsed = double.tryParse(value.trim());
                        return parsed == null || parsed < 0 || parsed > 100
                            ? state.tr('moisture_range')
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: pests,
                      maxLines: 2,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: state.tr('pest_symptoms'),
                      ),
                    ),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      maxLength: 4000,
                      decoration: InputDecoration(
                        labelText: state.tr('field_notes'),
                      ),
                    ),
                    if (errorText != null)
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: Text(state.tr('cancel')),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final parsedDate = DateTime.tryParse(date.text.trim());
                        if (parsedDate == null) {
                          setDialogState(
                            () => errorText = state.tr('invalid_date'),
                          );
                          return;
                        }
                        setDialogState(() {
                          saving = true;
                          errorText = null;
                        });
                        final payload = <String, dynamic>{
                          'observation_date': _isoDate(parsedDate),
                          'soil_moisture_percentage':
                              moisture.text.trim().isEmpty
                              ? null
                              : double.parse(moisture.text.trim()),
                          'pest_symptoms': pests.text.trim().isEmpty
                              ? null
                              : pests.text.trim(),
                          'notes': notes.text.trim().isEmpty
                              ? null
                              : notes.text.trim(),
                        };
                        try {
                          if (observation == null) {
                            await state.apiClient.createFarmObservation(
                              widget.cycle.id,
                              payload,
                            );
                          } else {
                            await state.apiClient.updateFarmObservation(
                              observation.id,
                              payload,
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              saving = false;
                              errorText = error is ApiException
                                  ? error.message
                                  : state.tr('connection_error');
                            });
                          }
                        }
                      },
                child: Text(state.tr(saving ? 'saving' : 'save')),
              ),
            ],
          ),
        ),
      );
      if (saved == true && mounted) await _loadObservations(reset: true);
    } finally {
      date.dispose();
      moisture.dispose();
      pests.dispose();
      notes.dispose();
    }
  }

  Future<void> _deleteObservation(FarmObservation observation) async {
    final state = context.read<AppStateProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(state.tr('delete_observation')),
        content: Text(state.tr('confirm_delete_observation')),
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
    if (confirmed != true) return;
    try {
      await state.apiClient.deleteFarmObservation(observation.id);
      if (mounted) await _loadObservations(reset: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : state.tr('connection_error'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(widget.cycle.cropName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: state.tr('refresh'),
            onPressed: () => _loadObservations(reset: true),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AppButton(
            text: state.tr('add_observation'),
            icon: Icons.add_circle_outline_rounded,
            isPill: true,
            height: 52,
            expanded: true,
            onPressed: () => _editObservation(),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.forestPine,
        onRefresh: () => _loadObservations(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Crop Hero Detail Card (inspired by Image Screen 2)
            AppCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.mistMint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.forestPine,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.farm.farmName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textHeadline,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.tr('variety')}: ${widget.cycle.variety}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FarmStatusBadge(
                        label: _optionLabel(state, _statusKey(widget.cycle.status), widget.cycle.status),
                        icon: Icons.check_circle_rounded,
                        color: AppColors.forestPine,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cycleMetric(
                        state.tr('stage'),
                        _optionLabel(state, _stageKey(widget.cycle.stage), widget.cycle.stage),
                        Icons.spa_rounded,
                      ),
                      _cycleMetric(
                        state.tr('sowing_date'),
                        widget.cycle.sowingDate,
                        Icons.calendar_today_rounded,
                      ),
                      if (widget.cycle.expectedHarvestDate != null)
                        _cycleMetric(
                          state.tr('expected_harvest_date'),
                          widget.cycle.expectedHarvestDate!,
                          Icons.event_available_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Notes / Field Observations Section (matching Image Screen 3)
            SectionHeader(
              title: state.tr('field_observations'),
              subtitle: 'Timeline of pest symptoms, soil moisture, and notes',
            ),

            const SizedBox(height: 6),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _observations.isEmpty)
              ErrorStateView(
                errorMessage: _error!,
                onRetry: () => _loadObservations(reset: true),
              )
            else if (_observations.isEmpty)
              EmptyStateView(
                title: state.tr('no_observations'),
                subtitle: state.tr('no_observations_help'),
                actionLabel: state.tr('add_observation'),
                onAction: () => _editObservation(),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                ),
              for (final observation in _observations)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoalSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE7),
                    ),
                    boxShadow: isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x080D3D22),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                  ),
                  child: InkWell(
                    onTap: () => _editObservation(observation: observation),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Thumbnail Icon
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.mistMint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.forestPine,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    observation.observationDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: state.tr('delete'),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => _deleteObservation(observation),
                                  ),
                                ],
                              ),
                              if (observation.soilMoisturePercentage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${state.tr('soil_moisture')}: ${observation.soilMoisturePercentage!.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.forestPine,
                                  ),
                                ),
                              ],
                              if (observation.pestSymptoms?.isNotEmpty == true) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${state.tr('pest_symptoms')}: ${observation.pestSymptoms}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (observation.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  observation.notes!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_hasMore)
                Center(
                  child: TextButton.icon(
                    onPressed: _loadingMore
                        ? null
                        : () => _loadObservations(reset: false),
                    icon: _loadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(state.tr('load_more')),
                  ),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _cycleMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.forestPine),
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
                fontSize: 12.5,
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

const _stages = [
  'Sowing',
  'Germination',
  'Vegetative',
  'Flowering',
  'Fruiting',
  'Maturity',
  'Harvesting',
  'Completed',
];
const _statuses = ['Active', 'Completed', 'Cancelled', 'Abandoned'];

String _stageKey(String value) => 'stage_${value.toLowerCase()}';
String _statusKey(String value) => 'status_${value.toLowerCase()}';
String _optionLabel(AppStateProvider state, String key, String fallback) {
  final translated = state.tr(key);
  return translated == key ? fallback : translated;
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final current = DateTime.tryParse(controller.text) ?? DateTime.now();
  final selected = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(1950),
    lastDate: DateTime(2100),
  );
  if (selected != null) controller.text = _isoDate(selected);
}

Widget _dateInput({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  bool requiredField = false,
}) {
  final state = context.read<AppStateProvider>();
  return TextFormField(
    controller: controller,
    readOnly: true,
    onTap: () => _selectDate(context, controller),
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: const Icon(Icons.calendar_today_outlined),
    ),
    validator: requiredField
        ? (value) => value == null || DateTime.tryParse(value.trim()) == null
              ? state.tr('required_field')
              : null
        : null,
  );
}

String _dialogError(AppStateProvider state, Object error) =>
    error is ApiException ? error.message : state.tr('connection_error');
