import 'package:flutter_test/flutter_test.dart';
import 'package:dino_food/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DinoFoodApp());
    expect(find.text('Dino_food'), findsNothing);
  });
}
