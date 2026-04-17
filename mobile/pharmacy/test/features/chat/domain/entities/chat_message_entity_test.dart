import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/chat/domain/entities/chat_message_entity.dart';

void main() {
  group('ChatMessageEntity', () {
    late ChatMessageEntity message;

    setUp(() {
      message = ChatMessageEntity(
        id: 1,
        message: 'Hello, this is a test message',
        senderType: SenderType.pharmacy,
        senderId: 100,
        isMine: true,
        readAt: DateTime(2024, 3, 10, 10, 35),
        createdAt: DateTime(2024, 3, 10, 10, 30),
      );
    });

    test('should create ChatMessageEntity with all fields', () {
      expect(message.id, 1);
      expect(message.message, 'Hello, this is a test message');
      expect(message.senderType, SenderType.pharmacy);
      expect(message.senderId, 100);
      expect(message.isMine, true);
      expect(message.readAt, isNotNull);
    });

    test('isRead should return true when readAt is set', () {
      expect(message.isRead, true);
    });

    test('isRead should return false when readAt is null', () {
      final unreadMessage = ChatMessageEntity(
        id: 2,
        message: 'Unread message',
        senderType: SenderType.courier,
        senderId: 200,
        isMine: false,
        createdAt: DateTime.now(),
      );
      expect(unreadMessage.isRead, false);
    });

    test('timeFormatted should return HH:mm format', () {
      expect(message.timeFormatted, '10:30');
    });

    test('timeFormatted should pad single digit hours and minutes', () {
      final earlyMessage = ChatMessageEntity(
        id: 3,
        message: 'Early message',
        senderType: SenderType.customer,
        senderId: 300,
        isMine: false,
        createdAt: DateTime(2024, 3, 10, 5, 8),
      );
      expect(earlyMessage.timeFormatted, '05:08');
    });

    test('copyWith should create a new entity with modified fields', () {
      final modified = message.copyWith(
        message: 'Modified message',
        isMine: false,
      );

      expect(modified.id, message.id);
      expect(modified.message, 'Modified message');
      expect(modified.isMine, false);
      expect(modified.senderType, message.senderType);
    });
  });

  group('SenderType', () {
    test('should have all expected values', () {
      expect(SenderType.values.length, 4);
      expect(SenderType.values, contains(SenderType.pharmacy));
      expect(SenderType.values, contains(SenderType.courier));
      expect(SenderType.values, contains(SenderType.customer));
      expect(SenderType.values, contains(SenderType.unknown));
    });
  });

  group('SenderType Extension toSenderType', () {
    test('should convert string to SenderType', () {
      expect('pharmacy'.toSenderType(), SenderType.pharmacy);
      expect('courier'.toSenderType(), SenderType.courier);
      expect('customer'.toSenderType(), SenderType.customer);
      expect('unknown'.toSenderType(), SenderType.unknown);
    });

    test('should be case insensitive', () {
      expect('PHARMACY'.toSenderType(), SenderType.pharmacy);
      expect('Courier'.toSenderType(), SenderType.courier);
      expect('CUSTOMER'.toSenderType(), SenderType.customer);
    });

    test('should return unknown for invalid string', () {
      expect('invalid'.toSenderType(), SenderType.unknown);
      expect(''.toSenderType(), SenderType.unknown);
    });
  });

  group('SenderType Extension toApiString', () {
    test('should convert SenderType to API string', () {
      expect(SenderType.pharmacy.toApiString(), 'pharmacy');
      expect(SenderType.courier.toApiString(), 'courier');
      expect(SenderType.customer.toApiString(), 'customer');
      expect(SenderType.unknown.toApiString(), 'unknown');
    });
  });
}
