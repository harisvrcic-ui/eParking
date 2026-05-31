import 'package:flutter_test/flutter_test.dart';
import 'package:eparking_desktop/main.dart';

void main() {
  testWidgets('Login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EParkingDesktopApp());
    expect(find.text('eParking Admin'), findsOneWidget);
    expect(find.text('Korisničko ime'), findsOneWidget);
    expect(find.text('Lozinka'), findsOneWidget);
  });
}
