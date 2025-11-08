/// Model representing a device calendar source.
class CalendarSource {
  const CalendarSource({
    required this.id,
    required this.name,
    this.accountName,
    this.accountType,
    this.isPrimary = false,
    this.included = false,
  });

  final String id;
  final String name;
  final String? accountName;
  final String? accountType;
  final bool isPrimary;
  final bool included;

  CalendarSource copyWith({
    String? id,
    String? name,
    String? accountName,
    String? accountType,
    bool? isPrimary,
    bool? included,
  }) {
    return CalendarSource(
      id: id ?? this.id,
      name: name ?? this.name,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      isPrimary: isPrimary ?? this.isPrimary,
      included: included ?? this.included,
    );
  }
}
