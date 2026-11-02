import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crop_cycle.dart';
import '../../data/models/farm_land.dart';
import '../../data/models/farm_observation.dart';
import '../../widgets/app_card.dart';
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
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(widget.cycle.cropName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editObservation(),
        icon: const Icon(Icons.add),
        label: Text(state.tr('add_observation')),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadObservations(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.farm.farmName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.tr('stage')}: ${_optionLabel(state, _stageKey(widget.cycle.stage), widget.cycle.stage)}',
                  ),
                  Text(
                    '${state.tr('status')}: ${_optionLabel(state, _statusKey(widget.cycle.status), widget.cycle.status)}',
                  ),
                  Text(
                    '${state.tr('sowing_date')}: ${widget.cycle.sowingDate}',
                  ),
                  if (widget.cycle.expectedHarvestDate != null)
                    Text(
                      '${state.tr('expected_harvest_date')}: ${widget.cycle.expectedHarvestDate}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.tr('field_observations'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
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
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              for (final observation in _observations)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(observation.observationDate),
                    subtitle: Text(
                      [
                        if (observation.soilMoisturePercentage != null)
                          '${state.tr('soil_moisture')}: ${observation.soilMoisturePercentage!.toStringAsFixed(1)}%',
                        if (observation.pestSymptoms?.isNotEmpty == true)
                          '${state.tr('pest_symptoms')}: ${observation.pestSymptoms}',
                        if (observation.notes?.isNotEmpty == true)
                          observation.notes!,
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    onTap: () => _editObservation(observation: observation),
                    trailing: IconButton(
                      tooltip: state.tr('delete'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteObservation(observation),
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
                        : const Icon(Icons.expand_more),
                    label: Text(state.tr('load_more')),
                  ),
                ),
            ],
          ],
        ),
      ),
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
