import 'package:coleggo/data/models/app_state.dart';
import 'package:coleggo/data/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns fresh state when no local snapshot exists', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());

    final state = await service.load();

    expect(state.onboardingComplete, isFalse);
    expect(state.setupComplete, isFalse);
  });

  test('round-trips important prototype progress', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());
    const original = AppState(
      onboardingComplete: true,
      selectedWorkplaceId: 'northstar',
      selectedWorksiteId: 'central_exchange',
      workEmail: 'test@example.invalid',
      workplaceVerified: true,
      themePreference: AppThemePreference.dark,
      selectedTab: 2,
    );

    await service.save(original);
    final restored = await service.load();

    expect(restored.onboardingComplete, isTrue);
    expect(restored.selectedWorkplaceId, 'northstar');
    expect(restored.workplaceVerified, isTrue);
    expect(restored.themePreference, AppThemePreference.dark);
    expect(restored.selectedTab, 2);
  });

  test('malformed local state falls back safely', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageService.stateKey: '{not valid json',
    });
    final service = LocalStorageService(await SharedPreferences.getInstance());

    final state = await service.load();

    expect(state, isA<AppState>());
    expect(state.onboardingComplete, isFalse);
  });
}
