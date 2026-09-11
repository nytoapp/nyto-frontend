import 'package:nyto_app/domain/table.dart';

/// Consumer booking row from `/bookings/me` or `/bookings/:id`.
class BookingSummary {
  const BookingSummary({
    required this.id,
    required this.status,
    required this.seatsBooked,
    required this.bookingType,
    this.checkInCode,
    this.amountPaid,
    this.paidAt,
    this.checkedInAt,
    this.cancelReason,
    this.table,
    this.venueName,
    this.city,
    this.area,
  });

  final String id;
  final String status;
  final int seatsBooked;
  final String bookingType;
  final String? checkInCode;
  final int? amountPaid;
  final DateTime? paidAt;
  final DateTime? checkedInAt;
  final String? cancelReason;
  final UpcomingTable? table;
  final String? venueName;
  final String? city;
  final String? area;

  bool get isConfirmed =>
      status == 'CONFIRMED' || status == 'ATTENDED';

  /// Paid seats stay locked. Unpaid holds never appear as a real booking.
  bool get canCancel => false;

  bool get isPaidSeat =>
      status == 'CONFIRMED' || status == 'ATTENDED';

  bool get isCancelled =>
      status == 'CANCELLED' || status == 'NO_SHOW';

  /// Who ended the booking — guest vs NYTO/ops.
  bool get cancelledByUser {
    final reason = (cancelReason ?? '').trim().toLowerCase();
    return reason == 'user' ||
        reason.contains('guest') ||
        reason.contains('by you');
  }

  String get cancelledByLabel =>
      cancelledByUser ? 'Cancelled by you' : 'Cancelled by NYTO';

  String get statusLabel => switch (status) {
        'PENDING_PAYMENT' => 'Awaiting payment',
        'CONFIRMED' => 'Confirmed',
        'ATTENDED' => 'Checked in',
        'CANCELLED' => cancelledByLabel,
        'NO_SHOW' => 'No show',
        _ => status,
      };

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    final tableRaw = json['table'];
    UpcomingTable? table;
    String? venueName;
    String? city;
    String? area;

    if (tableRaw is Map<String, dynamic>) {
      final venue = tableRaw['venue'];
      if (venue is Map<String, dynamic>) {
        venueName = venue['name'] as String?;
        city = venue['city'] as String?;
        final address = venue['address'] as String? ?? '';
        area = address.split(',').first.trim();
        if (area.isEmpty) area = city;
      }

      // Flatten nested venue fields into UpcomingTable shape when possible.
      final flat = <String, dynamic>{
        ...tableRaw,
        'venueName': venueName ?? tableRaw['venueName'],
        'city': city ?? tableRaw['city'] ?? 'Hyderabad',
        'area': area ?? tableRaw['area'] ?? venueName ?? 'Venue',
        'seatPrice': tableRaw['seatPrice'] ?? json['amountPaid'],
        'seatsTaken': tableRaw['seatsTaken'] ?? 0,
        'weekday': tableRaw['weekday'],
        'dateLabel': tableRaw['dateLabel'],
        'timeLabel': tableRaw['timeLabel'],
        'slot': tableRaw['slot'] ??
            ((tableRaw['priceTier'] == 'DAYTIME')
                ? 'DAYTIME_LUNCH'
                : 'EVENING_DINNER'),
      };

      // Derive labels if API returned raw SupperTable without formatted fields.
      final startsAt = DateTime.tryParse('${tableRaw['startsAt']}')?.toLocal();
      if (startsAt != null && flat['weekday'] == null) {
        flat['weekday'] = _weekdayShort(startsAt);
        flat['dateLabel'] = _dateLabel(startsAt);
        flat['timeLabel'] = _timeLabel(startsAt);
        flat['startsAt'] = startsAt.toIso8601String();
      }

      table = UpcomingTable.fromJson(flat);
    }

    DateTime? paidAt;
    final paidRaw = json['paidAt'];
    if (paidRaw is String) paidAt = DateTime.tryParse(paidRaw)?.toLocal();

    DateTime? checkedInAt;
    final checkedRaw = json['checkedInAt'];
    if (checkedRaw is String) {
      checkedInAt = DateTime.tryParse(checkedRaw)?.toLocal();
    }

    return BookingSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      seatsBooked: json['seatsBooked'] as int? ?? 1,
      bookingType: json['bookingType'] as String? ?? 'SOLO',
      checkInCode: json['checkInCode'] as String?,
      amountPaid: json['amountPaid'] as int?,
      paidAt: paidAt,
      checkedInAt: checkedInAt,
      cancelReason: json['cancelReason'] as String?,
      table: table,
      venueName: venueName ?? table?.area,
      city: city ?? table?.city,
      area: area ?? table?.area,
    );
  }

  static String _weekdayShort(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  static String _dateLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  static String _timeLabel(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
