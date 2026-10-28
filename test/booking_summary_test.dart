import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/domain/booking.dart';
import 'package:nyto_app/domain/table.dart';

UpcomingTable _table({DateTime? startsAt}) {
  final start = startsAt ?? DateTime.now().add(const Duration(days: 3));
  return UpcomingTable(
    id: 't1',
    venueName: 'Test Venue',
    area: 'Ameerpet',
    city: 'Hyderabad',
    weekday: 'Fri',
    dateLabel: '1 Jan',
    timeLabel: '8:00 PM',
    priceInr: 999,
    seatsTaken: 1,
    capacity: 6,
    startsAt: start,
    slot: MealSlot.eveningDinner,
    inclusions: const [],
  );
}

void main() {
  group('BookingSummary.canCancel', () {
    test('allows unpaid holds', () {
      final b = BookingSummary(
        id: 'b1',
        status: 'PENDING_PAYMENT',
        seatsBooked: 1,
        bookingType: 'SOLO',
        table: _table(),
      );
      expect(b.canCancel, isTrue);
    });

    test('allows paid seats before start', () {
      final b = BookingSummary(
        id: 'b1',
        status: 'CONFIRMED',
        seatsBooked: 1,
        bookingType: 'SOLO',
        table: _table(startsAt: DateTime.now().add(const Duration(hours: 5))),
      );
      expect(b.canCancel, isTrue);
    });

    test('blocks after table start', () {
      final b = BookingSummary(
        id: 'b1',
        status: 'CONFIRMED',
        seatsBooked: 1,
        bookingType: 'SOLO',
        table: _table(
          startsAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(b.canCancel, isFalse);
    });

    test('blocks attended / cancelled / no-show', () {
      for (final status in ['ATTENDED', 'CANCELLED', 'NO_SHOW']) {
        final b = BookingSummary(
          id: 'b1',
          status: status,
          seatsBooked: 1,
          bookingType: 'SOLO',
          table: _table(),
        );
        expect(b.canCancel, isFalse, reason: status);
      }
    });
  });

  group('BookingSummary status labels', () {
    test('guest cancel shows Cancelled by you', () {
      final b = BookingSummary(
        id: 'b1',
        status: 'CANCELLED',
        seatsBooked: 1,
        bookingType: 'SOLO',
        cancelReason: 'USER',
      );
      expect(b.statusLabel, 'Cancelled by you');
    });

    test('hold TTL shows Hold expired', () {
      final b = BookingSummary(
        id: 'b1',
        status: 'CANCELLED',
        seatsBooked: 1,
        bookingType: 'SOLO',
        cancelReason: 'HOLD_EXPIRED',
      );
      expect(b.holdExpired, isTrue);
      expect(b.statusLabel, 'Hold expired');
    });

    test('fromJson keeps cancelReason', () {
      final b = BookingSummary.fromJson({
        'id': 'b1',
        'status': 'CANCELLED',
        'seatsBooked': 1,
        'bookingType': 'SOLO',
        'cancelReason': 'USER',
      });
      expect(b.cancelReason, 'USER');
      expect(b.cancelledByUser, isTrue);
    });
  });
}
