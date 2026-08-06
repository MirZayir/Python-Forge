import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:python_forge/main.dart';

void main() {
  testWidgets('App compiles and renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // ProviderScope is required because PythonForgeApp is a ConsumerWidget.
    await tester.pumpWidget(const ProviderScope(child: PythonForgeApp()));

    // Verify that our root layout renders successfully.
    expect(find.text('Python Forge'), findsOneWidget);
  });
}
