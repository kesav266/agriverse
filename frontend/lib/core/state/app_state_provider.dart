import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/api_response.dart';
import '../localization/app_strings.dart';
import '../services/tts_service.dart';
import '../../data/models/crop_cycle.dart';
import '../../data/models/farm_land.dart';
import '../../data/models/farmer_profile.dart';
import '../../data/models/health_diagnosis.dart';
import '../../data/models/recommendation.dart';
import '../../data/models/weather_data.dart';
import '../../data/models/yield_estimate.dart';

class AppStateProvider extends ChangeNotifier {
  static const _tokenKey = 'agriverse_access_token';

  final ApiClient apiClient;
  final TtsService ttsService;
  final FlutterSecureStorage _secureStorage;

  bool _isLoggedIn = false;
  bool _isRestoringSession = false;
  bool _isDashboardLoading = false;
  bool _isSimpleMode = false;
  bool _isDarkMode = false;
  String _currentLanguage = 'en';
  FarmerProfile? _currentProfile;
  List<FarmLand> _farms = [];
  WeatherData? _weatherData;
  List<Recommendation> _recommendations = [];
  CropCycle? _activeCropCycle;
  Future<void> Function()? onSessionExpired;

  ApiResponse<FarmerProfile> profileState = ApiResponse.initial();
  ApiResponse<List<FarmLand>> farmsState = ApiResponse.initial();
  ApiResponse<WeatherData> weatherState = ApiResponse.initial();
  ApiResponse<List<Recommendation>> recommendationsState =
      ApiResponse.initial();
  ApiResponse<CropCycle?> activeCropCycleState = ApiResponse.initial();
  ApiResponse<YieldEstimate> yieldState = ApiResponse.initial();
  ApiResponse<HealthDiagnosis> diagnosisState = ApiResponse.initial();

  bool get isLoggedIn => _isLoggedIn;
  bool get isRestoringSession => _isRestoringSession;
  bool get isSimpleMode => _isSimpleMode;
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  FarmerProfile? get currentProfile => _currentProfile;
  List<FarmLand> get farms => List.unmodifiable(_farms);
  WeatherData? get weatherData => _weatherData;
  List<Recommendation> get recommendations =>
      List.unmodifiable(_recommendations);
  CropCycle? get activeCropCycle => _activeCropCycle;

  AppStateProvider({
    ApiClient? client,
    TtsService? tts,
    FlutterSecureStorage? secureStorage,
    bool autoLoad = true,
  }) : apiClient = client ?? ApiClient(),
       ttsService = tts ?? TtsService(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    apiClient.onUnauthorized = _handleSessionExpired;
    if (autoLoad) unawaited(restoreSession());
  }

  Future<void> restoreSession() async {
    _isRestoringSession = true;
    notifyListeners();
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return;
      apiClient.setAuthToken(token);
      final profile = FarmerProfile.fromJson(await apiClient.getMe());
      _applyProfile(profile);
      _isLoggedIn = true;
      await loadDashboardData();
    } on ApiException catch (error) {
      profileState = ApiResponse.error(error.message);
      if (error.statusCode == 401) {
        await _secureStorage.delete(key: _tokenKey);
        apiClient.clearAuthToken();
      }
    } catch (error) {
      profileState = ApiResponse.error(
        'Could not restore the saved session: $error',
      );
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    profileState = ApiResponse.loading();
    notifyListeners();
    try {
      final response = await apiClient.login(phone.trim(), password: password);
      final profile = FarmerProfile.fromJson(
        Map<String, dynamic>.from(response['profile'] as Map),
      );
      await _secureStorage.write(
        key: _tokenKey,
        value: response['access_token'] as String,
      );
      _applyProfile(profile);
      _isLoggedIn = true;
      profileState = ApiResponse.success(profile);
      await loadDashboardData();
      return true;
    } catch (error) {
      profileState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? village,
    required String district,
    String state = 'Andhra Pradesh',
    String preferredLanguage = 'en',
    bool simpleMode = false,
  }) async {
    profileState = ApiResponse.loading();
    notifyListeners();
    try {
      await apiClient.register({
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'village': village?.trim().isEmpty == true ? null : village?.trim(),
        'district': district.trim(),
        'state': state,
        'preferred_language': preferredLanguage,
        'simple_mode_enabled': simpleMode,
      });
      return login(phoneNumber, password);
    } catch (error) {
      profileState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    apiClient.clearAuthToken();
    await _secureStorage.delete(key: _tokenKey);
    _clearPrivateState();
    notifyListeners();
  }

  Future<void> _handleSessionExpired() async {
    await _secureStorage.delete(key: _tokenKey);
    _clearPrivateState();
    notifyListeners();
    await onSessionExpired?.call();
  }

  void _clearPrivateState() {
    _isLoggedIn = false;
    _currentProfile = null;
    _farms = [];
    _weatherData = null;
    _recommendations = [];
    _activeCropCycle = null;
    profileState = ApiResponse.initial();
    farmsState = ApiResponse.initial();
    weatherState = ApiResponse.initial();
    recommendationsState = ApiResponse.initial();
    activeCropCycleState = ApiResponse.initial();
  }

  void _applyProfile(FarmerProfile profile) {
    _currentProfile = profile;
    _currentLanguage = profile.preferredLanguage;
    _isSimpleMode = profile.simpleModeEnabled;
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (!{'en', 'te', 'hi'}.contains(language) ||
        _currentLanguage == language) {
      return;
    }
    _currentLanguage = language;
    notifyListeners();
    await _persistPreferences();
  }

  Future<void> toggleSimpleMode() async {
    _isSimpleMode = !_isSimpleMode;
    notifyListeners();
    await _persistPreferences();
  }

  Future<void> _persistPreferences() async {
    if (!_isLoggedIn) return;
    try {
      final json = await apiClient.updateProfile({
        'preferred_language': _currentLanguage,
        'simple_mode_enabled': _isSimpleMode,
      });
      _applyProfile(FarmerProfile.fromJson(json));
      profileState = ApiResponse.success(_currentProfile!);
    } catch (error) {
      profileState = ApiResponse.error(_errorMessage(error));
    }
    notifyListeners();
  }

  Future<bool> updatePersonalProfile(Map<String, dynamic> changes) async {
    if (!_isLoggedIn) return false;
    try {
      final updated = await apiClient.updateProfile(changes);
      _applyProfile(FarmerProfile.fromJson(updated));
      profileState = ApiResponse.success(_currentProfile!);
      notifyListeners();
      return true;
    } catch (error) {
      profileState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  String tr(String key) => AppStrings.tr(key, _currentLanguage);

  Future<void> speakText(String text) =>
      ttsService.speak(text, lang: _currentLanguage);

  Future<void> loadDashboardData() async {
    if (!_isLoggedIn || _isDashboardLoading) return;
    _isDashboardLoading = true;
    farmsState = ApiResponse.loading();
    weatherState = ApiResponse.loading();
    recommendationsState = ApiResponse.loading();
    activeCropCycleState = ApiResponse.loading();
    notifyListeners();

    try {
      final profileJson = await apiClient.getMe();
      _applyProfile(FarmerProfile.fromJson(profileJson));
      profileState = ApiResponse.success(_currentProfile!);
    } catch (error) {
      profileState = ApiResponse.error(_errorMessage(error));
      _isDashboardLoading = false;
      notifyListeners();
      return;
    }

    await Future.wait([_loadFarms(), _loadWeather()]);
    await _loadRecommendationsAndActiveCycle();
    _isDashboardLoading = false;
    notifyListeners();
  }

  Future<void> _loadFarms() async {
    try {
      final rows = await apiClient.getFarms();
      _farms = rows
          .map(
            (row) => FarmLand.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
      farmsState = ApiResponse.success(_farms);
    } catch (error) {
      _farms = [];
      farmsState = ApiResponse.error(_errorMessage(error));
    }
    notifyListeners();
  }

  Future<void> _loadWeather() async {
    _weatherData = null;
    try {
      final district = _currentProfile?.district;
      if (district == null || district.isEmpty) {
        throw const ApiException(
          statusCode: 422,
          message: 'Add a district to your profile to request local weather.',
        );
      }
      _weatherData = WeatherData.fromJson(await apiClient.getWeather(district));
      weatherState = ApiResponse.success(_weatherData!);
    } catch (error) {
      weatherState = ApiResponse.error(_errorMessage(error));
    }
    notifyListeners();
  }

  Future<void> _loadRecommendationsAndActiveCycle() async {
    _recommendations = [];
    _activeCropCycle = null;
    recommendationsState = ApiResponse.success(const []);
    if (farmsState.hasError) {
      activeCropCycleState = ApiResponse.error(
        farmsState.errorMessage ?? tr('connection_error'),
      );
      return;
    }
    if (_farms.isEmpty) {
      activeCropCycleState = ApiResponse.success(null);
      return;
    }
    try {
      final pages = await Future.wait(
        _farms.map((farm) => apiClient.getCropCycles(farm.id)),
      );
      final active =
          pages
              .expand((page) => page)
              .map(
                (row) =>
                    CropCycle.fromJson(Map<String, dynamic>.from(row as Map)),
              )
              .where((cycle) => cycle.status.toLowerCase() == 'active')
              .toList()
            ..sort(
              (left, right) => right.sowingDate.compareTo(left.sowingDate),
            );
      _activeCropCycle = active.isEmpty ? null : active.first;
      activeCropCycleState = ApiResponse.success(_activeCropCycle);
    } catch (error) {
      _activeCropCycle = null;
      activeCropCycleState = ApiResponse.error(_errorMessage(error));
    }
  }

  Future<bool> addFarm(FarmLand farm) async {
    try {
      final result = await apiClient.createFarm(farm.toCreateJson());
      _farms = [..._farms, FarmLand.fromJson(result)];
      farmsState = ApiResponse.success(_farms);
      notifyListeners();
      return true;
    } catch (error) {
      farmsState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFarm(String farmId, Map<String, dynamic> data) async {
    try {
      final updated = FarmLand.fromJson(
        await apiClient.updateFarm(farmId, data),
      );
      _farms = _farms
          .map((farm) => farm.id == farmId ? updated : farm)
          .toList();
      farmsState = ApiResponse.success(_farms);
      notifyListeners();
      return true;
    } catch (error) {
      farmsState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFarm(String farmId) async {
    try {
      await apiClient.deleteFarm(farmId);
      _farms = _farms.where((farm) => farm.id != farmId).toList();
      farmsState = ApiResponse.success(_farms);
      await _loadRecommendationsAndActiveCycle();
      notifyListeners();
      return true;
    } catch (error) {
      farmsState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      return false;
    }
  }

  Future<List<Recommendation>> evaluateRecommendations({
    required String soilType,
    required String season,
    required String availableWater,
    String? farmId,
  }) async {
    final response = await apiClient.evaluateCropRecommendations({
      'soil_type': soilType,
      'season': season,
      'available_water': availableWater,
      'farm_id': ?farmId,
    });
    return response
        .map(
          (row) =>
              Recommendation.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<YieldEstimate> calculateYield(Map<String, dynamic> payload) async {
    yieldState = ApiResponse.loading();
    notifyListeners();
    try {
      final estimate = YieldEstimate.fromJson(
        await apiClient.calculateYield(payload),
      );
      yieldState = ApiResponse.success(estimate);
      notifyListeners();
      return estimate;
    } catch (error) {
      yieldState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      rethrow;
    }
  }

  Future<HealthDiagnosis> diagnoseCrop({
    required List<int> imageBytes,
    required String fileName,
    required String mimeType,
    required String cropName,
  }) async {
    diagnosisState = ApiResponse.loading();
    notifyListeners();
    try {
      final diagnosis = HealthDiagnosis.fromJson(
        await apiClient.diagnoseCrop(
          imageBytes: imageBytes,
          fileName: fileName,
          mimeType: mimeType,
          cropName: cropName,
        ),
      );
      diagnosisState = ApiResponse.success(diagnosis);
      notifyListeners();
      return diagnosis;
    } catch (error) {
      diagnosisState = ApiResponse.error(_errorMessage(error));
      notifyListeners();
      rethrow;
    }
  }

  String _errorMessage(Object error) =>
      error is ApiException ? error.message : error.toString();

  @override
  void dispose() {
    apiClient.dispose();
    super.dispose();
  }
}
