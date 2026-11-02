import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_strings.dart';

void main() {
  test('English, Telugu, and Hindi static dictionaries are complete', () {
    expect(AppStrings.supportedLanguages, containsAll(['en', 'te', 'hi']));
    expect(AppStrings.missingTranslations('te'), isEmpty);
    expect(AppStrings.missingTranslations('hi'), isEmpty);
  });

  test('selected language resolves cycle and observation labels', () {
    expect(AppStrings.tr('add_crop_cycle', 'te'), isNot('Add crop cycle'));
    expect(AppStrings.tr('add_observation', 'hi'), isNot('Add observation'));
    expect(
      AppStrings.tr('no_active_crop_cycle', 'hi'),
      isNot('no_active_crop_cycle'),
    );
  });

  test(
    'English remains the fallback for unknown language and provider-only text',
    () {
      expect(AppStrings.tr('crop_health', 'en'), 'Crop health screening');
      expect(AppStrings.tr('unknown_key', 'hi'), 'unknown_key');
      expect(AppStrings.missingTranslations('unknown'), isNotEmpty);
    },
  );
}
