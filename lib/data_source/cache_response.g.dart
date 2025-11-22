// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_response.dart';

// ignore_for_file: type=lint
class $CacheResponseTable extends CacheResponse
    with TableInfo<$CacheResponseTable, CacheResponseData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheResponseTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _endPointMeta =
      const VerificationMeta('endPoint');
  @override
  late final GeneratedColumn<String> endPoint = GeneratedColumn<String>(
      'end_point', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _headerMeta = const VerificationMeta('header');
  @override
  late final GeneratedColumn<String> header = GeneratedColumn<String>(
      'header', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseMeta =
      const VerificationMeta('response');
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
      'response', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        endPoint,
        header,
        response,
        createdAt,
        cacheKey,
        metadata,
        expiresAt,
        lastAccessedAt,
        sizeBytes,
        schemaVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_response';
  @override
  VerificationContext validateIntegrity(Insertable<CacheResponseData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('end_point')) {
      context.handle(_endPointMeta,
          endPoint.isAcceptableOrUnknown(data['end_point']!, _endPointMeta));
    } else if (isInserting) {
      context.missing(_endPointMeta);
    }
    if (data.containsKey('header')) {
      context.handle(_headerMeta,
          header.isAcceptableOrUnknown(data['header']!, _headerMeta));
    } else if (isInserting) {
      context.missing(_headerMeta);
    }
    if (data.containsKey('response')) {
      context.handle(_responseMeta,
          response.isAcceptableOrUnknown(data['response']!, _responseMeta));
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheResponseData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheResponseData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      endPoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_point'])!,
      header: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}header'])!,
      response: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at']),
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}schema_version'])!,
    );
  }

  @override
  $CacheResponseTable createAlias(String alias) {
    return $CacheResponseTable(attachedDatabase, alias);
  }
}

class CacheResponseData extends DataClass
    implements Insertable<CacheResponseData> {
  final int id;
  final String endPoint;
  final String header;
  final String response;
  final DateTime createdAt;
  final String? cacheKey;
  final String? metadata;
  final DateTime? expiresAt;
  final DateTime? lastAccessedAt;
  final int sizeBytes;
  final int schemaVersion;
  const CacheResponseData(
      {required this.id,
      required this.endPoint,
      required this.header,
      required this.response,
      required this.createdAt,
      this.cacheKey,
      this.metadata,
      this.expiresAt,
      this.lastAccessedAt,
      required this.sizeBytes,
      required this.schemaVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['end_point'] = Variable<String>(endPoint);
    map['header'] = Variable<String>(header);
    map['response'] = Variable<String>(response);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || cacheKey != null) {
      map['cache_key'] = Variable<String>(cacheKey);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  CacheResponseCompanion toCompanion(bool nullToAbsent) {
    return CacheResponseCompanion(
      id: Value(id),
      endPoint: Value(endPoint),
      header: Value(header),
      response: Value(response),
      createdAt: Value(createdAt),
      cacheKey: cacheKey == null && nullToAbsent
          ? const Value.absent()
          : Value(cacheKey),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      sizeBytes: Value(sizeBytes),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory CacheResponseData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheResponseData(
      id: serializer.fromJson<int>(json['id']),
      endPoint: serializer.fromJson<String>(json['endPoint']),
      header: serializer.fromJson<String>(json['header']),
      response: serializer.fromJson<String>(json['response']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cacheKey: serializer.fromJson<String?>(json['cacheKey']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'endPoint': serializer.toJson<String>(endPoint),
      'header': serializer.toJson<String>(header),
      'response': serializer.toJson<String>(response),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cacheKey': serializer.toJson<String?>(cacheKey),
      'metadata': serializer.toJson<String?>(metadata),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  CacheResponseData copyWith(
          {int? id,
          String? endPoint,
          String? header,
          String? response,
          DateTime? createdAt,
          Value<String?> cacheKey = const Value.absent(),
          Value<String?> metadata = const Value.absent(),
          Value<DateTime?> expiresAt = const Value.absent(),
          Value<DateTime?> lastAccessedAt = const Value.absent(),
          int? sizeBytes,
          int? schemaVersion}) =>
      CacheResponseData(
        id: id ?? this.id,
        endPoint: endPoint ?? this.endPoint,
        header: header ?? this.header,
        response: response ?? this.response,
        createdAt: createdAt ?? this.createdAt,
        cacheKey: cacheKey.present ? cacheKey.value : this.cacheKey,
        metadata: metadata.present ? metadata.value : this.metadata,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        lastAccessedAt:
            lastAccessedAt.present ? lastAccessedAt.value : this.lastAccessedAt,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        schemaVersion: schemaVersion ?? this.schemaVersion,
      );
  CacheResponseData copyWithCompanion(CacheResponseCompanion data) {
    return CacheResponseData(
      id: data.id.present ? data.id.value : this.id,
      endPoint: data.endPoint.present ? data.endPoint.value : this.endPoint,
      header: data.header.present ? data.header.value : this.header,
      response: data.response.present ? data.response.value : this.response,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheResponseData(')
          ..write('id: $id, ')
          ..write('endPoint: $endPoint, ')
          ..write('header: $header, ')
          ..write('response: $response, ')
          ..write('createdAt: $createdAt, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('metadata: $metadata, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, endPoint, header, response, createdAt,
      cacheKey, metadata, expiresAt, lastAccessedAt, sizeBytes, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheResponseData &&
          other.id == this.id &&
          other.endPoint == this.endPoint &&
          other.header == this.header &&
          other.response == this.response &&
          other.createdAt == this.createdAt &&
          other.cacheKey == this.cacheKey &&
          other.metadata == this.metadata &&
          other.expiresAt == this.expiresAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.sizeBytes == this.sizeBytes &&
          other.schemaVersion == this.schemaVersion);
}

class CacheResponseCompanion extends UpdateCompanion<CacheResponseData> {
  final Value<int> id;
  final Value<String> endPoint;
  final Value<String> header;
  final Value<String> response;
  final Value<DateTime> createdAt;
  final Value<String?> cacheKey;
  final Value<String?> metadata;
  final Value<DateTime?> expiresAt;
  final Value<DateTime?> lastAccessedAt;
  final Value<int> sizeBytes;
  final Value<int> schemaVersion;
  const CacheResponseCompanion({
    this.id = const Value.absent(),
    this.endPoint = const Value.absent(),
    this.header = const Value.absent(),
    this.response = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.metadata = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  });
  CacheResponseCompanion.insert({
    this.id = const Value.absent(),
    required String endPoint,
    required String header,
    required String response,
    this.createdAt = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.metadata = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  })  : endPoint = Value(endPoint),
        header = Value(header),
        response = Value(response);
  static Insertable<CacheResponseData> custom({
    Expression<int>? id,
    Expression<String>? endPoint,
    Expression<String>? header,
    Expression<String>? response,
    Expression<DateTime>? createdAt,
    Expression<String>? cacheKey,
    Expression<String>? metadata,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? sizeBytes,
    Expression<int>? schemaVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endPoint != null) 'end_point': endPoint,
      if (header != null) 'header': header,
      if (response != null) 'response': response,
      if (createdAt != null) 'created_at': createdAt,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (metadata != null) 'metadata': metadata,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (schemaVersion != null) 'schema_version': schemaVersion,
    });
  }

  CacheResponseCompanion copyWith(
      {Value<int>? id,
      Value<String>? endPoint,
      Value<String>? header,
      Value<String>? response,
      Value<DateTime>? createdAt,
      Value<String?>? cacheKey,
      Value<String?>? metadata,
      Value<DateTime?>? expiresAt,
      Value<DateTime?>? lastAccessedAt,
      Value<int>? sizeBytes,
      Value<int>? schemaVersion}) {
    return CacheResponseCompanion(
      id: id ?? this.id,
      endPoint: endPoint ?? this.endPoint,
      header: header ?? this.header,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      cacheKey: cacheKey ?? this.cacheKey,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (endPoint.present) {
      map['end_point'] = Variable<String>(endPoint.value);
    }
    if (header.present) {
      map['header'] = Variable<String>(header.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheResponseCompanion(')
          ..write('id: $id, ')
          ..write('endPoint: $endPoint, ')
          ..write('header: $header, ')
          ..write('response: $response, ')
          ..write('createdAt: $createdAt, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('metadata: $metadata, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CacheResponseTable cacheResponse = $CacheResponseTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cacheResponse];
}

typedef $$CacheResponseTableCreateCompanionBuilder = CacheResponseCompanion
    Function({
  Value<int> id,
  required String endPoint,
  required String header,
  required String response,
  Value<DateTime> createdAt,
  Value<String?> cacheKey,
  Value<String?> metadata,
  Value<DateTime?> expiresAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> sizeBytes,
  Value<int> schemaVersion,
});
typedef $$CacheResponseTableUpdateCompanionBuilder = CacheResponseCompanion
    Function({
  Value<int> id,
  Value<String> endPoint,
  Value<String> header,
  Value<String> response,
  Value<DateTime> createdAt,
  Value<String?> cacheKey,
  Value<String?> metadata,
  Value<DateTime?> expiresAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> sizeBytes,
  Value<int> schemaVersion,
});

class $$CacheResponseTableFilterComposer
    extends Composer<_$AppDatabase, $CacheResponseTable> {
  $$CacheResponseTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endPoint => $composableBuilder(
      column: $table.endPoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get header => $composableBuilder(
      column: $table.header, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));
}

class $$CacheResponseTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheResponseTable> {
  $$CacheResponseTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endPoint => $composableBuilder(
      column: $table.endPoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get header => $composableBuilder(
      column: $table.header, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$CacheResponseTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheResponseTable> {
  $$CacheResponseTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get endPoint =>
      $composableBuilder(column: $table.endPoint, builder: (column) => column);

  GeneratedColumn<String> get header =>
      $composableBuilder(column: $table.header, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);
}

class $$CacheResponseTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CacheResponseTable,
    CacheResponseData,
    $$CacheResponseTableFilterComposer,
    $$CacheResponseTableOrderingComposer,
    $$CacheResponseTableAnnotationComposer,
    $$CacheResponseTableCreateCompanionBuilder,
    $$CacheResponseTableUpdateCompanionBuilder,
    (
      CacheResponseData,
      BaseReferences<_$AppDatabase, $CacheResponseTable, CacheResponseData>
    ),
    CacheResponseData,
    PrefetchHooks Function()> {
  $$CacheResponseTableTableManager(_$AppDatabase db, $CacheResponseTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheResponseTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheResponseTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheResponseTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> endPoint = const Value.absent(),
            Value<String> header = const Value.absent(),
            Value<String> response = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> cacheKey = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
          }) =>
              CacheResponseCompanion(
            id: id,
            endPoint: endPoint,
            header: header,
            response: response,
            createdAt: createdAt,
            cacheKey: cacheKey,
            metadata: metadata,
            expiresAt: expiresAt,
            lastAccessedAt: lastAccessedAt,
            sizeBytes: sizeBytes,
            schemaVersion: schemaVersion,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String endPoint,
            required String header,
            required String response,
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> cacheKey = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
          }) =>
              CacheResponseCompanion.insert(
            id: id,
            endPoint: endPoint,
            header: header,
            response: response,
            createdAt: createdAt,
            cacheKey: cacheKey,
            metadata: metadata,
            expiresAt: expiresAt,
            lastAccessedAt: lastAccessedAt,
            sizeBytes: sizeBytes,
            schemaVersion: schemaVersion,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CacheResponseTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CacheResponseTable,
    CacheResponseData,
    $$CacheResponseTableFilterComposer,
    $$CacheResponseTableOrderingComposer,
    $$CacheResponseTableAnnotationComposer,
    $$CacheResponseTableCreateCompanionBuilder,
    $$CacheResponseTableUpdateCompanionBuilder,
    (
      CacheResponseData,
      BaseReferences<_$AppDatabase, $CacheResponseTable, CacheResponseData>
    ),
    CacheResponseData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CacheResponseTableTableManager get cacheResponse =>
      $$CacheResponseTableTableManager(_db, _db.cacheResponse);
}
