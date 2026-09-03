enum MealSlot { daytimeLunch, eveningDinner }

enum NytoTableType {
  weekly,
  womenLed,
  couples,
  singles,
}

enum TablePaymentType {
  allInclusive,
  payOwnBill,
}

NytoTableType parseTableType(String? raw) {
  switch (raw) {
    case 'WOMEN_LED':
      return NytoTableType.womenLed;
    case 'COUPLES':
      return NytoTableType.couples;
    case 'SINGLES':
      return NytoTableType.singles;
    default:
      return NytoTableType.weekly;
  }
}

TablePaymentType parsePaymentType(String? raw) {
  if (raw == 'PAY_OWN_BILL') return TablePaymentType.payOwnBill;
  return TablePaymentType.allInclusive;
}

/// Bookable NYTO table — shared across Home, booking, and chat.
class UpcomingTable {
  const UpcomingTable({
    required this.id,
    required this.weekday,
    required this.dateLabel,
    required this.timeLabel,
    required this.priceInr,
    required this.slot,
    required this.area,
    required this.seatsTaken,
    this.womenOnly = false,
    this.capacity = 6,
    this.section = 'This week',
    this.city = 'Hyderabad',
    this.venueName,
    this.startsAt,
    this.bookingOpensAt,
    this.bookable = true,
    this.isInstant = false,
    this.tableType = NytoTableType.weekly,
    this.paymentType = TablePaymentType.allInclusive,
    this.vibeCopy,
    this.inclusions = const [],
    this.matchingLine,
    this.menSeated = 0,
    this.womenSeated = 0,
    this.nonBinarySeated = 0,
    this.couplesConfirmed = 0,
  });

  final String id;
  final String weekday;
  final String dateLabel;
  final String timeLabel;
  final int priceInr;
  final MealSlot slot;
  final String area;
  final int seatsTaken;
  final bool womenOnly;
  final int capacity;
  final String section;
  final String city;
  final String? venueName;
  final DateTime? startsAt;
  final DateTime? bookingOpensAt;
  final bool bookable;
  final bool isInstant;
  final NytoTableType tableType;
  final TablePaymentType paymentType;
  final String? vibeCopy;
  final List<String> inclusions;
  final String? matchingLine;
  final int menSeated;
  final int womenSeated;
  final int nonBinarySeated;
  final int couplesConfirmed;

  int get seatsLeft => capacity - seatsTaken;

  String get tableTypeLabel => switch (tableType) {
        NytoTableType.weekly => 'Weekly',
        NytoTableType.womenLed => 'Women-Led',
        NytoTableType.couples => 'Couples',
        NytoTableType.singles => 'Singles',
      };

  String get paymentTypeLabel => switch (paymentType) {
        TablePaymentType.allInclusive => 'All-inclusive',
        TablePaymentType.payOwnBill => 'Pay your own bill',
      };

  String get apiTableType => switch (tableType) {
        NytoTableType.weekly => 'WEEKLY',
        NytoTableType.womenLed => 'WOMEN_LED',
        NytoTableType.couples => 'COUPLES',
        NytoTableType.singles => 'SINGLES',
      };

  String get seatMixLabel {
    if (tableType == NytoTableType.singles) {
      return '$womenSeated women · $menSeated men · $seatsLeft open';
    }
    if (tableType == NytoTableType.couples) {
      return '$couplesConfirmed / 3 couples · $seatsLeft open';
    }
    final parts = <String>[];
    if (womenOnly || tableType == NytoTableType.womenLed) {
      if (womenSeated > 0) parts.add('${womenSeated}W');
    } else {
      if (womenSeated > 0) parts.add('${womenSeated}W');
      if (menSeated > 0) parts.add('${menSeated}M');
      if (nonBinarySeated > 0) parts.add('${nonBinarySeated}NB');
    }
    parts.add('$seatsLeft open');
    return parts.join(' · ');
  }

  String get mealLabel => switch (slot) {
        MealSlot.daytimeLunch => 'Lunch',
        MealSlot.eveningDinner => 'Dinner',
      };

  String get fullDateLabel => '$weekday, $dateLabel';

  factory UpcomingTable.fromJson(Map<String, dynamic> json) {
    final slotRaw = json['slot'] as String? ?? 'EVENING_DINNER';
    final seatsTaken = json['seatsTaken'] as int? ?? 0;
    final capacity = json['capacity'] as int? ?? 6;
    final seatsLeft = json['seatsLeft'] as int?;
    final taken = seatsLeft != null ? (capacity - seatsLeft) : seatsTaken;
    DateTime? startsAt;
    final rawStarts = json['startsAt'];
    if (rawStarts is String) {
      startsAt = DateTime.tryParse(rawStarts)?.toLocal();
    }
    DateTime? bookingOpensAt;
    final rawOpens = json['bookingOpensAt'];
    if (rawOpens is String) {
      bookingOpensAt = DateTime.tryParse(rawOpens)?.toLocal();
    }
    final tableType = parseTableType(json['tableType'] as String?);
    final womenOnly = json['womenOnly'] as bool? ??
        tableType == NytoTableType.womenLed;
    var men = json['menConfirmed'] as int? ?? json['menSeated'] as int?;
    var women = json['womenConfirmed'] as int? ?? json['womenSeated'] as int?;
    var nb = json['nonBinarySeated'] as int?;
    if (men == null && women == null && nb == null) {
      final preview = _previewMix(taken: taken, womenOnly: womenOnly);
      men = preview.$1;
      women = preview.$2;
      nb = preview.$3;
    }
    final inclusionsRaw = json['inclusions'];
    final inclusions = inclusionsRaw is List
        ? inclusionsRaw.whereType<String>().toList()
        : const <String>[];
    return UpcomingTable(
      id: json['id'] as String,
      weekday: json['weekday'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      priceInr: json['seatPrice'] as int? ?? 0,
      slot: slotRaw.contains('DAYTIME')
          ? MealSlot.daytimeLunch
          : MealSlot.eveningDinner,
      area: json['area'] as String? ?? '',
      seatsTaken: taken,
      womenOnly: womenOnly,
      capacity: capacity,
      section: json['section'] as String? ?? 'This week',
      city: json['city'] as String? ?? 'Hyderabad',
      venueName: json['venueName'] as String?,
      startsAt: startsAt,
      bookingOpensAt: bookingOpensAt,
      bookable: json['bookable'] as bool? ?? true,
      isInstant: json['instant'] as bool? ?? false,
      tableType: tableType,
      paymentType: parsePaymentType(json['paymentType'] as String?),
      vibeCopy: json['vibeCopy'] as String?,
      inclusions: inclusions,
      matchingLine: json['matchingLine'] as String?,
      menSeated: men ?? 0,
      womenSeated: women ?? 0,
      nonBinarySeated: nb ?? 0,
      couplesConfirmed: json['couplesConfirmed'] as int? ?? 0,
    );
  }

  static (int, int, int) _previewMix({
    required int taken,
    required bool womenOnly,
  }) {
    if (taken <= 0) return (0, 0, 0);
    if (womenOnly) return (0, taken, 0);
    if (taken == 1) return (0, 1, 0);
    if (taken == 2) return (1, 1, 0);
    if (taken == 3) return (1, 2, 0);
    if (taken == 4) return (2, 1, 1);
    if (taken == 5) return (2, 2, 1);
    return (2, 3, 1);
  }
}
