import 'package:flutter_test/flutter_test.dart';
import 'package:uz_license_plate_example/main.dart';

void main() {
  testWidgets('example app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const UzLicensePlateExampleApp());
    expect(find.text('uz_license_plate example'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });
}
