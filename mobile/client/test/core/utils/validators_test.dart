import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/utils/validators.dart';
import 'package:drpharma_client/core/validators/form_validators.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // Validators
  // ────────────────────────────────────────────────────────────────────────────
  group('Validators.isValidEmail', () {
    test('returns true for valid emails', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('user.name+tag@sub.domain.co'), isTrue);
      expect(Validators.isValidEmail('test-user@my-domain.org'), isTrue);
    });

    test('returns false for invalid emails', () {
      expect(Validators.isValidEmail('notanemail'), isFalse);
      expect(Validators.isValidEmail('@domain.com'), isFalse);
      expect(Validators.isValidEmail('user@'), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
    });
  });

  group('Validators.isValidPhone', () {
    test('returns true for valid ivorian numbers', () {
      expect(Validators.isValidPhone('+2250700000001'), isTrue);
      expect(Validators.isValidPhone('0700000001'), isTrue);
      expect(Validators.isValidPhone('+225 07 00 00 00 01'), isTrue);
    });

    test('returns false for invalid numbers', () {
      expect(Validators.isValidPhone('123'), isFalse);
      expect(Validators.isValidPhone(''), isFalse);
    });
  });

  group('Validators.isStrongPassword', () {
    test('returns true for password >= 8 chars', () {
      expect(Validators.isStrongPassword('12345678'), isTrue);
      expect(Validators.isStrongPassword('abcdefgh'), isTrue);
    });

    test('returns false for short passwords', () {
      expect(Validators.isStrongPassword('abc'), isFalse);
      expect(Validators.isStrongPassword('1234567'), isFalse);
    });
  });

  group('Validators.isValidOtp', () {
    test('returns true for 4-6 digits', () {
      expect(Validators.isValidOtp('1234'), isTrue);
      expect(Validators.isValidOtp('123456'), isTrue);
      expect(Validators.isValidOtp('12345'), isTrue);
    });

    test('returns false for invalid OTP', () {
      expect(Validators.isValidOtp('123'), isFalse);
      expect(Validators.isValidOtp('1234567'), isFalse);
      expect(Validators.isValidOtp('abcd'), isFalse);
      expect(Validators.isValidOtp(''), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // FormValidators
  // ────────────────────────────────────────────────────────────────────────────
  group('FormValidators.required', () {
    test('returns null for non-empty value', () {
      expect(FormValidators.required('hello'), isNull);
    });

    test('returns error for null or empty value', () {
      expect(FormValidators.required(null), isNotNull);
      expect(FormValidators.required(''), isNotNull);
      expect(FormValidators.required('   '), isNotNull);
    });

    test('uses custom fieldName in error message', () {
      final result = FormValidators.required('', fieldName: 'Prénom');
      expect(result, contains('Prénom'));
    });
  });

  group('FormValidators.email', () {
    test('returns null for valid email', () {
      expect(FormValidators.email('test@example.com'), isNull);
    });

    test('returns error for empty email', () {
      expect(FormValidators.email(''), isNotNull);
      expect(FormValidators.email(null), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(FormValidators.email('notanemail'), isNotNull);
      expect(FormValidators.email('@domain'), isNotNull);
    });

    test('validateEmail is an alias for email', () {
      expect(FormValidators.validateEmail('a@b.com'), isNull);
      expect(FormValidators.validateEmail('bad'), isNotNull);
    });
  });

  group('FormValidators.phone', () {
    test('returns null for valid phone', () {
      expect(FormValidators.phone('0700000001'), isNull);
    });

    test('returns error for empty phone', () {
      expect(FormValidators.phone(''), isNotNull);
      expect(FormValidators.phone(null), isNotNull);
    });

    test('returns error for too short/too long phone', () {
      expect(FormValidators.phone('123'), isNotNull);
      expect(FormValidators.phone('1234567890123456'), isNotNull);
    });

    test('validatePhone is an alias', () {
      expect(FormValidators.validatePhone('0700000001'), isNull);
    });
  });

  group('FormValidators.password', () {
    test('returns null for valid password', () {
      expect(FormValidators.password('12345678'), isNull);
    });

    test('returns error for empty password', () {
      expect(FormValidators.password(''), isNotNull);
      expect(FormValidators.password(null), isNotNull);
    });

    test('returns error for short password', () {
      expect(FormValidators.password('1234567'), isNotNull);
    });
  });

  group('FormValidators.validatePassword with strength', () {
    test('passes basic 8-char password at none/medium strength', () {
      expect(FormValidators.validatePassword('12345678'), isNull);
    });

    test('requires uppercase at strong strength', () {
      final result = FormValidators.validatePassword(
        'lowercase1',
        strength: PasswordStrength.strong,
      );
      expect(result, isNotNull);
      expect(result, contains('majuscule'));
    });

    test('requires digit at strong strength', () {
      final result = FormValidators.validatePassword(
        'NoDigitsHere',
        strength: PasswordStrength.strong,
      );
      expect(result, isNotNull);
      expect(result, contains('chiffre'));
    });

    test('passes strong password with uppercase and digit', () {
      expect(
        FormValidators.validatePassword(
          'Password1',
          strength: PasswordStrength.strong,
        ),
        isNull,
      );
    });
  });

  group('FormValidators.confirmPassword', () {
    test('returns null when passwords match', () {
      expect(FormValidators.confirmPassword('abc12345', 'abc12345'), isNull);
    });

    test('returns error when passwords do not match', () {
      expect(FormValidators.confirmPassword('abc12345', 'xyz12345'), isNotNull);
    });

    test('returns error for empty confirmation', () {
      expect(FormValidators.confirmPassword('', 'abc12345'), isNotNull);
    });

    test('validatePasswordConfirmation is alias', () {
      expect(
        FormValidators.validatePasswordConfirmation('match', 'match'),
        isNull,
      );
    });
  });

  group('FormValidators.name', () {
    test('returns null for valid name', () {
      expect(FormValidators.name('Alice'), isNull);
    });

    test('returns error for empty name', () {
      expect(FormValidators.name(''), isNotNull);
      expect(FormValidators.name(null), isNotNull);
    });

    test('returns error for single char name', () {
      expect(FormValidators.name('A'), isNotNull);
    });
  });

  group('FormValidators.validateName', () {
    test('returns null for valid input', () {
      expect(FormValidators.validateName('Bob'), isNull);
    });

    test('uses custom fieldName', () {
      final result = FormValidators.validateName(
        '',
        fieldName: 'Nom de famille',
      );
      expect(result, contains('Nom de famille'));
    });

    test('respects custom minLength', () {
      expect(FormValidators.validateName('ab', minLength: 5), isNotNull);
      expect(FormValidators.validateName('abcde', minLength: 5), isNull);
    });
  });

  group('FormValidators.validateAddress', () {
    test('returns null for valid address', () {
      expect(FormValidators.validateAddress('123 Rue de la Paix'), isNull);
    });

    test('returns error for short or empty address', () {
      expect(FormValidators.validateAddress(''), isNotNull);
      expect(FormValidators.validateAddress('abc'), isNotNull);
    });
  });

  group('FormValidators.minLength', () {
    test('returns null when length >= min', () {
      expect(FormValidators.minLength('hello', 3), isNull);
    });

    test('returns error when length < min', () {
      expect(FormValidators.minLength('hi', 5), isNotNull);
    });

    test('uses custom fieldName in error', () {
      final result = FormValidators.minLength(
        'ab',
        5,
        fieldName: 'Code postal',
      );
      expect(result, contains('Code postal'));
    });
  });

  group('FormValidators.otp', () {
    test('returns null for valid OTP', () {
      expect(FormValidators.otp('1234'), isNull);
      expect(FormValidators.otp('123456'), isNull);
    });

    test('returns error for invalid OTP', () {
      expect(FormValidators.otp(''), isNotNull);
      expect(FormValidators.otp('123'), isNotNull);
      expect(FormValidators.otp('abcd'), isNotNull);
    });
  });

  group('PasswordStrength enum', () {
    test('has 3 values', () {
      expect(PasswordStrength.values.length, 3);
      expect(PasswordStrength.values, contains(PasswordStrength.weak));
      expect(PasswordStrength.values, contains(PasswordStrength.medium));
      expect(PasswordStrength.values, contains(PasswordStrength.strong));
    });
  });
}
