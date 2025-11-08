// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    displayName,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String id;
  final String? email;
  final String? displayName;
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const LocalProfile({
    required this.id,
    this.email,
    this.displayName,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      id: Value(id),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String?>(json['email']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String?>(email),
      'displayName': serializer.toJson<String?>(displayName),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalProfile copyWith({
    String? id,
    Value<String?> email = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalProfile(
    id: id ?? this.id,
    email: email.present ? email.value : this.email,
    displayName: displayName.present ? displayName.value : this.displayName,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalProfile copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfile(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> id;
  final Value<String?> email;
  final Value<String?> displayName;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String id,
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalProfile> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? email,
    Value<String?>? displayName,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalProfilesCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFocusSessionsTable extends LocalFocusSessions
    with TableInfo<$LocalFocusSessionsTable, LocalFocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedDurationMinutesMeta =
      const VerificationMeta('plannedDurationMinutes');
  @override
  late final GeneratedColumn<int> plannedDurationMinutes = GeneratedColumn<int>(
    'planned_duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualDurationMinutesMeta =
      const VerificationMeta('actualDurationMinutes');
  @override
  late final GeneratedColumn<int> actualDurationMinutes = GeneratedColumn<int>(
    'actual_duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pomodoro'),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    startedAt,
    endedAt,
    plannedDurationMinutes,
    actualDurationMinutes,
    sessionType,
    completed,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('planned_duration_minutes')) {
      context.handle(
        _plannedDurationMinutesMeta,
        plannedDurationMinutes.isAcceptableOrUnknown(
          data['planned_duration_minutes']!,
          _plannedDurationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedDurationMinutesMeta);
    }
    if (data.containsKey('actual_duration_minutes')) {
      context.handle(
        _actualDurationMinutesMeta,
        actualDurationMinutes.isAcceptableOrUnknown(
          data['actual_duration_minutes']!,
          _actualDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      plannedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_minutes'],
      )!,
      actualDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration_minutes'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LocalFocusSessionsTable createAlias(String alias) {
    return $LocalFocusSessionsTable(attachedDatabase, alias);
  }
}

class LocalFocusSession extends DataClass
    implements Insertable<LocalFocusSession> {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final String sessionType;
  final bool completed;
  final String? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool synced;
  const LocalFocusSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    required this.sessionType,
    required this.completed,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['planned_duration_minutes'] = Variable<int>(plannedDurationMinutes);
    if (!nullToAbsent || actualDurationMinutes != null) {
      map['actual_duration_minutes'] = Variable<int>(actualDurationMinutes);
    }
    map['session_type'] = Variable<String>(sessionType);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalFocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalFocusSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      plannedDurationMinutes: Value(plannedDurationMinutes),
      actualDurationMinutes: actualDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDurationMinutes),
      sessionType: Value(sessionType),
      completed: Value(completed),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      synced: Value(synced),
    );
  }

  factory LocalFocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFocusSession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      plannedDurationMinutes: serializer.fromJson<int>(
        json['plannedDurationMinutes'],
      ),
      actualDurationMinutes: serializer.fromJson<int?>(
        json['actualDurationMinutes'],
      ),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      completed: serializer.fromJson<bool>(json['completed']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'plannedDurationMinutes': serializer.toJson<int>(plannedDurationMinutes),
      'actualDurationMinutes': serializer.toJson<int?>(actualDurationMinutes),
      'sessionType': serializer.toJson<String>(sessionType),
      'completed': serializer.toJson<bool>(completed),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalFocusSession copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? plannedDurationMinutes,
    Value<int?> actualDurationMinutes = const Value.absent(),
    String? sessionType,
    bool? completed,
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? synced,
  }) => LocalFocusSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    plannedDurationMinutes:
        plannedDurationMinutes ?? this.plannedDurationMinutes,
    actualDurationMinutes: actualDurationMinutes.present
        ? actualDurationMinutes.value
        : this.actualDurationMinutes,
    sessionType: sessionType ?? this.sessionType,
    completed: completed ?? this.completed,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    synced: synced ?? this.synced,
  );
  LocalFocusSession copyWithCompanion(LocalFocusSessionsCompanion data) {
    return LocalFocusSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      plannedDurationMinutes: data.plannedDurationMinutes.present
          ? data.plannedDurationMinutes.value
          : this.plannedDurationMinutes,
      actualDurationMinutes: data.actualDurationMinutes.present
          ? data.actualDurationMinutes.value
          : this.actualDurationMinutes,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      completed: data.completed.present ? data.completed.value : this.completed,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFocusSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes, ')
          ..write('actualDurationMinutes: $actualDurationMinutes, ')
          ..write('sessionType: $sessionType, ')
          ..write('completed: $completed, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    startedAt,
    endedAt,
    plannedDurationMinutes,
    actualDurationMinutes,
    sessionType,
    completed,
    metadata,
    createdAt,
    updatedAt,
    deletedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFocusSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.plannedDurationMinutes == this.plannedDurationMinutes &&
          other.actualDurationMinutes == this.actualDurationMinutes &&
          other.sessionType == this.sessionType &&
          other.completed == this.completed &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.synced == this.synced);
}

class LocalFocusSessionsCompanion extends UpdateCompanion<LocalFocusSession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> plannedDurationMinutes;
  final Value<int?> actualDurationMinutes;
  final Value<String> sessionType;
  final Value<bool> completed;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalFocusSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.plannedDurationMinutes = const Value.absent(),
    this.actualDurationMinutes = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.completed = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFocusSessionsCompanion.insert({
    required String id,
    required String userId,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required int plannedDurationMinutes,
    this.actualDurationMinutes = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.completed = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       plannedDurationMinutes = Value(plannedDurationMinutes);
  static Insertable<LocalFocusSession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? plannedDurationMinutes,
    Expression<int>? actualDurationMinutes,
    Expression<String>? sessionType,
    Expression<bool>? completed,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (plannedDurationMinutes != null)
        'planned_duration_minutes': plannedDurationMinutes,
      if (actualDurationMinutes != null)
        'actual_duration_minutes': actualDurationMinutes,
      if (sessionType != null) 'session_type': sessionType,
      if (completed != null) 'completed': completed,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? plannedDurationMinutes,
    Value<int?>? actualDurationMinutes,
    Value<String>? sessionType,
    Value<bool>? completed,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LocalFocusSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      sessionType: sessionType ?? this.sessionType,
      completed: completed ?? this.completed,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (plannedDurationMinutes.present) {
      map['planned_duration_minutes'] = Variable<int>(
        plannedDurationMinutes.value,
      );
    }
    if (actualDurationMinutes.present) {
      map['actual_duration_minutes'] = Variable<int>(
        actualDurationMinutes.value,
      );
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes, ')
          ..write('actualDurationMinutes: $actualDurationMinutes, ')
          ..write('sessionType: $sessionType, ')
          ..write('completed: $completed, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarSourcesTable extends LocalCalendarSources
    with TableInfo<$LocalCalendarSourcesTable, LocalCalendarSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _includedMeta = const VerificationMeta(
    'included',
  );
  @override
  late final GeneratedColumn<bool> included = GeneratedColumn<bool>(
    'included',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("included" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    accountName,
    accountType,
    isPrimary,
    included,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendar_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendarSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('included')) {
      context.handle(
        _includedMeta,
        included.isAcceptableOrUnknown(data['included']!, _includedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCalendarSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendarSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      included: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}included'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCalendarSourcesTable createAlias(String alias) {
    return $LocalCalendarSourcesTable(attachedDatabase, alias);
  }
}

class LocalCalendarSource extends DataClass
    implements Insertable<LocalCalendarSource> {
  final String id;
  final String name;
  final String? accountName;
  final String? accountType;
  final bool isPrimary;
  final bool included;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalCalendarSource({
    required this.id,
    required this.name,
    this.accountName,
    this.accountType,
    required this.isPrimary,
    required this.included,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    if (!nullToAbsent || accountType != null) {
      map['account_type'] = Variable<String>(accountType);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['included'] = Variable<bool>(included);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCalendarSourcesCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarSourcesCompanion(
      id: Value(id),
      name: Value(name),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      accountType: accountType == null && nullToAbsent
          ? const Value.absent()
          : Value(accountType),
      isPrimary: Value(isPrimary),
      included: Value(included),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCalendarSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendarSource(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      accountType: serializer.fromJson<String?>(json['accountType']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      included: serializer.fromJson<bool>(json['included']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'accountName': serializer.toJson<String?>(accountName),
      'accountType': serializer.toJson<String?>(accountType),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'included': serializer.toJson<bool>(included),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCalendarSource copyWith({
    String? id,
    String? name,
    Value<String?> accountName = const Value.absent(),
    Value<String?> accountType = const Value.absent(),
    bool? isPrimary,
    bool? included,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalCalendarSource(
    id: id ?? this.id,
    name: name ?? this.name,
    accountName: accountName.present ? accountName.value : this.accountName,
    accountType: accountType.present ? accountType.value : this.accountType,
    isPrimary: isPrimary ?? this.isPrimary,
    included: included ?? this.included,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCalendarSource copyWithCompanion(LocalCalendarSourcesCompanion data) {
    return LocalCalendarSource(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      included: data.included.present ? data.included.value : this.included,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarSource(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('included: $included, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    accountName,
    accountType,
    isPrimary,
    included,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendarSource &&
          other.id == this.id &&
          other.name == this.name &&
          other.accountName == this.accountName &&
          other.accountType == this.accountType &&
          other.isPrimary == this.isPrimary &&
          other.included == this.included &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCalendarSourcesCompanion
    extends UpdateCompanion<LocalCalendarSource> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> accountName;
  final Value<String?> accountType;
  final Value<bool> isPrimary;
  final Value<bool> included;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCalendarSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.included = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarSourcesCompanion.insert({
    required String id,
    required String name,
    this.accountName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.included = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalCalendarSource> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? accountName,
    Expression<String>? accountType,
    Expression<bool>? isPrimary,
    Expression<bool>? included,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (accountName != null) 'account_name': accountName,
      if (accountType != null) 'account_type': accountType,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (included != null) 'included': included,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? accountName,
    Value<String?>? accountType,
    Value<bool>? isPrimary,
    Value<bool>? included,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCalendarSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      isPrimary: isPrimary ?? this.isPrimary,
      included: included ?? this.included,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (included.present) {
      map['included'] = Variable<bool>(included.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('included: $included, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarEventsTable extends LocalCalendarEvents
    with TableInfo<$LocalCalendarEventsTable, LocalCalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_calendar_sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _instanceStartTsMeta = const VerificationMeta(
    'instanceStartTs',
  );
  @override
  late final GeneratedColumn<BigInt> instanceStartTs = GeneratedColumn<BigInt>(
    'instance_start_ts',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTsMeta = const VerificationMeta(
    'startTs',
  );
  @override
  late final GeneratedColumn<BigInt> startTs = GeneratedColumn<BigInt>(
    'start_ts',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTsMeta = const VerificationMeta('endTs');
  @override
  late final GeneratedColumn<BigInt> endTs = GeneratedColumn<BigInt>(
    'end_ts',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _busyHintMeta = const VerificationMeta(
    'busyHint',
  );
  @override
  late final GeneratedColumn<bool> busyHint = GeneratedColumn<bool>(
    'busy_hint',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("busy_hint" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    calendarId,
    instanceStartTs,
    startTs,
    endTs,
    isAllDay,
    busyHint,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendarEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('instance_start_ts')) {
      context.handle(
        _instanceStartTsMeta,
        instanceStartTs.isAcceptableOrUnknown(
          data['instance_start_ts']!,
          _instanceStartTsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instanceStartTsMeta);
    }
    if (data.containsKey('start_ts')) {
      context.handle(
        _startTsMeta,
        startTs.isAcceptableOrUnknown(data['start_ts']!, _startTsMeta),
      );
    } else if (isInserting) {
      context.missing(_startTsMeta);
    }
    if (data.containsKey('end_ts')) {
      context.handle(
        _endTsMeta,
        endTs.isAcceptableOrUnknown(data['end_ts']!, _endTsMeta),
      );
    } else if (isInserting) {
      context.missing(_endTsMeta);
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('busy_hint')) {
      context.handle(
        _busyHintMeta,
        busyHint.isAcceptableOrUnknown(data['busy_hint']!, _busyHintMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    eventId,
    calendarId,
    instanceStartTs,
  };
  @override
  LocalCalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendarEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      instanceStartTs: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}instance_start_ts'],
      )!,
      startTs: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}start_ts'],
      )!,
      endTs: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}end_ts'],
      )!,
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      busyHint: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}busy_hint'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalCalendarEventsTable createAlias(String alias) {
    return $LocalCalendarEventsTable(attachedDatabase, alias);
  }
}

class LocalCalendarEvent extends DataClass
    implements Insertable<LocalCalendarEvent> {
  /// Platform event ID - unique per calendar
  final String eventId;

  /// Calendar ID this event belongs to
  final String calendarId;

  /// Instance discriminator for recurring events.
  /// For recurring events, the platform reuses the same eventId,
  /// so we use the start timestamp to distinguish each occurrence.
  /// For non-recurring events, this equals startTs.
  final BigInt instanceStartTs;

  /// Start timestamp in milliseconds since epoch (UTC)
  final BigInt startTs;

  /// End timestamp in milliseconds since epoch (UTC)
  final BigInt endTs;

  /// Whether this is an all-day event
  final bool isAllDay;

  /// Busy/free hint from platform (nullable - not all platforms provide this)
  final bool? busyHint;

  /// Privacy: NO title/description/location stored
  /// Only timestamps and busy/free hints for free-time calculation
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const LocalCalendarEvent({
    required this.eventId,
    required this.calendarId,
    required this.instanceStartTs,
    required this.startTs,
    required this.endTs,
    required this.isAllDay,
    this.busyHint,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['calendar_id'] = Variable<String>(calendarId);
    map['instance_start_ts'] = Variable<BigInt>(instanceStartTs);
    map['start_ts'] = Variable<BigInt>(startTs);
    map['end_ts'] = Variable<BigInt>(endTs);
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || busyHint != null) {
      map['busy_hint'] = Variable<bool>(busyHint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LocalCalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarEventsCompanion(
      eventId: Value(eventId),
      calendarId: Value(calendarId),
      instanceStartTs: Value(instanceStartTs),
      startTs: Value(startTs),
      endTs: Value(endTs),
      isAllDay: Value(isAllDay),
      busyHint: busyHint == null && nullToAbsent
          ? const Value.absent()
          : Value(busyHint),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalCalendarEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendarEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      instanceStartTs: serializer.fromJson<BigInt>(json['instanceStartTs']),
      startTs: serializer.fromJson<BigInt>(json['startTs']),
      endTs: serializer.fromJson<BigInt>(json['endTs']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      busyHint: serializer.fromJson<bool?>(json['busyHint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'calendarId': serializer.toJson<String>(calendarId),
      'instanceStartTs': serializer.toJson<BigInt>(instanceStartTs),
      'startTs': serializer.toJson<BigInt>(startTs),
      'endTs': serializer.toJson<BigInt>(endTs),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'busyHint': serializer.toJson<bool?>(busyHint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalCalendarEvent copyWith({
    String? eventId,
    String? calendarId,
    BigInt? instanceStartTs,
    BigInt? startTs,
    BigInt? endTs,
    bool? isAllDay,
    Value<bool?> busyHint = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalCalendarEvent(
    eventId: eventId ?? this.eventId,
    calendarId: calendarId ?? this.calendarId,
    instanceStartTs: instanceStartTs ?? this.instanceStartTs,
    startTs: startTs ?? this.startTs,
    endTs: endTs ?? this.endTs,
    isAllDay: isAllDay ?? this.isAllDay,
    busyHint: busyHint.present ? busyHint.value : this.busyHint,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalCalendarEvent copyWithCompanion(LocalCalendarEventsCompanion data) {
    return LocalCalendarEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      instanceStartTs: data.instanceStartTs.present
          ? data.instanceStartTs.value
          : this.instanceStartTs,
      startTs: data.startTs.present ? data.startTs.value : this.startTs,
      endTs: data.endTs.present ? data.endTs.value : this.endTs,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      busyHint: data.busyHint.present ? data.busyHint.value : this.busyHint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarEvent(')
          ..write('eventId: $eventId, ')
          ..write('calendarId: $calendarId, ')
          ..write('instanceStartTs: $instanceStartTs, ')
          ..write('startTs: $startTs, ')
          ..write('endTs: $endTs, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('busyHint: $busyHint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    calendarId,
    instanceStartTs,
    startTs,
    endTs,
    isAllDay,
    busyHint,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendarEvent &&
          other.eventId == this.eventId &&
          other.calendarId == this.calendarId &&
          other.instanceStartTs == this.instanceStartTs &&
          other.startTs == this.startTs &&
          other.endTs == this.endTs &&
          other.isAllDay == this.isAllDay &&
          other.busyHint == this.busyHint &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalCalendarEventsCompanion extends UpdateCompanion<LocalCalendarEvent> {
  final Value<String> eventId;
  final Value<String> calendarId;
  final Value<BigInt> instanceStartTs;
  final Value<BigInt> startTs;
  final Value<BigInt> endTs;
  final Value<bool> isAllDay;
  final Value<bool?> busyHint;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const LocalCalendarEventsCompanion({
    this.eventId = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.instanceStartTs = const Value.absent(),
    this.startTs = const Value.absent(),
    this.endTs = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.busyHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarEventsCompanion.insert({
    required String eventId,
    required String calendarId,
    required BigInt instanceStartTs,
    required BigInt startTs,
    required BigInt endTs,
    this.isAllDay = const Value.absent(),
    this.busyHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       calendarId = Value(calendarId),
       instanceStartTs = Value(instanceStartTs),
       startTs = Value(startTs),
       endTs = Value(endTs);
  static Insertable<LocalCalendarEvent> custom({
    Expression<String>? eventId,
    Expression<String>? calendarId,
    Expression<BigInt>? instanceStartTs,
    Expression<BigInt>? startTs,
    Expression<BigInt>? endTs,
    Expression<bool>? isAllDay,
    Expression<bool>? busyHint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (instanceStartTs != null) 'instance_start_ts': instanceStartTs,
      if (startTs != null) 'start_ts': startTs,
      if (endTs != null) 'end_ts': endTs,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (busyHint != null) 'busy_hint': busyHint,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? calendarId,
    Value<BigInt>? instanceStartTs,
    Value<BigInt>? startTs,
    Value<BigInt>? endTs,
    Value<bool>? isAllDay,
    Value<bool?>? busyHint,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalCalendarEventsCompanion(
      eventId: eventId ?? this.eventId,
      calendarId: calendarId ?? this.calendarId,
      instanceStartTs: instanceStartTs ?? this.instanceStartTs,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      isAllDay: isAllDay ?? this.isAllDay,
      busyHint: busyHint ?? this.busyHint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (instanceStartTs.present) {
      map['instance_start_ts'] = Variable<BigInt>(instanceStartTs.value);
    }
    if (startTs.present) {
      map['start_ts'] = Variable<BigInt>(startTs.value);
    }
    if (endTs.present) {
      map['end_ts'] = Variable<BigInt>(endTs.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (busyHint.present) {
      map['busy_hint'] = Variable<bool>(busyHint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('calendarId: $calendarId, ')
          ..write('instanceStartTs: $instanceStartTs, ')
          ..write('startTs: $startTs, ')
          ..write('endTs: $endTs, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('busyHint: $busyHint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalFocusSessionsTable localFocusSessions =
      $LocalFocusSessionsTable(this);
  late final $LocalCalendarSourcesTable localCalendarSources =
      $LocalCalendarSourcesTable(this);
  late final $LocalCalendarEventsTable localCalendarEvents =
      $LocalCalendarEventsTable(this);
  late final Index idxUserActiveSessions = Index(
    'idx_user_active_sessions',
    'CREATE INDEX idx_user_active_sessions ON local_focus_sessions (user_id, deleted_at)',
  );
  late final Index idxSynced = Index(
    'idx_synced',
    'CREATE INDEX idx_synced ON local_focus_sessions (synced)',
  );
  late final Index idxUserSessionsByDate = Index(
    'idx_user_sessions_by_date',
    'CREATE INDEX idx_user_sessions_by_date ON local_focus_sessions (user_id, started_at)',
  );
  late final Index idxUserSessionsByUpdatedAt = Index(
    'idx_user_sessions_by_updated_at',
    'CREATE INDEX idx_user_sessions_by_updated_at ON local_focus_sessions (user_id, updated_at)',
  );
  late final Index idxCalendarIncluded = Index(
    'idx_calendar_included',
    'CREATE INDEX idx_calendar_included ON local_calendar_sources (included)',
  );
  late final Index idxCalendarEventWindow = Index(
    'idx_calendar_event_window',
    'CREATE INDEX idx_calendar_event_window ON local_calendar_events (calendar_id, start_ts)',
  );
  late final Index idxEventStart = Index(
    'idx_event_start',
    'CREATE INDEX idx_event_start ON local_calendar_events (start_ts)',
  );
  late final Index idxEventDeleted = Index(
    'idx_event_deleted',
    'CREATE INDEX idx_event_deleted ON local_calendar_events (deleted_at)',
  );
  late final FocusSessionDao focusSessionDao = FocusSessionDao(
    this as AppDatabase,
  );
  late final CalendarSourceDao calendarSourceDao = CalendarSourceDao(
    this as AppDatabase,
  );
  late final CalendarEventsDao calendarEventsDao = CalendarEventsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProfiles,
    localFocusSessions,
    localCalendarSources,
    localCalendarEvents,
    idxUserActiveSessions,
    idxSynced,
    idxUserSessionsByDate,
    idxUserSessionsByUpdatedAt,
    idxCalendarIncluded,
    idxCalendarEventWindow,
    idxEventStart,
    idxEventDeleted,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_focus_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_calendar_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_calendar_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      required String id,
      Value<String?> email,
      Value<String?> displayName,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<String> id,
      Value<String?> email,
      Value<String?> displayName,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$LocalProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfile> {
  $$LocalProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalFocusSessionsTable, List<LocalFocusSession>>
  _localFocusSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localFocusSessions,
        aliasName: $_aliasNameGenerator(
          db.localProfiles.id,
          db.localFocusSessions.userId,
        ),
      );

  $$LocalFocusSessionsTableProcessedTableManager get localFocusSessionsRefs {
    final manager = $$LocalFocusSessionsTableTableManager(
      $_db,
      $_db.localFocusSessions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localFocusSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localFocusSessionsRefs(
    Expression<bool> Function($$LocalFocusSessionsTableFilterComposer f) f,
  ) {
    final $$LocalFocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localFocusSessions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalFocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localFocusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> localFocusSessionsRefs<T extends Object>(
    Expression<T> Function($$LocalFocusSessionsTableAnnotationComposer a) f,
  ) {
    final $$LocalFocusSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localFocusSessions,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalFocusSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localFocusSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfilesTable,
          LocalProfile,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (LocalProfile, $$LocalProfilesTableReferences),
          LocalProfile,
          PrefetchHooks Function({bool localFocusSessionsRefs})
        > {
  $$LocalProfilesTableTableManager(_$AppDatabase db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion(
                id: id,
                email: email,
                displayName: displayName,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> email = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion.insert(
                id: id,
                email: email,
                displayName: displayName,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localFocusSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localFocusSessionsRefs) db.localFocusSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localFocusSessionsRefs)
                    await $_getPrefetchedData<
                      LocalProfile,
                      $LocalProfilesTable,
                      LocalFocusSession
                    >(
                      currentTable: table,
                      referencedTable: $$LocalProfilesTableReferences
                          ._localFocusSessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).localFocusSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfilesTable,
      LocalProfile,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (LocalProfile, $$LocalProfilesTableReferences),
      LocalProfile,
      PrefetchHooks Function({bool localFocusSessionsRefs})
    >;
typedef $$LocalFocusSessionsTableCreateCompanionBuilder =
    LocalFocusSessionsCompanion Function({
      required String id,
      required String userId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      required int plannedDurationMinutes,
      Value<int?> actualDurationMinutes,
      Value<String> sessionType,
      Value<bool> completed,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LocalFocusSessionsTableUpdateCompanionBuilder =
    LocalFocusSessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> plannedDurationMinutes,
      Value<int?> actualDurationMinutes,
      Value<String> sessionType,
      Value<bool> completed,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$LocalFocusSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalFocusSessionsTable,
          LocalFocusSession
        > {
  $$LocalFocusSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalProfilesTable _userIdTable(_$AppDatabase db) =>
      db.localProfiles.createAlias(
        $_aliasNameGenerator(db.localFocusSessions.userId, db.localProfiles.id),
      );

  $$LocalProfilesTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$LocalProfilesTableTableManager(
      $_db,
      $_db.localProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalFocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFocusSessionsTable> {
  $$LocalFocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalProfilesTableFilterComposer get userId {
    final $$LocalProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalProfilesTableFilterComposer(
            $db: $db,
            $table: $db.localProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalFocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFocusSessionsTable> {
  $$LocalFocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalProfilesTableOrderingComposer get userId {
    final $$LocalProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.localProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalFocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFocusSessionsTable> {
  $$LocalFocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  $$LocalProfilesTableAnnotationComposer get userId {
    final $$LocalProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.localProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalFocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFocusSessionsTable,
          LocalFocusSession,
          $$LocalFocusSessionsTableFilterComposer,
          $$LocalFocusSessionsTableOrderingComposer,
          $$LocalFocusSessionsTableAnnotationComposer,
          $$LocalFocusSessionsTableCreateCompanionBuilder,
          $$LocalFocusSessionsTableUpdateCompanionBuilder,
          (LocalFocusSession, $$LocalFocusSessionsTableReferences),
          LocalFocusSession,
          PrefetchHooks Function({bool userId})
        > {
  $$LocalFocusSessionsTableTableManager(
    _$AppDatabase db,
    $LocalFocusSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFocusSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> plannedDurationMinutes = const Value.absent(),
                Value<int?> actualDurationMinutes = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFocusSessionsCompanion(
                id: id,
                userId: userId,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedDurationMinutes: plannedDurationMinutes,
                actualDurationMinutes: actualDurationMinutes,
                sessionType: sessionType,
                completed: completed,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required int plannedDurationMinutes,
                Value<int?> actualDurationMinutes = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFocusSessionsCompanion.insert(
                id: id,
                userId: userId,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedDurationMinutes: plannedDurationMinutes,
                actualDurationMinutes: actualDurationMinutes,
                sessionType: sessionType,
                completed: completed,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalFocusSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$LocalFocusSessionsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$LocalFocusSessionsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalFocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFocusSessionsTable,
      LocalFocusSession,
      $$LocalFocusSessionsTableFilterComposer,
      $$LocalFocusSessionsTableOrderingComposer,
      $$LocalFocusSessionsTableAnnotationComposer,
      $$LocalFocusSessionsTableCreateCompanionBuilder,
      $$LocalFocusSessionsTableUpdateCompanionBuilder,
      (LocalFocusSession, $$LocalFocusSessionsTableReferences),
      LocalFocusSession,
      PrefetchHooks Function({bool userId})
    >;
typedef $$LocalCalendarSourcesTableCreateCompanionBuilder =
    LocalCalendarSourcesCompanion Function({
      required String id,
      required String name,
      Value<String?> accountName,
      Value<String?> accountType,
      Value<bool> isPrimary,
      Value<bool> included,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCalendarSourcesTableUpdateCompanionBuilder =
    LocalCalendarSourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> accountName,
      Value<String?> accountType,
      Value<bool> isPrimary,
      Value<bool> included,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalCalendarSourcesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalCalendarSourcesTable,
          LocalCalendarSource
        > {
  $$LocalCalendarSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $LocalCalendarEventsTable,
    List<LocalCalendarEvent>
  >
  _localCalendarEventsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localCalendarEvents,
        aliasName: $_aliasNameGenerator(
          db.localCalendarSources.id,
          db.localCalendarEvents.calendarId,
        ),
      );

  $$LocalCalendarEventsTableProcessedTableManager get localCalendarEventsRefs {
    final manager = $$LocalCalendarEventsTableTableManager(
      $_db,
      $_db.localCalendarEvents,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localCalendarEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalCalendarSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarSourcesTable> {
  $$LocalCalendarSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get included => $composableBuilder(
    column: $table.included,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localCalendarEventsRefs(
    Expression<bool> Function($$LocalCalendarEventsTableFilterComposer f) f,
  ) {
    final $$LocalCalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localCalendarEvents,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalCalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.localCalendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalCalendarSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarSourcesTable> {
  $$LocalCalendarSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get included => $composableBuilder(
    column: $table.included,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCalendarSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarSourcesTable> {
  $$LocalCalendarSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<bool> get included =>
      $composableBuilder(column: $table.included, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> localCalendarEventsRefs<T extends Object>(
    Expression<T> Function($$LocalCalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$LocalCalendarEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localCalendarEvents,
          getReferencedColumn: (t) => t.calendarId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalCalendarEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.localCalendarEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalCalendarSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarSourcesTable,
          LocalCalendarSource,
          $$LocalCalendarSourcesTableFilterComposer,
          $$LocalCalendarSourcesTableOrderingComposer,
          $$LocalCalendarSourcesTableAnnotationComposer,
          $$LocalCalendarSourcesTableCreateCompanionBuilder,
          $$LocalCalendarSourcesTableUpdateCompanionBuilder,
          (LocalCalendarSource, $$LocalCalendarSourcesTableReferences),
          LocalCalendarSource,
          PrefetchHooks Function({bool localCalendarEventsRefs})
        > {
  $$LocalCalendarSourcesTableTableManager(
    _$AppDatabase db,
    $LocalCalendarSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCalendarSourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCalendarSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String?> accountType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> included = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarSourcesCompanion(
                id: id,
                name: name,
                accountName: accountName,
                accountType: accountType,
                isPrimary: isPrimary,
                included: included,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> accountName = const Value.absent(),
                Value<String?> accountType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> included = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarSourcesCompanion.insert(
                id: id,
                name: name,
                accountName: accountName,
                accountType: accountType,
                isPrimary: isPrimary,
                included: included,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalCalendarSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localCalendarEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localCalendarEventsRefs) db.localCalendarEvents,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localCalendarEventsRefs)
                    await $_getPrefetchedData<
                      LocalCalendarSource,
                      $LocalCalendarSourcesTable,
                      LocalCalendarEvent
                    >(
                      currentTable: table,
                      referencedTable: $$LocalCalendarSourcesTableReferences
                          ._localCalendarEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalCalendarSourcesTableReferences(
                            db,
                            table,
                            p0,
                          ).localCalendarEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.calendarId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalCalendarSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarSourcesTable,
      LocalCalendarSource,
      $$LocalCalendarSourcesTableFilterComposer,
      $$LocalCalendarSourcesTableOrderingComposer,
      $$LocalCalendarSourcesTableAnnotationComposer,
      $$LocalCalendarSourcesTableCreateCompanionBuilder,
      $$LocalCalendarSourcesTableUpdateCompanionBuilder,
      (LocalCalendarSource, $$LocalCalendarSourcesTableReferences),
      LocalCalendarSource,
      PrefetchHooks Function({bool localCalendarEventsRefs})
    >;
typedef $$LocalCalendarEventsTableCreateCompanionBuilder =
    LocalCalendarEventsCompanion Function({
      required String eventId,
      required String calendarId,
      required BigInt instanceStartTs,
      required BigInt startTs,
      required BigInt endTs,
      Value<bool> isAllDay,
      Value<bool?> busyHint,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalCalendarEventsTableUpdateCompanionBuilder =
    LocalCalendarEventsCompanion Function({
      Value<String> eventId,
      Value<String> calendarId,
      Value<BigInt> instanceStartTs,
      Value<BigInt> startTs,
      Value<BigInt> endTs,
      Value<bool> isAllDay,
      Value<bool?> busyHint,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$LocalCalendarEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalCalendarEventsTable,
          LocalCalendarEvent
        > {
  $$LocalCalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalCalendarSourcesTable _calendarIdTable(_$AppDatabase db) =>
      db.localCalendarSources.createAlias(
        $_aliasNameGenerator(
          db.localCalendarEvents.calendarId,
          db.localCalendarSources.id,
        ),
      );

  $$LocalCalendarSourcesTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$LocalCalendarSourcesTableTableManager(
      $_db,
      $_db.localCalendarSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalCalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarEventsTable> {
  $$LocalCalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get instanceStartTs => $composableBuilder(
    column: $table.instanceStartTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get endTs => $composableBuilder(
    column: $table.endTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get busyHint => $composableBuilder(
    column: $table.busyHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalCalendarSourcesTableFilterComposer get calendarId {
    final $$LocalCalendarSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.localCalendarSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalCalendarSourcesTableFilterComposer(
            $db: $db,
            $table: $db.localCalendarSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalCalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarEventsTable> {
  $$LocalCalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get instanceStartTs => $composableBuilder(
    column: $table.instanceStartTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get startTs => $composableBuilder(
    column: $table.startTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get endTs => $composableBuilder(
    column: $table.endTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get busyHint => $composableBuilder(
    column: $table.busyHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalCalendarSourcesTableOrderingComposer get calendarId {
    final $$LocalCalendarSourcesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.calendarId,
          referencedTable: $db.localCalendarSources,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalCalendarSourcesTableOrderingComposer(
                $db: $db,
                $table: $db.localCalendarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalCalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarEventsTable> {
  $$LocalCalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<BigInt> get instanceStartTs => $composableBuilder(
    column: $table.instanceStartTs,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get startTs =>
      $composableBuilder(column: $table.startTs, builder: (column) => column);

  GeneratedColumn<BigInt> get endTs =>
      $composableBuilder(column: $table.endTs, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get busyHint =>
      $composableBuilder(column: $table.busyHint, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalCalendarSourcesTableAnnotationComposer get calendarId {
    final $$LocalCalendarSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.calendarId,
          referencedTable: $db.localCalendarSources,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalCalendarSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.localCalendarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalCalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarEventsTable,
          LocalCalendarEvent,
          $$LocalCalendarEventsTableFilterComposer,
          $$LocalCalendarEventsTableOrderingComposer,
          $$LocalCalendarEventsTableAnnotationComposer,
          $$LocalCalendarEventsTableCreateCompanionBuilder,
          $$LocalCalendarEventsTableUpdateCompanionBuilder,
          (LocalCalendarEvent, $$LocalCalendarEventsTableReferences),
          LocalCalendarEvent,
          PrefetchHooks Function({bool calendarId})
        > {
  $$LocalCalendarEventsTableTableManager(
    _$AppDatabase db,
    $LocalCalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCalendarEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCalendarEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<BigInt> instanceStartTs = const Value.absent(),
                Value<BigInt> startTs = const Value.absent(),
                Value<BigInt> endTs = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool?> busyHint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarEventsCompanion(
                eventId: eventId,
                calendarId: calendarId,
                instanceStartTs: instanceStartTs,
                startTs: startTs,
                endTs: endTs,
                isAllDay: isAllDay,
                busyHint: busyHint,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String calendarId,
                required BigInt instanceStartTs,
                required BigInt startTs,
                required BigInt endTs,
                Value<bool> isAllDay = const Value.absent(),
                Value<bool?> busyHint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarEventsCompanion.insert(
                eventId: eventId,
                calendarId: calendarId,
                instanceStartTs: instanceStartTs,
                startTs: startTs,
                endTs: endTs,
                isAllDay: isAllDay,
                busyHint: busyHint,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalCalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (calendarId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.calendarId,
                                referencedTable:
                                    $$LocalCalendarEventsTableReferences
                                        ._calendarIdTable(db),
                                referencedColumn:
                                    $$LocalCalendarEventsTableReferences
                                        ._calendarIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalCalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarEventsTable,
      LocalCalendarEvent,
      $$LocalCalendarEventsTableFilterComposer,
      $$LocalCalendarEventsTableOrderingComposer,
      $$LocalCalendarEventsTableAnnotationComposer,
      $$LocalCalendarEventsTableCreateCompanionBuilder,
      $$LocalCalendarEventsTableUpdateCompanionBuilder,
      (LocalCalendarEvent, $$LocalCalendarEventsTableReferences),
      LocalCalendarEvent,
      PrefetchHooks Function({bool calendarId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalFocusSessionsTableTableManager get localFocusSessions =>
      $$LocalFocusSessionsTableTableManager(_db, _db.localFocusSessions);
  $$LocalCalendarSourcesTableTableManager get localCalendarSources =>
      $$LocalCalendarSourcesTableTableManager(_db, _db.localCalendarSources);
  $$LocalCalendarEventsTableTableManager get localCalendarEvents =>
      $$LocalCalendarEventsTableTableManager(_db, _db.localCalendarEvents);
}

mixin _$FocusSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalProfilesTable get localProfiles => attachedDatabase.localProfiles;
  $LocalFocusSessionsTable get localFocusSessions =>
      attachedDatabase.localFocusSessions;
}
mixin _$CalendarSourceDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalCalendarSourcesTable get localCalendarSources =>
      attachedDatabase.localCalendarSources;
}
mixin _$CalendarEventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalCalendarSourcesTable get localCalendarSources =>
      attachedDatabase.localCalendarSources;
  $LocalCalendarEventsTable get localCalendarEvents =>
      attachedDatabase.localCalendarEvents;
}
