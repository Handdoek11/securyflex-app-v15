import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';

void main() {
  group('Dutch Business Validation Tests', () {
    group('Postal Code Validation', () {
      test('should validate correct Dutch postal codes', () {
        expect(DutchBusinessValidation.isValidPostalCode('1234AB'), isTrue);
        expect(DutchBusinessValidation.isValidPostalCode('9999ZZ'), isTrue);
        expect(DutchBusinessValidation.isValidPostalCode('1012ab'), isTrue); // Case insensitive
      });

      test('should reject invalid Dutch postal codes', () {
        expect(DutchBusinessValidation.isValidPostalCode('12345'), isFalse);
        expect(DutchBusinessValidation.isValidPostalCode('ABCD12'), isFalse);
        expect(DutchBusinessValidation.isValidPostalCode('1234A'), isFalse);
        expect(DutchBusinessValidation.isValidPostalCode('12345AB'), isFalse);
        expect(DutchBusinessValidation.isValidPostalCode(''), isFalse);
      });

      test('should format postal codes correctly', () {
        expect(DutchBusinessValidation.formatPostalCode('1234ab'), equals('1234AB'));
        expect(DutchBusinessValidation.formatPostalCode('1234 AB'), equals('1234AB'));
        expect(DutchBusinessValidation.formatPostalCode('1234-AB'), equals('1234AB'));
        expect(DutchBusinessValidation.formatPostalCode('invalid'), equals('INVALID'));
      });
    });

    group('KvK Number Validation', () {
      test('should validate correct KvK numbers', () {
        expect(DutchBusinessValidation.isValidKvkNumber('12345678'), isTrue);
        expect(DutchBusinessValidation.isValidKvkNumber('87654321'), isTrue);
        expect(DutchBusinessValidation.isValidKvkNumber('12 34 56 78'), isTrue); // With spaces
        expect(DutchBusinessValidation.isValidKvkNumber('12.34.56.78'), isTrue); // With dots
      });

      test('should reject invalid KvK numbers', () {
        expect(DutchBusinessValidation.isValidKvkNumber('1234567'), isFalse); // Too short
        expect(DutchBusinessValidation.isValidKvkNumber('123456789'), isFalse); // Too long
        expect(DutchBusinessValidation.isValidKvkNumber('1234567A'), isFalse); // Contains letter
        expect(DutchBusinessValidation.isValidKvkNumber(''), isFalse);
      });

      test('should format KvK numbers correctly', () {
        expect(DutchBusinessValidation.formatKvkNumber('12345678'), equals('12 34 56 78'));
        expect(DutchBusinessValidation.formatKvkNumber('12 34 56 78'), equals('12 34 56 78'));
        expect(DutchBusinessValidation.formatKvkNumber('12.34.56.78'), equals('12 34 56 78'));
        expect(DutchBusinessValidation.formatKvkNumber('invalid'), equals('invalid'));
      });
    });

    group('Dutch Phone Number Validation', () {
      test('should validate correct Dutch phone numbers', () {
        expect(DutchBusinessValidation.isValidDutchPhone('0612345678'), isTrue); // Mobile
        expect(DutchBusinessValidation.isValidDutchPhone('0201234567'), isTrue); // Amsterdam landline
        expect(DutchBusinessValidation.isValidDutchPhone('+31612345678'), isTrue); // International mobile
        expect(DutchBusinessValidation.isValidDutchPhone('0031612345678'), isTrue); // International format
        expect(DutchBusinessValidation.isValidDutchPhone('06 12 34 56 78'), isTrue); // With spaces
      });

      test('should reject invalid Dutch phone numbers', () {
        expect(DutchBusinessValidation.isValidDutchPhone('061234567'), isFalse); // Too short
        expect(DutchBusinessValidation.isValidDutchPhone('06123456789'), isFalse); // Too long
        expect(DutchBusinessValidation.isValidDutchPhone('0012345678'), isFalse); // Invalid area code
        expect(DutchBusinessValidation.isValidDutchPhone('1234567890'), isFalse); // No country/area code
        expect(DutchBusinessValidation.isValidDutchPhone(''), isFalse);
      });

      test('should format Dutch phone numbers correctly', () {
        expect(DutchBusinessValidation.formatDutchPhone('0612345678'), equals('06 12 34 56 78'));
        expect(DutchBusinessValidation.formatDutchPhone('+31612345678'), equals('+31 6 12 34 56 78'));
        expect(DutchBusinessValidation.formatDutchPhone('0201234567'), equals('020 123 4567'));
        expect(DutchBusinessValidation.formatDutchPhone('invalid'), equals('invalid'));
      });
    });

    group('Dutch IBAN Validation', () {
      test('should validate correct Dutch IBAN numbers', () {
        expect(DutchBusinessValidation.isValidDutchIban('NL91ABNA0417164300'), isTrue);
        expect(DutchBusinessValidation.isValidDutchIban('NL02RABO0123456789'), isTrue);
        expect(DutchBusinessValidation.isValidDutchIban('nl91abna0417164300'), isTrue); // Case insensitive
      });

      test('should reject invalid Dutch IBAN numbers', () {
        expect(DutchBusinessValidation.isValidDutchIban('DE91ABNA0417164300'), isFalse); // German IBAN
        expect(DutchBusinessValidation.isValidDutchIban('NL91ABNA041716430'), isFalse); // Too short
        expect(DutchBusinessValidation.isValidDutchIban('NL91ABNA04171643001'), isFalse); // Too long
        expect(DutchBusinessValidation.isValidDutchIban(''), isFalse);
      });

      test('should format Dutch IBAN numbers correctly', () {
        expect(DutchBusinessValidation.formatDutchIban('NL91ABNA0417164300'), 
               equals('NL91 ABNA 0417 1643 00'));
        expect(DutchBusinessValidation.formatDutchIban('nl91abna0417164300'), 
               equals('NL91 ABNA 0417 1643 00'));
        expect(DutchBusinessValidation.formatDutchIban('invalid'), equals('INVALID'));
      });
    });

    group('Dutch BTW Number Validation', () {
      test('should validate correct Dutch BTW numbers', () {
        expect(DutchBusinessValidation.isValidBtwNumber('NL123456789B01'), isTrue);
        expect(DutchBusinessValidation.isValidBtwNumber('NL987654321B99'), isTrue);
        expect(DutchBusinessValidation.isValidBtwNumber('nl123456789b01'), isTrue); // Case insensitive
      });

      test('should reject invalid Dutch BTW numbers', () {
        expect(DutchBusinessValidation.isValidBtwNumber('DE123456789B01'), isFalse); // German format
        expect(DutchBusinessValidation.isValidBtwNumber('NL12345678B01'), isFalse); // Too short
        expect(DutchBusinessValidation.isValidBtwNumber('NL1234567890B01'), isFalse); // Too long
        expect(DutchBusinessValidation.isValidBtwNumber('NL123456789A01'), isFalse); // Wrong letter
        expect(DutchBusinessValidation.isValidBtwNumber(''), isFalse);
      });

      test('should format Dutch BTW numbers correctly', () {
        expect(DutchBusinessValidation.formatBtwNumber('NL123456789B01'), 
               equals('NL.123.456.7.89B.01'));
        expect(DutchBusinessValidation.formatBtwNumber('nl123456789b01'), 
               equals('NL.123.456.7.89B.01'));
        expect(DutchBusinessValidation.formatBtwNumber('invalid'), equals('INVALID'));
      });
    });

    group('Currency Formatting', () {
      test('should format euros correctly with Dutch locale', () {
        expect(DutchBusinessValidation.formatEuros(25.50), equals('€25,50'));
        expect(DutchBusinessValidation.formatEuros(1000.00), equals('€1000,00'));
        expect(DutchBusinessValidation.formatEuros(0.99), equals('€0,99'));
        expect(DutchBusinessValidation.formatEuros(15.0), equals('€15,00'));
      });
    });
  });
}
