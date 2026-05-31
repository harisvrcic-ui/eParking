import 'package:flutter_test/flutter_test.dart';
import 'package:eparking_mobile/main.dart';

void main() {
  testWidgets('User home page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EParkingMobileApp());
    expect(find.text('eParking'), findsOneWidget);
  });
}
