import 'package:coleggo/app/app.dart';
import 'package:coleggo/features/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('fresh launch restores into onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const ColeggoApp(),
      ),
    );
    expect(find.text('Coleggo'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Meet verified colleagues'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
