enum MealSlot { daytimeLunch, eveningDinner }

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
    this.startsAt,
    this.menSeated = 0,
    this.womenSeated = 0,
    this.nonBinarySeated = 0,
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
  final DateTime? startsAt;

  /// Anonymous seated mix (prefer-not-to-say is never shown publicly).
  final int menSeated;
  final int womenSeated;
  final int nonBinarySeated;

  int get seatsLeft => capacity - seatsTaken;

  /// Quiet label: `2W · 1M · 1NB · 3 open`
  String get seatMixLabel {
    final parts = <String>[];
    if (womenOnly) {
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
    final womenOnly = json['womenOnly'] as bool? ?? false;
    var men = json['menSeated'] as int?;
    var women = json['womenSeated'] as int?;
    var nb = json['nonBinarySeated'] as int?;
    if (men == null && women == null && nb == null) {
      final preview = _previewMix(taken: taken, womenOnly: womenOnly);
      men = preview.$1;
      women = preview.$2;
      nb = preview.$3;
    }
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
      startsAt: startsAt,
      menSeated: men ?? 0,
      womenSeated: women ?? 0,
      nonBinarySeated: nb ?? 0,
    );
  }

  /// Deterministic UI preview until booking genders ship from API.
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
