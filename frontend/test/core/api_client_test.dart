import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/state/app_state_provider.dart';
import 'package:frontend/data/models/crop_cycle.dart';
import 'package:frontend/data/models/farm_observation.dart';

void main() {
  test('app state starts logged out without a demo farmer or farm', () {
    final state = AppStateProvider(autoLoad: false);
    expect(state.isLoggedIn, isFalse);
    expect(state.currentProfile, isNull);
    expect(state.farms, isEmpty);
    state.dispose();
  });

  test(
    'empty farm response remains empty and is not replaced with samples',
    () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await api.getFarms(), isEmpty);
      api.dispose();
    },
  );

  test(
    'provider/API failures surface as typed errors instead of fallback data',
    () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"error_code":"WEATHER_NOT_CONFIGURED","detail":"Weather provider is not configured."}',
            503,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        api.getWeather('Guntur'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
      api.dispose();
    },
  );

  test('login installs the returned bearer token for later requests', () async {
    var sawBearer = false;
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            '{"access_token":"test-session","token_type":"bearer","profile":{"id":"farmer-1","full_name":"Farmer One","phone_number":"+919999999999","village":null,"district":"Guntur","state":"Andhra Pradesh","preferred_language":"en","simple_mode_enabled":false}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        sawBearer = request.headers['authorization'] == 'Bearer test-session';
        return http.Response('{"id":"farmer-1"}', 200);
      }),
    );

    await api.login('+919999999999', password: 'FarmPassword#2026');
    await api.getMe();
    expect(sawBearer, isTrue);
    api.dispose();
  });

  test(
    'crop-cycle and observation calls use the authenticated paginated API',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'DELETE') return http.Response('', 204);
          if (request.method == 'GET') return http.Response('[]', 200);
          return http.Response(
            '{"id":"created-record"}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      )..setAuthToken('test-session');

      await api.getCropCycles('farm-1', skip: 50, limit: 25);
      await api.createCropCycle({
        'farm_id': 'farm-1',
        'crop_name': 'Paddy',
        'sowing_date': '2026-06-01',
      });
      await api.updateCropCycle('cycle-1', {'stage': 'Flowering'});
      await api.deleteCropCycle('cycle-1');
      await api.getFarmObservations('cycle-1', skip: 25, limit: 25);
      await api.createFarmObservation('cycle-1', {'notes': 'Field visit'});
      await api.updateFarmObservation('observation-1', {
        'notes': 'Updated visit',
      });
      await api.deleteFarmObservation('observation-1');

      expect(requests.map((request) => request.method), [
        'GET',
        'POST',
        'PATCH',
        'DELETE',
        'GET',
        'POST',
        'PATCH',
        'DELETE',
      ]);
      expect(requests[0].url.queryParameters, {'skip': '50', 'limit': '25'});
      expect(requests[4].url.queryParameters, {'skip': '25', 'limit': '25'});
      expect(
        requests.every(
          (request) =>
              request.headers['authorization'] == 'Bearer test-session',
        ),
        isTrue,
      );
      expect(requests[1].url.path, '/api/v1/crop-cycles');
      expect(requests[2].url.path, '/api/v1/crop-cycles/cycle-1');
      expect(
        requests[5].url.path,
        '/api/v1/farm-observations/crop-cycle/cycle-1',
      );
      expect(requests[6].url.path, '/api/v1/farm-observations/observation-1');
      api.dispose();
    },
  );

  test('observation response model reads database timestamps', () {
    final observation = FarmObservation.fromJson({
      'id': 'observation-1',
      'crop_cycle_id': 'cycle-1',
      'observation_date': '2026-06-15',
      'soil_moisture_percentage': 41.5,
      'pest_symptoms': null,
      'notes': 'Leaves healthy',
      'created_at': '2026-06-15T08:00:00Z',
      'updated_at': '2026-06-16T08:00:00Z',
    });

    expect(observation.cropCycleId, 'cycle-1');
    expect(observation.updatedAt, '2026-06-16T08:00:00Z');
  });

  test('crop-cycle response model reads server fields', () {
    final cycle = CropCycle.fromJson({
      'id': 'cycle-1',
      'farm_id': 'farm-1',
      'crop_name': 'Paddy',
      'variety': 'Sona Masuri',
      'sowing_date': '2026-06-01',
      'expected_harvest_date': '2026-10-01',
      'stage': 'Flowering',
      'status': 'Active',
      'created_at': '2026-06-01T08:00:00Z',
    });

    expect(cycle.farmId, 'farm-1');
    expect(cycle.expectedHarvestDate, '2026-10-01');
    expect(cycle.createdAt, '2026-06-01T08:00:00Z');
  });
}
