part of 'package:tempo_pilot/data/local/app_database.dart';

class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_user_active_sessions', columns: {#userId, #deletedAt})
@TableIndex(name: 'idx_synced', columns: {#synced})
@TableIndex(name: 'idx_user_sessions_by_date', columns: {#userId, #startedAt})
@TableIndex(
  name: 'idx_user_sessions_by_updated_at',
  columns: {#userId, #updatedAt},
)
class LocalFocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId =>
      text().references(LocalProfiles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get plannedDurationMinutes => integer()();
  IntColumn get actualDurationMinutes => integer().nullable()();
  TextColumn get sessionType =>
      text().withDefault(const Constant('pomodoro'))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_calendar_included', columns: {#included})
class LocalCalendarSources extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountName => text().nullable()();
  TextColumn get accountType => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  BoolColumn get included => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_calendar_event_window', columns: {#calendarId, #startTs})
@TableIndex(name: 'idx_event_start', columns: {#startTs})
@TableIndex(name: 'idx_event_deleted', columns: {#deletedAt})
class LocalCalendarEvents extends Table {
  /// Platform event ID - unique per calendar
  TextColumn get eventId => text()();

  /// Calendar ID this event belongs to
  TextColumn get calendarId => text().references(
    LocalCalendarSources,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Instance discriminator for recurring events.
  /// For recurring events, the platform reuses the same eventId,
  /// so we use the start timestamp to distinguish each occurrence.
  /// For non-recurring events, this equals startTs.
  Int64Column get instanceStartTs => int64()();

  /// Start timestamp in milliseconds since epoch (UTC)
  Int64Column get startTs => int64()();

  /// End timestamp in milliseconds since epoch (UTC)
  Int64Column get endTs => int64()();

  /// Whether this is an all-day event
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();

  /// Busy/free hint from platform (nullable - not all platforms provide this)
  BoolColumn get busyHint => boolean().nullable()();

  /// Privacy: NO title/description/location stored
  /// Only timestamps and busy/free hints for free-time calculation

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {eventId, calendarId, instanceStartTs};
}
