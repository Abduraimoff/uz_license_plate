import 'package:flutter_test/flutter_test.dart';
import 'package:uz_license_plate/uz_license_plate.dart';

void main() {
  group('parseUzPlate', () {
    test('normalizes spaces and case', () {
      final r = parseUzPlate(' un 1234 ');
      expect(r?.normalized, 'UN1234');
      expect(r?.category, UzPlateCategory.diplomatic);
    });

    test('UN diplomatic', () {
      final r = parseUzPlate('UN1234');
      expect(r?.category, UzPlateCategory.diplomatic);
      expect(r?.format.diplomaticSingleField, isTrue);
      expect(r?.format.useVerticalDivider, isFalse);
    });

    test('CMD diplomatic', () {
      final r = parseUzPlate('CMD5678');
      expect(r?.category, UzPlateCategory.diplomatic);
    });

    test('taxi 01H pattern', () {
      final r = parseUzPlate('01H000069');
      expect(r?.category, UzPlateCategory.taxi);
      expect(r?.format.mainFlexLeadingStyle, PlateMainFlexLeadingStyle.truckTaxi);
    });

    test('electric yur', () {
      final r = parseUzPlate('12345ABEEEE');
      expect(r?.category, UzPlateCategory.electric);
      expect(r?.format.electricGreenRegion, isTrue);
    });

    test('unknown fallback', () {
      final r = parseUzPlate('???');
      expect(r?.category, UzPlateCategory.unknown);
    });

    test('empty returns null', () {
      expect(parseUzPlate(''), isNull);
      expect(parseUzPlate('   '), isNull);
    });
  });
}
