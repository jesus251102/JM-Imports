import 'package:flutter_test/flutter_test.dart';
import 'package:jm_imports/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App()),
    );
    // Basic smoke test - app should render without errors
    expect(find.byType(App), findsOneWidget);
  });
}
