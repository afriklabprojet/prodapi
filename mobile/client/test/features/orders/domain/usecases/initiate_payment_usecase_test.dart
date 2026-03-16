import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/orders/domain/usecases/initiate_payment_usecase.dart';
import 'package:drpharma_client/features/orders/domain/repositories/orders_repository.dart';

@GenerateMocks([OrdersRepository])
import 'initiate_payment_usecase_test.mocks.dart';

void main() {
  late InitiatePaymentUseCase useCase;
  late MockOrdersRepository mockRepository;

  setUp(() {
    mockRepository = MockOrdersRepository();
    useCase = InitiatePaymentUseCase(mockRepository);
  });

  group('InitiatePaymentUseCase', () {
    final testPaymentResponse = {
      'payment_id': 123,
      'payment_url': 'https://payment.jeko.com/pay/123',
      'status': 'pending',
      'amount': 5500.0,
    };

    test('should initiate payment successfully with jeko provider', () async {
      // Arrange
      when(mockRepository.initiatePayment(
        orderId: 1,
        provider: 'jeko',
      )).thenAnswer((_) async => Right(testPaymentResponse));

      // Act
      final result = await useCase.call(orderId: 1, provider: 'jeko');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (response) {
          expect(response['payment_id'], 123);
          expect(response['payment_url'], isNotEmpty);
          expect(response['status'], 'pending');
        },
      );
      verify(mockRepository.initiatePayment(
        orderId: 1,
        provider: 'jeko',
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      when(mockRepository.initiatePayment(
        orderId: 1,
        provider: 'jeko',
      )).thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // Act
      final result = await useCase.call(orderId: 1, provider: 'jeko');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return failure when order not found', () async {
      // Arrange
      when(mockRepository.initiatePayment(
        orderId: 999,
        provider: 'jeko',
      )).thenAnswer((_) async => const Left(ServerFailure(message: 'Order not found')));

      // Act
      final result = await useCase.call(orderId: 999, provider: 'jeko');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    group('Validation - orderId', () {
      test('should return validation failure for orderId <= 0', () async {
        // Act
        final result = await useCase.call(orderId: 0, provider: 'jeko');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors['orderId'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
        verifyNever(mockRepository.initiatePayment(
          orderId: anyNamed('orderId'),
          provider: anyNamed('provider'),
        ));
      });

      test('should return validation failure for negative orderId', () async {
        // Act
        final result = await useCase.call(orderId: -1, provider: 'jeko');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should be Left'),
        );
      });

      test('should return validation failure for orderId -100', () async {
        // Act
        final result = await useCase.call(orderId: -100, provider: 'jeko');

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('Validation - provider', () {
      test('should return validation failure for empty provider', () async {
        // Act
        final result = await useCase.call(orderId: 1, provider: '');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors['provider'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return validation failure for whitespace-only provider', () async {
        // Act
        final result = await useCase.call(orderId: 1, provider: '   ');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should be Left'),
        );
      });

      test('should return validation failure for unsupported provider', () async {
        // Act
        final result = await useCase.call(orderId: 1, provider: 'paypal');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors['provider'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return validation failure for unsupported provider', () async {
        // Act
        final result = await useCase.call(orderId: 1, provider: 'unknown_provider');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should be Left'),
        );
      });

      test('should accept jeko provider (lowercase)', () async {
        // Arrange
        when(mockRepository.initiatePayment(
          orderId: 1,
          provider: 'jeko',
        )).thenAnswer((_) async => Right(testPaymentResponse));

        // Act
        final result = await useCase.call(orderId: 1, provider: 'jeko');

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept Jeko provider (case insensitive)', () async {
        // Arrange
        when(mockRepository.initiatePayment(
          orderId: 1,
          provider: 'Jeko',
        )).thenAnswer((_) async => Right(testPaymentResponse));

        // Act
        final result = await useCase.call(orderId: 1, provider: 'Jeko');

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept JEKO provider (uppercase)', () async {
        // Arrange
        when(mockRepository.initiatePayment(
          orderId: 1,
          provider: 'JEKO',
        )).thenAnswer((_) async => Right(testPaymentResponse));

        // Act
        final result = await useCase.call(orderId: 1, provider: 'JEKO');

        // Assert
        expect(result.isRight(), isTrue);
      });
    });

    group('Multiple validations', () {
      test('should return validation failure for both invalid orderId and provider', () async {
        // Act (orderId validation should fail first)
        final result = await useCase.call(orderId: 0, provider: '');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should be Left'),
        );
      });
    });
  });
}
