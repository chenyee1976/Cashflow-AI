// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _googleIdMeta =
      const VerificationMeta('googleId');
  @override
  late final GeneratedColumn<String> googleId = GeneratedColumn<String>(
      'google_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rewardFocusMeta =
      const VerificationMeta('rewardFocus');
  @override
  late final GeneratedColumn<String> rewardFocus = GeneratedColumn<String>(
      'reward_focus', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyPrefMeta =
      const VerificationMeta('currencyPref');
  @override
  late final GeneratedColumn<String> currencyPref = GeneratedColumn<String>(
      'currency_pref', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('SGD'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastLoginAtMeta =
      const VerificationMeta('lastLoginAt');
  @override
  late final GeneratedColumn<int> lastLoginAt = GeneratedColumn<int>(
      'last_login_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionExpiresMeta =
      const VerificationMeta('sessionExpires');
  @override
  late final GeneratedColumn<int> sessionExpires = GeneratedColumn<int>(
      'session_expires', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        firstName,
        lastName,
        email,
        googleId,
        displayName,
        photoUrl,
        rewardFocus,
        currencyPref,
        createdAt,
        lastLoginAt,
        sessionExpires
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('google_id')) {
      context.handle(_googleIdMeta,
          googleId.isAcceptableOrUnknown(data['google_id']!, _googleIdMeta));
    } else if (isInserting) {
      context.missing(_googleIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('reward_focus')) {
      context.handle(
          _rewardFocusMeta,
          rewardFocus.isAcceptableOrUnknown(
              data['reward_focus']!, _rewardFocusMeta));
    }
    if (data.containsKey('currency_pref')) {
      context.handle(
          _currencyPrefMeta,
          currencyPref.isAcceptableOrUnknown(
              data['currency_pref']!, _currencyPrefMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
          _lastLoginAtMeta,
          lastLoginAt.isAcceptableOrUnknown(
              data['last_login_at']!, _lastLoginAtMeta));
    }
    if (data.containsKey('session_expires')) {
      context.handle(
          _sessionExpiresMeta,
          sessionExpires.isAcceptableOrUnknown(
              data['session_expires']!, _sessionExpiresMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      googleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}google_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      rewardFocus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reward_focus']),
      currencyPref: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_pref'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastLoginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_login_at']),
      sessionExpires: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_expires']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String googleId;
  final String? displayName;
  final String? photoUrl;
  final String? rewardFocus;
  final String currencyPref;
  final int createdAt;
  final int? lastLoginAt;
  final int? sessionExpires;
  const User(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.googleId,
      this.displayName,
      this.photoUrl,
      this.rewardFocus,
      required this.currencyPref,
      required this.createdAt,
      this.lastLoginAt,
      this.sessionExpires});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['email'] = Variable<String>(email);
    map['google_id'] = Variable<String>(googleId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || rewardFocus != null) {
      map['reward_focus'] = Variable<String>(rewardFocus);
    }
    map['currency_pref'] = Variable<String>(currencyPref);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<int>(lastLoginAt);
    }
    if (!nullToAbsent || sessionExpires != null) {
      map['session_expires'] = Variable<int>(sessionExpires);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: Value(email),
      googleId: Value(googleId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      rewardFocus: rewardFocus == null && nullToAbsent
          ? const Value.absent()
          : Value(rewardFocus),
      currencyPref: Value(currencyPref),
      createdAt: Value(createdAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
      sessionExpires: sessionExpires == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionExpires),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      email: serializer.fromJson<String>(json['email']),
      googleId: serializer.fromJson<String>(json['googleId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      rewardFocus: serializer.fromJson<String?>(json['rewardFocus']),
      currencyPref: serializer.fromJson<String>(json['currencyPref']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastLoginAt: serializer.fromJson<int?>(json['lastLoginAt']),
      sessionExpires: serializer.fromJson<int?>(json['sessionExpires']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'email': serializer.toJson<String>(email),
      'googleId': serializer.toJson<String>(googleId),
      'displayName': serializer.toJson<String?>(displayName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'rewardFocus': serializer.toJson<String?>(rewardFocus),
      'currencyPref': serializer.toJson<String>(currencyPref),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastLoginAt': serializer.toJson<int?>(lastLoginAt),
      'sessionExpires': serializer.toJson<int?>(sessionExpires),
    };
  }

  User copyWith(
          {String? id,
          String? firstName,
          String? lastName,
          String? email,
          String? googleId,
          Value<String?> displayName = const Value.absent(),
          Value<String?> photoUrl = const Value.absent(),
          Value<String?> rewardFocus = const Value.absent(),
          String? currencyPref,
          int? createdAt,
          Value<int?> lastLoginAt = const Value.absent(),
          Value<int?> sessionExpires = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        googleId: googleId ?? this.googleId,
        displayName: displayName.present ? displayName.value : this.displayName,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        rewardFocus: rewardFocus.present ? rewardFocus.value : this.rewardFocus,
        currencyPref: currencyPref ?? this.currencyPref,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
        sessionExpires:
            sessionExpires.present ? sessionExpires.value : this.sessionExpires,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      email: data.email.present ? data.email.value : this.email,
      googleId: data.googleId.present ? data.googleId.value : this.googleId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      rewardFocus:
          data.rewardFocus.present ? data.rewardFocus.value : this.rewardFocus,
      currencyPref: data.currencyPref.present
          ? data.currencyPref.value
          : this.currencyPref,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt:
          data.lastLoginAt.present ? data.lastLoginAt.value : this.lastLoginAt,
      sessionExpires: data.sessionExpires.present
          ? data.sessionExpires.value
          : this.sessionExpires,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('googleId: $googleId, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('rewardFocus: $rewardFocus, ')
          ..write('currencyPref: $currencyPref, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('sessionExpires: $sessionExpires')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      firstName,
      lastName,
      email,
      googleId,
      displayName,
      photoUrl,
      rewardFocus,
      currencyPref,
      createdAt,
      lastLoginAt,
      sessionExpires);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.email == this.email &&
          other.googleId == this.googleId &&
          other.displayName == this.displayName &&
          other.photoUrl == this.photoUrl &&
          other.rewardFocus == this.rewardFocus &&
          other.currencyPref == this.currencyPref &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt &&
          other.sessionExpires == this.sessionExpires);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> email;
  final Value<String> googleId;
  final Value<String?> displayName;
  final Value<String?> photoUrl;
  final Value<String?> rewardFocus;
  final Value<String> currencyPref;
  final Value<int> createdAt;
  final Value<int?> lastLoginAt;
  final Value<int?> sessionExpires;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.googleId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.rewardFocus = const Value.absent(),
    this.currencyPref = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.sessionExpires = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String googleId,
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.rewardFocus = const Value.absent(),
    this.currencyPref = const Value.absent(),
    required int createdAt,
    this.lastLoginAt = const Value.absent(),
    this.sessionExpires = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        firstName = Value(firstName),
        lastName = Value(lastName),
        email = Value(email),
        googleId = Value(googleId),
        createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? email,
    Expression<String>? googleId,
    Expression<String>? displayName,
    Expression<String>? photoUrl,
    Expression<String>? rewardFocus,
    Expression<String>? currencyPref,
    Expression<int>? createdAt,
    Expression<int>? lastLoginAt,
    Expression<int>? sessionExpires,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (googleId != null) 'google_id': googleId,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (rewardFocus != null) 'reward_focus': rewardFocus,
      if (currencyPref != null) 'currency_pref': currencyPref,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (sessionExpires != null) 'session_expires': sessionExpires,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String>? email,
      Value<String>? googleId,
      Value<String?>? displayName,
      Value<String?>? photoUrl,
      Value<String?>? rewardFocus,
      Value<String>? currencyPref,
      Value<int>? createdAt,
      Value<int?>? lastLoginAt,
      Value<int?>? sessionExpires,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      googleId: googleId ?? this.googleId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      rewardFocus: rewardFocus ?? this.rewardFocus,
      currencyPref: currencyPref ?? this.currencyPref,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      sessionExpires: sessionExpires ?? this.sessionExpires,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (googleId.present) {
      map['google_id'] = Variable<String>(googleId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (rewardFocus.present) {
      map['reward_focus'] = Variable<String>(rewardFocus.value);
    }
    if (currencyPref.present) {
      map['currency_pref'] = Variable<String>(currencyPref.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<int>(lastLoginAt.value);
    }
    if (sessionExpires.present) {
      map['session_expires'] = Variable<int>(sessionExpires.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('googleId: $googleId, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('rewardFocus: $rewardFocus, ')
          ..write('currencyPref: $currencyPref, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('sessionExpires: $sessionExpires, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BankAccountsTable extends BankAccounts
    with TableInfo<$BankAccountsTable, BankAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountNumberMeta =
      const VerificationMeta('accountNumber');
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
      'account_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingBalanceMeta =
      const VerificationMeta('openingBalance');
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
      'opening_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _currentBalanceMeta =
      const VerificationMeta('currentBalance');
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
      'current_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('SGD'));
  static const VerificationMeta _sourceStatementIdMeta =
      const VerificationMeta('sourceStatementId');
  @override
  late final GeneratedColumn<String> sourceStatementId =
      GeneratedColumn<String>('source_statement_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        bankName,
        accountType,
        accountNumber,
        openingBalance,
        currentBalance,
        currency,
        sourceStatementId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<BankAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('account_number')) {
      context.handle(
          _accountNumberMeta,
          accountNumber.isAcceptableOrUnknown(
              data['account_number']!, _accountNumberMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
          _openingBalanceMeta,
          openingBalance.isAcceptableOrUnknown(
              data['opening_balance']!, _openingBalanceMeta));
    }
    if (data.containsKey('current_balance')) {
      context.handle(
          _currentBalanceMeta,
          currentBalance.isAcceptableOrUnknown(
              data['current_balance']!, _currentBalanceMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('source_statement_id')) {
      context.handle(
          _sourceStatementIdMeta,
          sourceStatementId.isAcceptableOrUnknown(
              data['source_statement_id']!, _sourceStatementIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name'])!,
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      accountNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_number']),
      openingBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}opening_balance'])!,
      currentBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_balance'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      sourceStatementId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_statement_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BankAccountsTable createAlias(String alias) {
    return $BankAccountsTable(attachedDatabase, alias);
  }
}

class BankAccount extends DataClass implements Insertable<BankAccount> {
  final String id;
  final String userId;
  final String bankName;
  final String accountType;
  final String? accountNumber;
  final double openingBalance;
  final double currentBalance;
  final String currency;
  final String? sourceStatementId;
  final int createdAt;
  const BankAccount(
      {required this.id,
      required this.userId,
      required this.bankName,
      required this.accountType,
      this.accountNumber,
      required this.openingBalance,
      required this.currentBalance,
      required this.currency,
      this.sourceStatementId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['bank_name'] = Variable<String>(bankName);
    map['account_type'] = Variable<String>(accountType);
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    map['opening_balance'] = Variable<double>(openingBalance);
    map['current_balance'] = Variable<double>(currentBalance);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || sourceStatementId != null) {
      map['source_statement_id'] = Variable<String>(sourceStatementId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BankAccountsCompanion toCompanion(bool nullToAbsent) {
    return BankAccountsCompanion(
      id: Value(id),
      userId: Value(userId),
      bankName: Value(bankName),
      accountType: Value(accountType),
      accountNumber: accountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumber),
      openingBalance: Value(openingBalance),
      currentBalance: Value(currentBalance),
      currency: Value(currency),
      sourceStatementId: sourceStatementId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceStatementId),
      createdAt: Value(createdAt),
    );
  }

  factory BankAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankAccount(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      bankName: serializer.fromJson<String>(json['bankName']),
      accountType: serializer.fromJson<String>(json['accountType']),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      currency: serializer.fromJson<String>(json['currency']),
      sourceStatementId:
          serializer.fromJson<String?>(json['sourceStatementId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'bankName': serializer.toJson<String>(bankName),
      'accountType': serializer.toJson<String>(accountType),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'currency': serializer.toJson<String>(currency),
      'sourceStatementId': serializer.toJson<String?>(sourceStatementId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BankAccount copyWith(
          {String? id,
          String? userId,
          String? bankName,
          String? accountType,
          Value<String?> accountNumber = const Value.absent(),
          double? openingBalance,
          double? currentBalance,
          String? currency,
          Value<String?> sourceStatementId = const Value.absent(),
          int? createdAt}) =>
      BankAccount(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        bankName: bankName ?? this.bankName,
        accountType: accountType ?? this.accountType,
        accountNumber:
            accountNumber.present ? accountNumber.value : this.accountNumber,
        openingBalance: openingBalance ?? this.openingBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        currency: currency ?? this.currency,
        sourceStatementId: sourceStatementId.present
            ? sourceStatementId.value
            : this.sourceStatementId,
        createdAt: createdAt ?? this.createdAt,
      );
  BankAccount copyWithCompanion(BankAccountsCompanion data) {
    return BankAccount(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      currency: data.currency.present ? data.currency.value : this.currency,
      sourceStatementId: data.sourceStatementId.present
          ? data.sourceStatementId.value
          : this.sourceStatementId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankAccount(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('currency: $currency, ')
          ..write('sourceStatementId: $sourceStatementId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      bankName,
      accountType,
      accountNumber,
      openingBalance,
      currentBalance,
      currency,
      sourceStatementId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankAccount &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.bankName == this.bankName &&
          other.accountType == this.accountType &&
          other.accountNumber == this.accountNumber &&
          other.openingBalance == this.openingBalance &&
          other.currentBalance == this.currentBalance &&
          other.currency == this.currency &&
          other.sourceStatementId == this.sourceStatementId &&
          other.createdAt == this.createdAt);
}

class BankAccountsCompanion extends UpdateCompanion<BankAccount> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> bankName;
  final Value<String> accountType;
  final Value<String?> accountNumber;
  final Value<double> openingBalance;
  final Value<double> currentBalance;
  final Value<String> currency;
  final Value<String?> sourceStatementId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BankAccountsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.sourceStatementId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BankAccountsCompanion.insert({
    required String id,
    required String userId,
    required String bankName,
    required String accountType,
    this.accountNumber = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.sourceStatementId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        bankName = Value(bankName),
        accountType = Value(accountType),
        createdAt = Value(createdAt);
  static Insertable<BankAccount> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? bankName,
    Expression<String>? accountType,
    Expression<String>? accountNumber,
    Expression<double>? openingBalance,
    Expression<double>? currentBalance,
    Expression<String>? currency,
    Expression<String>? sourceStatementId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (bankName != null) 'bank_name': bankName,
      if (accountType != null) 'account_type': accountType,
      if (accountNumber != null) 'account_number': accountNumber,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (currency != null) 'currency': currency,
      if (sourceStatementId != null) 'source_statement_id': sourceStatementId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BankAccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? bankName,
      Value<String>? accountType,
      Value<String?>? accountNumber,
      Value<double>? openingBalance,
      Value<double>? currentBalance,
      Value<String>? currency,
      Value<String?>? sourceStatementId,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return BankAccountsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      sourceStatementId: sourceStatementId ?? this.sourceStatementId,
      createdAt: createdAt ?? this.createdAt,
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
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (sourceStatementId.present) {
      map['source_statement_id'] = Variable<String>(sourceStatementId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('currency: $currency, ')
          ..write('sourceStatementId: $sourceStatementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTable extends CreditCards
    with TableInfo<$CreditCardsTable, CreditCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardNameMeta =
      const VerificationMeta('cardName');
  @override
  late final GeneratedColumn<String> cardName = GeneratedColumn<String>(
      'card_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardTypeMeta =
      const VerificationMeta('cardType');
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
      'card_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rewardTypeMeta =
      const VerificationMeta('rewardType');
  @override
  late final GeneratedColumn<String> rewardType = GeneratedColumn<String>(
      'reward_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastFourMeta =
      const VerificationMeta('lastFour');
  @override
  late final GeneratedColumn<String> lastFour = GeneratedColumn<String>(
      'last_four', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceStatementIdMeta =
      const VerificationMeta('sourceStatementId');
  @override
  late final GeneratedColumn<String> sourceStatementId =
      GeneratedColumn<String>('source_statement_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        bankName,
        cardName,
        cardType,
        rewardType,
        lastFour,
        sourceStatementId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(Insertable<CreditCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('card_name')) {
      context.handle(_cardNameMeta,
          cardName.isAcceptableOrUnknown(data['card_name']!, _cardNameMeta));
    } else if (isInserting) {
      context.missing(_cardNameMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(_cardTypeMeta,
          cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta));
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('reward_type')) {
      context.handle(
          _rewardTypeMeta,
          rewardType.isAcceptableOrUnknown(
              data['reward_type']!, _rewardTypeMeta));
    } else if (isInserting) {
      context.missing(_rewardTypeMeta);
    }
    if (data.containsKey('last_four')) {
      context.handle(_lastFourMeta,
          lastFour.isAcceptableOrUnknown(data['last_four']!, _lastFourMeta));
    }
    if (data.containsKey('source_statement_id')) {
      context.handle(
          _sourceStatementIdMeta,
          sourceStatementId.isAcceptableOrUnknown(
              data['source_statement_id']!, _sourceStatementIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name'])!,
      cardName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_name'])!,
      cardType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_type'])!,
      rewardType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reward_type'])!,
      lastFour: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_four']),
      sourceStatementId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_statement_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CreditCardsTable createAlias(String alias) {
    return $CreditCardsTable(attachedDatabase, alias);
  }
}

class CreditCard extends DataClass implements Insertable<CreditCard> {
  final String id;
  final String userId;
  final String bankName;
  final String cardName;
  final String cardType;
  final String rewardType;
  final String? lastFour;
  final String? sourceStatementId;
  final int createdAt;
  const CreditCard(
      {required this.id,
      required this.userId,
      required this.bankName,
      required this.cardName,
      required this.cardType,
      required this.rewardType,
      this.lastFour,
      this.sourceStatementId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['bank_name'] = Variable<String>(bankName);
    map['card_name'] = Variable<String>(cardName);
    map['card_type'] = Variable<String>(cardType);
    map['reward_type'] = Variable<String>(rewardType);
    if (!nullToAbsent || lastFour != null) {
      map['last_four'] = Variable<String>(lastFour);
    }
    if (!nullToAbsent || sourceStatementId != null) {
      map['source_statement_id'] = Variable<String>(sourceStatementId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CreditCardsCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsCompanion(
      id: Value(id),
      userId: Value(userId),
      bankName: Value(bankName),
      cardName: Value(cardName),
      cardType: Value(cardType),
      rewardType: Value(rewardType),
      lastFour: lastFour == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFour),
      sourceStatementId: sourceStatementId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceStatementId),
      createdAt: Value(createdAt),
    );
  }

  factory CreditCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      bankName: serializer.fromJson<String>(json['bankName']),
      cardName: serializer.fromJson<String>(json['cardName']),
      cardType: serializer.fromJson<String>(json['cardType']),
      rewardType: serializer.fromJson<String>(json['rewardType']),
      lastFour: serializer.fromJson<String?>(json['lastFour']),
      sourceStatementId:
          serializer.fromJson<String?>(json['sourceStatementId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'bankName': serializer.toJson<String>(bankName),
      'cardName': serializer.toJson<String>(cardName),
      'cardType': serializer.toJson<String>(cardType),
      'rewardType': serializer.toJson<String>(rewardType),
      'lastFour': serializer.toJson<String?>(lastFour),
      'sourceStatementId': serializer.toJson<String?>(sourceStatementId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CreditCard copyWith(
          {String? id,
          String? userId,
          String? bankName,
          String? cardName,
          String? cardType,
          String? rewardType,
          Value<String?> lastFour = const Value.absent(),
          Value<String?> sourceStatementId = const Value.absent(),
          int? createdAt}) =>
      CreditCard(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        bankName: bankName ?? this.bankName,
        cardName: cardName ?? this.cardName,
        cardType: cardType ?? this.cardType,
        rewardType: rewardType ?? this.rewardType,
        lastFour: lastFour.present ? lastFour.value : this.lastFour,
        sourceStatementId: sourceStatementId.present
            ? sourceStatementId.value
            : this.sourceStatementId,
        createdAt: createdAt ?? this.createdAt,
      );
  CreditCard copyWithCompanion(CreditCardsCompanion data) {
    return CreditCard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      cardName: data.cardName.present ? data.cardName.value : this.cardName,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      rewardType:
          data.rewardType.present ? data.rewardType.value : this.rewardType,
      lastFour: data.lastFour.present ? data.lastFour.value : this.lastFour,
      sourceStatementId: data.sourceStatementId.present
          ? data.sourceStatementId.value
          : this.sourceStatementId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('bankName: $bankName, ')
          ..write('cardName: $cardName, ')
          ..write('cardType: $cardType, ')
          ..write('rewardType: $rewardType, ')
          ..write('lastFour: $lastFour, ')
          ..write('sourceStatementId: $sourceStatementId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, bankName, cardName, cardType,
      rewardType, lastFour, sourceStatementId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.bankName == this.bankName &&
          other.cardName == this.cardName &&
          other.cardType == this.cardType &&
          other.rewardType == this.rewardType &&
          other.lastFour == this.lastFour &&
          other.sourceStatementId == this.sourceStatementId &&
          other.createdAt == this.createdAt);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> bankName;
  final Value<String> cardName;
  final Value<String> cardType;
  final Value<String> rewardType;
  final Value<String?> lastFour;
  final Value<String?> sourceStatementId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.bankName = const Value.absent(),
    this.cardName = const Value.absent(),
    this.cardType = const Value.absent(),
    this.rewardType = const Value.absent(),
    this.lastFour = const Value.absent(),
    this.sourceStatementId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditCardsCompanion.insert({
    required String id,
    required String userId,
    required String bankName,
    required String cardName,
    required String cardType,
    required String rewardType,
    this.lastFour = const Value.absent(),
    this.sourceStatementId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        bankName = Value(bankName),
        cardName = Value(cardName),
        cardType = Value(cardType),
        rewardType = Value(rewardType),
        createdAt = Value(createdAt);
  static Insertable<CreditCard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? bankName,
    Expression<String>? cardName,
    Expression<String>? cardType,
    Expression<String>? rewardType,
    Expression<String>? lastFour,
    Expression<String>? sourceStatementId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (bankName != null) 'bank_name': bankName,
      if (cardName != null) 'card_name': cardName,
      if (cardType != null) 'card_type': cardType,
      if (rewardType != null) 'reward_type': rewardType,
      if (lastFour != null) 'last_four': lastFour,
      if (sourceStatementId != null) 'source_statement_id': sourceStatementId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditCardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? bankName,
      Value<String>? cardName,
      Value<String>? cardType,
      Value<String>? rewardType,
      Value<String?>? lastFour,
      Value<String?>? sourceStatementId,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return CreditCardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      cardType: cardType ?? this.cardType,
      rewardType: rewardType ?? this.rewardType,
      lastFour: lastFour ?? this.lastFour,
      sourceStatementId: sourceStatementId ?? this.sourceStatementId,
      createdAt: createdAt ?? this.createdAt,
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
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (cardName.present) {
      map['card_name'] = Variable<String>(cardName.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (rewardType.present) {
      map['reward_type'] = Variable<String>(rewardType.value);
    }
    if (lastFour.present) {
      map['last_four'] = Variable<String>(lastFour.value);
    }
    if (sourceStatementId.present) {
      map['source_statement_id'] = Variable<String>(sourceStatementId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('bankName: $bankName, ')
          ..write('cardName: $cardName, ')
          ..write('cardType: $cardType, ')
          ..write('rewardType: $rewardType, ')
          ..write('lastFour: $lastFour, ')
          ..write('sourceStatementId: $sourceStatementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StatementsTable extends Statements
    with TableInfo<$StatementsTable, Statement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileTypeMeta =
      const VerificationMeta('fileType');
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
      'file_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fileHashMeta =
      const VerificationMeta('fileHash');
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
      'file_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankOrCardMeta =
      const VerificationMeta('bankOrCard');
  @override
  late final GeneratedColumn<String> bankOrCard = GeneratedColumn<String>(
      'bank_or_card', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<int> periodStart = GeneratedColumn<int>(
      'period_start', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _periodEndMeta =
      const VerificationMeta('periodEnd');
  @override
  late final GeneratedColumn<int> periodEnd = GeneratedColumn<int>(
      'period_end', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _aiModelUsedMeta =
      const VerificationMeta('aiModelUsed');
  @override
  late final GeneratedColumn<String> aiModelUsed = GeneratedColumn<String>(
      'ai_model_used', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionCountMeta =
      const VerificationMeta('transactionCount');
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
      'transaction_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<int> uploadedAt = GeneratedColumn<int>(
      'uploaded_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _processedAtMeta =
      const VerificationMeta('processedAt');
  @override
  late final GeneratedColumn<int> processedAt = GeneratedColumn<int>(
      'processed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        fileName,
        filePath,
        fileType,
        fileSizeBytes,
        fileHash,
        bankOrCard,
        accountType,
        periodStart,
        periodEnd,
        status,
        aiModelUsed,
        transactionCount,
        uploadedAt,
        processedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statements';
  @override
  VerificationContext validateIntegrity(Insertable<Statement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(_fileTypeMeta,
          fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta));
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(_fileHashMeta,
          fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta));
    }
    if (data.containsKey('bank_or_card')) {
      context.handle(
          _bankOrCardMeta,
          bankOrCard.isAcceptableOrUnknown(
              data['bank_or_card']!, _bankOrCardMeta));
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    }
    if (data.containsKey('period_end')) {
      context.handle(_periodEndMeta,
          periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('ai_model_used')) {
      context.handle(
          _aiModelUsedMeta,
          aiModelUsed.isAcceptableOrUnknown(
              data['ai_model_used']!, _aiModelUsedMeta));
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
          _transactionCountMeta,
          transactionCount.isAcceptableOrUnknown(
              data['transaction_count']!, _transactionCountMeta));
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    } else if (isInserting) {
      context.missing(_uploadedAtMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
          _processedAtMeta,
          processedAt.isAcceptableOrUnknown(
              data['processed_at']!, _processedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Statement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Statement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_type'])!,
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      fileHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_hash']),
      bankOrCard: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_or_card']),
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type']),
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_start']),
      periodEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_end']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      aiModelUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_model_used']),
      transactionCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_count'])!,
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uploaded_at'])!,
      processedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}processed_at']),
    );
  }

  @override
  $StatementsTable createAlias(String alias) {
    return $StatementsTable(attachedDatabase, alias);
  }
}

class Statement extends DataClass implements Insertable<Statement> {
  final String id;
  final String userId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSizeBytes;
  final String? fileHash;
  final String? bankOrCard;
  final String? accountType;
  final int? periodStart;
  final int? periodEnd;
  final String status;
  final String? aiModelUsed;
  final int transactionCount;
  final int uploadedAt;
  final int? processedAt;
  const Statement(
      {required this.id,
      required this.userId,
      required this.fileName,
      required this.filePath,
      required this.fileType,
      required this.fileSizeBytes,
      this.fileHash,
      this.bankOrCard,
      this.accountType,
      this.periodStart,
      this.periodEnd,
      required this.status,
      this.aiModelUsed,
      required this.transactionCount,
      required this.uploadedAt,
      this.processedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    if (!nullToAbsent || bankOrCard != null) {
      map['bank_or_card'] = Variable<String>(bankOrCard);
    }
    if (!nullToAbsent || accountType != null) {
      map['account_type'] = Variable<String>(accountType);
    }
    if (!nullToAbsent || periodStart != null) {
      map['period_start'] = Variable<int>(periodStart);
    }
    if (!nullToAbsent || periodEnd != null) {
      map['period_end'] = Variable<int>(periodEnd);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || aiModelUsed != null) {
      map['ai_model_used'] = Variable<String>(aiModelUsed);
    }
    map['transaction_count'] = Variable<int>(transactionCount);
    map['uploaded_at'] = Variable<int>(uploadedAt);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<int>(processedAt);
    }
    return map;
  }

  StatementsCompanion toCompanion(bool nullToAbsent) {
    return StatementsCompanion(
      id: Value(id),
      userId: Value(userId),
      fileName: Value(fileName),
      filePath: Value(filePath),
      fileType: Value(fileType),
      fileSizeBytes: Value(fileSizeBytes),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      bankOrCard: bankOrCard == null && nullToAbsent
          ? const Value.absent()
          : Value(bankOrCard),
      accountType: accountType == null && nullToAbsent
          ? const Value.absent()
          : Value(accountType),
      periodStart: periodStart == null && nullToAbsent
          ? const Value.absent()
          : Value(periodStart),
      periodEnd: periodEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(periodEnd),
      status: Value(status),
      aiModelUsed: aiModelUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(aiModelUsed),
      transactionCount: Value(transactionCount),
      uploadedAt: Value(uploadedAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
    );
  }

  factory Statement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Statement(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      bankOrCard: serializer.fromJson<String?>(json['bankOrCard']),
      accountType: serializer.fromJson<String?>(json['accountType']),
      periodStart: serializer.fromJson<int?>(json['periodStart']),
      periodEnd: serializer.fromJson<int?>(json['periodEnd']),
      status: serializer.fromJson<String>(json['status']),
      aiModelUsed: serializer.fromJson<String?>(json['aiModelUsed']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      uploadedAt: serializer.fromJson<int>(json['uploadedAt']),
      processedAt: serializer.fromJson<int?>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'fileHash': serializer.toJson<String?>(fileHash),
      'bankOrCard': serializer.toJson<String?>(bankOrCard),
      'accountType': serializer.toJson<String?>(accountType),
      'periodStart': serializer.toJson<int?>(periodStart),
      'periodEnd': serializer.toJson<int?>(periodEnd),
      'status': serializer.toJson<String>(status),
      'aiModelUsed': serializer.toJson<String?>(aiModelUsed),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'uploadedAt': serializer.toJson<int>(uploadedAt),
      'processedAt': serializer.toJson<int?>(processedAt),
    };
  }

  Statement copyWith(
          {String? id,
          String? userId,
          String? fileName,
          String? filePath,
          String? fileType,
          int? fileSizeBytes,
          Value<String?> fileHash = const Value.absent(),
          Value<String?> bankOrCard = const Value.absent(),
          Value<String?> accountType = const Value.absent(),
          Value<int?> periodStart = const Value.absent(),
          Value<int?> periodEnd = const Value.absent(),
          String? status,
          Value<String?> aiModelUsed = const Value.absent(),
          int? transactionCount,
          int? uploadedAt,
          Value<int?> processedAt = const Value.absent()}) =>
      Statement(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        fileType: fileType ?? this.fileType,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        fileHash: fileHash.present ? fileHash.value : this.fileHash,
        bankOrCard: bankOrCard.present ? bankOrCard.value : this.bankOrCard,
        accountType: accountType.present ? accountType.value : this.accountType,
        periodStart: periodStart.present ? periodStart.value : this.periodStart,
        periodEnd: periodEnd.present ? periodEnd.value : this.periodEnd,
        status: status ?? this.status,
        aiModelUsed: aiModelUsed.present ? aiModelUsed.value : this.aiModelUsed,
        transactionCount: transactionCount ?? this.transactionCount,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        processedAt: processedAt.present ? processedAt.value : this.processedAt,
      );
  Statement copyWithCompanion(StatementsCompanion data) {
    return Statement(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      bankOrCard:
          data.bankOrCard.present ? data.bankOrCard.value : this.bankOrCard,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      status: data.status.present ? data.status.value : this.status,
      aiModelUsed:
          data.aiModelUsed.present ? data.aiModelUsed.value : this.aiModelUsed,
      transactionCount: data.transactionCount.present
          ? data.transactionCount.value
          : this.transactionCount,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
      processedAt:
          data.processedAt.present ? data.processedAt.value : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Statement(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('fileHash: $fileHash, ')
          ..write('bankOrCard: $bankOrCard, ')
          ..write('accountType: $accountType, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('status: $status, ')
          ..write('aiModelUsed: $aiModelUsed, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      fileName,
      filePath,
      fileType,
      fileSizeBytes,
      fileHash,
      bankOrCard,
      accountType,
      periodStart,
      periodEnd,
      status,
      aiModelUsed,
      transactionCount,
      uploadedAt,
      processedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Statement &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.fileHash == this.fileHash &&
          other.bankOrCard == this.bankOrCard &&
          other.accountType == this.accountType &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.status == this.status &&
          other.aiModelUsed == this.aiModelUsed &&
          other.transactionCount == this.transactionCount &&
          other.uploadedAt == this.uploadedAt &&
          other.processedAt == this.processedAt);
}

class StatementsCompanion extends UpdateCompanion<Statement> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<int> fileSizeBytes;
  final Value<String?> fileHash;
  final Value<String?> bankOrCard;
  final Value<String?> accountType;
  final Value<int?> periodStart;
  final Value<int?> periodEnd;
  final Value<String> status;
  final Value<String?> aiModelUsed;
  final Value<int> transactionCount;
  final Value<int> uploadedAt;
  final Value<int?> processedAt;
  final Value<int> rowid;
  const StatementsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.bankOrCard = const Value.absent(),
    this.accountType = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.aiModelUsed = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatementsCompanion.insert({
    required String id,
    required String userId,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSizeBytes,
    this.fileHash = const Value.absent(),
    this.bankOrCard = const Value.absent(),
    this.accountType = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.aiModelUsed = const Value.absent(),
    this.transactionCount = const Value.absent(),
    required int uploadedAt,
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        fileName = Value(fileName),
        filePath = Value(filePath),
        fileType = Value(fileType),
        fileSizeBytes = Value(fileSizeBytes),
        uploadedAt = Value(uploadedAt);
  static Insertable<Statement> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<int>? fileSizeBytes,
    Expression<String>? fileHash,
    Expression<String>? bankOrCard,
    Expression<String>? accountType,
    Expression<int>? periodStart,
    Expression<int>? periodEnd,
    Expression<String>? status,
    Expression<String>? aiModelUsed,
    Expression<int>? transactionCount,
    Expression<int>? uploadedAt,
    Expression<int>? processedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (fileHash != null) 'file_hash': fileHash,
      if (bankOrCard != null) 'bank_or_card': bankOrCard,
      if (accountType != null) 'account_type': accountType,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (status != null) 'status': status,
      if (aiModelUsed != null) 'ai_model_used': aiModelUsed,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? fileName,
      Value<String>? filePath,
      Value<String>? fileType,
      Value<int>? fileSizeBytes,
      Value<String?>? fileHash,
      Value<String?>? bankOrCard,
      Value<String?>? accountType,
      Value<int?>? periodStart,
      Value<int?>? periodEnd,
      Value<String>? status,
      Value<String?>? aiModelUsed,
      Value<int>? transactionCount,
      Value<int>? uploadedAt,
      Value<int?>? processedAt,
      Value<int>? rowid}) {
    return StatementsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileHash: fileHash ?? this.fileHash,
      bankOrCard: bankOrCard ?? this.bankOrCard,
      accountType: accountType ?? this.accountType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      aiModelUsed: aiModelUsed ?? this.aiModelUsed,
      transactionCount: transactionCount ?? this.transactionCount,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      processedAt: processedAt ?? this.processedAt,
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
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (bankOrCard.present) {
      map['bank_or_card'] = Variable<String>(bankOrCard.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<int>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<int>(periodEnd.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (aiModelUsed.present) {
      map['ai_model_used'] = Variable<String>(aiModelUsed.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<int>(uploadedAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<int>(processedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatementsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('fileHash: $fileHash, ')
          ..write('bankOrCard: $bankOrCard, ')
          ..write('accountType: $accountType, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('status: $status, ')
          ..write('aiModelUsed: $aiModelUsed, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _merchantMeta =
      const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
      'merchant', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('SGD'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mccCodeMeta =
      const VerificationMeta('mccCode');
  @override
  late final GeneratedColumn<String> mccCode = GeneratedColumn<String>(
      'mcc_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _milesEarnedMeta =
      const VerificationMeta('milesEarned');
  @override
  late final GeneratedColumn<double> milesEarned = GeneratedColumn<double>(
      'miles_earned', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _cashbackEarnedMeta =
      const VerificationMeta('cashbackEarned');
  @override
  late final GeneratedColumn<double> cashbackEarned = GeneratedColumn<double>(
      'cashback_earned', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _statementIdMeta =
      const VerificationMeta('statementId');
  @override
  late final GeneratedColumn<String> statementId = GeneratedColumn<String>(
      'statement_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES statements (id)'));
  static const VerificationMeta _aiConfidenceMeta =
      const VerificationMeta('aiConfidence');
  @override
  late final GeneratedColumn<double> aiConfidence = GeneratedColumn<double>(
      'ai_confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _userCorrectedMeta =
      const VerificationMeta('userCorrected');
  @override
  late final GeneratedColumn<int> userCorrected = GeneratedColumn<int>(
      'user_corrected', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        accountId,
        accountType,
        date,
        merchant,
        description,
        amount,
        currency,
        category,
        mccCode,
        milesEarned,
        cashbackEarned,
        statementId,
        aiConfidence,
        userCorrected,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta,
          merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('mcc_code')) {
      context.handle(_mccCodeMeta,
          mccCode.isAcceptableOrUnknown(data['mcc_code']!, _mccCodeMeta));
    }
    if (data.containsKey('miles_earned')) {
      context.handle(
          _milesEarnedMeta,
          milesEarned.isAcceptableOrUnknown(
              data['miles_earned']!, _milesEarnedMeta));
    }
    if (data.containsKey('cashback_earned')) {
      context.handle(
          _cashbackEarnedMeta,
          cashbackEarned.isAcceptableOrUnknown(
              data['cashback_earned']!, _cashbackEarnedMeta));
    }
    if (data.containsKey('statement_id')) {
      context.handle(
          _statementIdMeta,
          statementId.isAcceptableOrUnknown(
              data['statement_id']!, _statementIdMeta));
    }
    if (data.containsKey('ai_confidence')) {
      context.handle(
          _aiConfidenceMeta,
          aiConfidence.isAcceptableOrUnknown(
              data['ai_confidence']!, _aiConfidenceMeta));
    }
    if (data.containsKey('user_corrected')) {
      context.handle(
          _userCorrectedMeta,
          userCorrected.isAcceptableOrUnknown(
              data['user_corrected']!, _userCorrectedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      merchant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      mccCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mcc_code']),
      milesEarned: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}miles_earned'])!,
      cashbackEarned: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}cashback_earned'])!,
      statementId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}statement_id']),
      aiConfidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ai_confidence']),
      userCorrected: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_corrected'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String userId;
  final String accountId;
  final String accountType;
  final int date;
  final String merchant;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String? mccCode;
  final double milesEarned;
  final double cashbackEarned;
  final String? statementId;
  final double? aiConfidence;
  final int userCorrected;
  final int createdAt;
  const Transaction(
      {required this.id,
      required this.userId,
      required this.accountId,
      required this.accountType,
      required this.date,
      required this.merchant,
      required this.description,
      required this.amount,
      required this.currency,
      required this.category,
      this.mccCode,
      required this.milesEarned,
      required this.cashbackEarned,
      this.statementId,
      this.aiConfidence,
      required this.userCorrected,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['account_id'] = Variable<String>(accountId);
    map['account_type'] = Variable<String>(accountType);
    map['date'] = Variable<int>(date);
    map['merchant'] = Variable<String>(merchant);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || mccCode != null) {
      map['mcc_code'] = Variable<String>(mccCode);
    }
    map['miles_earned'] = Variable<double>(milesEarned);
    map['cashback_earned'] = Variable<double>(cashbackEarned);
    if (!nullToAbsent || statementId != null) {
      map['statement_id'] = Variable<String>(statementId);
    }
    if (!nullToAbsent || aiConfidence != null) {
      map['ai_confidence'] = Variable<double>(aiConfidence);
    }
    map['user_corrected'] = Variable<int>(userCorrected);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: Value(accountId),
      accountType: Value(accountType),
      date: Value(date),
      merchant: Value(merchant),
      description: Value(description),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      mccCode: mccCode == null && nullToAbsent
          ? const Value.absent()
          : Value(mccCode),
      milesEarned: Value(milesEarned),
      cashbackEarned: Value(cashbackEarned),
      statementId: statementId == null && nullToAbsent
          ? const Value.absent()
          : Value(statementId),
      aiConfidence: aiConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(aiConfidence),
      userCorrected: Value(userCorrected),
      createdAt: Value(createdAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      accountType: serializer.fromJson<String>(json['accountType']),
      date: serializer.fromJson<int>(json['date']),
      merchant: serializer.fromJson<String>(json['merchant']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      mccCode: serializer.fromJson<String?>(json['mccCode']),
      milesEarned: serializer.fromJson<double>(json['milesEarned']),
      cashbackEarned: serializer.fromJson<double>(json['cashbackEarned']),
      statementId: serializer.fromJson<String?>(json['statementId']),
      aiConfidence: serializer.fromJson<double?>(json['aiConfidence']),
      userCorrected: serializer.fromJson<int>(json['userCorrected']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'accountId': serializer.toJson<String>(accountId),
      'accountType': serializer.toJson<String>(accountType),
      'date': serializer.toJson<int>(date),
      'merchant': serializer.toJson<String>(merchant),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'mccCode': serializer.toJson<String?>(mccCode),
      'milesEarned': serializer.toJson<double>(milesEarned),
      'cashbackEarned': serializer.toJson<double>(cashbackEarned),
      'statementId': serializer.toJson<String?>(statementId),
      'aiConfidence': serializer.toJson<double?>(aiConfidence),
      'userCorrected': serializer.toJson<int>(userCorrected),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Transaction copyWith(
          {String? id,
          String? userId,
          String? accountId,
          String? accountType,
          int? date,
          String? merchant,
          String? description,
          double? amount,
          String? currency,
          String? category,
          Value<String?> mccCode = const Value.absent(),
          double? milesEarned,
          double? cashbackEarned,
          Value<String?> statementId = const Value.absent(),
          Value<double?> aiConfidence = const Value.absent(),
          int? userCorrected,
          int? createdAt}) =>
      Transaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId ?? this.accountId,
        accountType: accountType ?? this.accountType,
        date: date ?? this.date,
        merchant: merchant ?? this.merchant,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        mccCode: mccCode.present ? mccCode.value : this.mccCode,
        milesEarned: milesEarned ?? this.milesEarned,
        cashbackEarned: cashbackEarned ?? this.cashbackEarned,
        statementId: statementId.present ? statementId.value : this.statementId,
        aiConfidence:
            aiConfidence.present ? aiConfidence.value : this.aiConfidence,
        userCorrected: userCorrected ?? this.userCorrected,
        createdAt: createdAt ?? this.createdAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      date: data.date.present ? data.date.value : this.date,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      mccCode: data.mccCode.present ? data.mccCode.value : this.mccCode,
      milesEarned:
          data.milesEarned.present ? data.milesEarned.value : this.milesEarned,
      cashbackEarned: data.cashbackEarned.present
          ? data.cashbackEarned.value
          : this.cashbackEarned,
      statementId:
          data.statementId.present ? data.statementId.value : this.statementId,
      aiConfidence: data.aiConfidence.present
          ? data.aiConfidence.value
          : this.aiConfidence,
      userCorrected: data.userCorrected.present
          ? data.userCorrected.value
          : this.userCorrected,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('accountType: $accountType, ')
          ..write('date: $date, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('mccCode: $mccCode, ')
          ..write('milesEarned: $milesEarned, ')
          ..write('cashbackEarned: $cashbackEarned, ')
          ..write('statementId: $statementId, ')
          ..write('aiConfidence: $aiConfidence, ')
          ..write('userCorrected: $userCorrected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      accountId,
      accountType,
      date,
      merchant,
      description,
      amount,
      currency,
      category,
      mccCode,
      milesEarned,
      cashbackEarned,
      statementId,
      aiConfidence,
      userCorrected,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.accountType == this.accountType &&
          other.date == this.date &&
          other.merchant == this.merchant &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.mccCode == this.mccCode &&
          other.milesEarned == this.milesEarned &&
          other.cashbackEarned == this.cashbackEarned &&
          other.statementId == this.statementId &&
          other.aiConfidence == this.aiConfidence &&
          other.userCorrected == this.userCorrected &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> accountId;
  final Value<String> accountType;
  final Value<int> date;
  final Value<String> merchant;
  final Value<String> description;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> category;
  final Value<String?> mccCode;
  final Value<double> milesEarned;
  final Value<double> cashbackEarned;
  final Value<String?> statementId;
  final Value<double?> aiConfidence;
  final Value<int> userCorrected;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountType = const Value.absent(),
    this.date = const Value.absent(),
    this.merchant = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.mccCode = const Value.absent(),
    this.milesEarned = const Value.absent(),
    this.cashbackEarned = const Value.absent(),
    this.statementId = const Value.absent(),
    this.aiConfidence = const Value.absent(),
    this.userCorrected = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String userId,
    required String accountId,
    required String accountType,
    required int date,
    required String merchant,
    required String description,
    required double amount,
    this.currency = const Value.absent(),
    required String category,
    this.mccCode = const Value.absent(),
    this.milesEarned = const Value.absent(),
    this.cashbackEarned = const Value.absent(),
    this.statementId = const Value.absent(),
    this.aiConfidence = const Value.absent(),
    this.userCorrected = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        accountId = Value(accountId),
        accountType = Value(accountType),
        date = Value(date),
        merchant = Value(merchant),
        description = Value(description),
        amount = Value(amount),
        category = Value(category),
        createdAt = Value(createdAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? accountId,
    Expression<String>? accountType,
    Expression<int>? date,
    Expression<String>? merchant,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<String>? mccCode,
    Expression<double>? milesEarned,
    Expression<double>? cashbackEarned,
    Expression<String>? statementId,
    Expression<double>? aiConfidence,
    Expression<int>? userCorrected,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (accountType != null) 'account_type': accountType,
      if (date != null) 'date': date,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (mccCode != null) 'mcc_code': mccCode,
      if (milesEarned != null) 'miles_earned': milesEarned,
      if (cashbackEarned != null) 'cashback_earned': cashbackEarned,
      if (statementId != null) 'statement_id': statementId,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      if (userCorrected != null) 'user_corrected': userCorrected,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? accountId,
      Value<String>? accountType,
      Value<int>? date,
      Value<String>? merchant,
      Value<String>? description,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? category,
      Value<String?>? mccCode,
      Value<double>? milesEarned,
      Value<double>? cashbackEarned,
      Value<String?>? statementId,
      Value<double?>? aiConfidence,
      Value<int>? userCorrected,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      accountType: accountType ?? this.accountType,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      mccCode: mccCode ?? this.mccCode,
      milesEarned: milesEarned ?? this.milesEarned,
      cashbackEarned: cashbackEarned ?? this.cashbackEarned,
      statementId: statementId ?? this.statementId,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      userCorrected: userCorrected ?? this.userCorrected,
      createdAt: createdAt ?? this.createdAt,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (mccCode.present) {
      map['mcc_code'] = Variable<String>(mccCode.value);
    }
    if (milesEarned.present) {
      map['miles_earned'] = Variable<double>(milesEarned.value);
    }
    if (cashbackEarned.present) {
      map['cashback_earned'] = Variable<double>(cashbackEarned.value);
    }
    if (statementId.present) {
      map['statement_id'] = Variable<String>(statementId.value);
    }
    if (aiConfidence.present) {
      map['ai_confidence'] = Variable<double>(aiConfidence.value);
    }
    if (userCorrected.present) {
      map['user_corrected'] = Variable<int>(userCorrected.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('accountType: $accountType, ')
          ..write('date: $date, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('mccCode: $mccCode, ')
          ..write('milesEarned: $milesEarned, ')
          ..write('cashbackEarned: $cashbackEarned, ')
          ..write('statementId: $statementId, ')
          ..write('aiConfidence: $aiConfidence, ')
          ..write('userCorrected: $userCorrected, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilesWalletTable extends MilesWallet
    with TableInfo<$MilesWalletTable, MilesWalletData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilesWalletTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _programNameMeta =
      const VerificationMeta('programName');
  @override
  late final GeneratedColumn<String> programName = GeneratedColumn<String>(
      'program_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _programTypeMeta =
      const VerificationMeta('programType');
  @override
  late final GeneratedColumn<String> programType = GeneratedColumn<String>(
      'program_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<int> expiryDate = GeneratedColumn<int>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<int> lastUpdated = GeneratedColumn<int>(
      'last_updated', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, programName, programType, balance, expiryDate, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'miles_wallet';
  @override
  VerificationContext validateIntegrity(Insertable<MilesWalletData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('program_name')) {
      context.handle(
          _programNameMeta,
          programName.isAcceptableOrUnknown(
              data['program_name']!, _programNameMeta));
    } else if (isInserting) {
      context.missing(_programNameMeta);
    }
    if (data.containsKey('program_type')) {
      context.handle(
          _programTypeMeta,
          programType.isAcceptableOrUnknown(
              data['program_type']!, _programTypeMeta));
    } else if (isInserting) {
      context.missing(_programTypeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MilesWalletData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MilesWalletData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      programName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program_name'])!,
      programType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program_type'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expiry_date']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_updated'])!,
    );
  }

  @override
  $MilesWalletTable createAlias(String alias) {
    return $MilesWalletTable(attachedDatabase, alias);
  }
}

class MilesWalletData extends DataClass implements Insertable<MilesWalletData> {
  final String id;
  final String userId;
  final String programName;
  final String programType;
  final double balance;
  final int? expiryDate;
  final int lastUpdated;
  const MilesWalletData(
      {required this.id,
      required this.userId,
      required this.programName,
      required this.programType,
      required this.balance,
      this.expiryDate,
      required this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['program_name'] = Variable<String>(programName);
    map['program_type'] = Variable<String>(programType);
    map['balance'] = Variable<double>(balance);
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<int>(expiryDate);
    }
    map['last_updated'] = Variable<int>(lastUpdated);
    return map;
  }

  MilesWalletCompanion toCompanion(bool nullToAbsent) {
    return MilesWalletCompanion(
      id: Value(id),
      userId: Value(userId),
      programName: Value(programName),
      programType: Value(programType),
      balance: Value(balance),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory MilesWalletData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MilesWalletData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      programName: serializer.fromJson<String>(json['programName']),
      programType: serializer.fromJson<String>(json['programType']),
      balance: serializer.fromJson<double>(json['balance']),
      expiryDate: serializer.fromJson<int?>(json['expiryDate']),
      lastUpdated: serializer.fromJson<int>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'programName': serializer.toJson<String>(programName),
      'programType': serializer.toJson<String>(programType),
      'balance': serializer.toJson<double>(balance),
      'expiryDate': serializer.toJson<int?>(expiryDate),
      'lastUpdated': serializer.toJson<int>(lastUpdated),
    };
  }

  MilesWalletData copyWith(
          {String? id,
          String? userId,
          String? programName,
          String? programType,
          double? balance,
          Value<int?> expiryDate = const Value.absent(),
          int? lastUpdated}) =>
      MilesWalletData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        programName: programName ?? this.programName,
        programType: programType ?? this.programType,
        balance: balance ?? this.balance,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
  MilesWalletData copyWithCompanion(MilesWalletCompanion data) {
    return MilesWalletData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      programName:
          data.programName.present ? data.programName.value : this.programName,
      programType:
          data.programType.present ? data.programType.value : this.programType,
      balance: data.balance.present ? data.balance.value : this.balance,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MilesWalletData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('programName: $programName, ')
          ..write('programType: $programType, ')
          ..write('balance: $balance, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, programName, programType, balance, expiryDate, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MilesWalletData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.programName == this.programName &&
          other.programType == this.programType &&
          other.balance == this.balance &&
          other.expiryDate == this.expiryDate &&
          other.lastUpdated == this.lastUpdated);
}

class MilesWalletCompanion extends UpdateCompanion<MilesWalletData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> programName;
  final Value<String> programType;
  final Value<double> balance;
  final Value<int?> expiryDate;
  final Value<int> lastUpdated;
  final Value<int> rowid;
  const MilesWalletCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.programName = const Value.absent(),
    this.programType = const Value.absent(),
    this.balance = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilesWalletCompanion.insert({
    required String id,
    required String userId,
    required String programName,
    required String programType,
    this.balance = const Value.absent(),
    this.expiryDate = const Value.absent(),
    required int lastUpdated,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        programName = Value(programName),
        programType = Value(programType),
        lastUpdated = Value(lastUpdated);
  static Insertable<MilesWalletData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? programName,
    Expression<String>? programType,
    Expression<double>? balance,
    Expression<int>? expiryDate,
    Expression<int>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (programName != null) 'program_name': programName,
      if (programType != null) 'program_type': programType,
      if (balance != null) 'balance': balance,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilesWalletCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? programName,
      Value<String>? programType,
      Value<double>? balance,
      Value<int?>? expiryDate,
      Value<int>? lastUpdated,
      Value<int>? rowid}) {
    return MilesWalletCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programName: programName ?? this.programName,
      programType: programType ?? this.programType,
      balance: balance ?? this.balance,
      expiryDate: expiryDate ?? this.expiryDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
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
    if (programName.present) {
      map['program_name'] = Variable<String>(programName.value);
    }
    if (programType.present) {
      map['program_type'] = Variable<String>(programType.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<int>(expiryDate.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<int>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilesWalletCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('programName: $programName, ')
          ..write('programType: $programType, ')
          ..write('balance: $balance, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TravelGoalsTable extends TravelGoals
    with TableInfo<$TravelGoalsTable, TravelGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TravelGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _destinationMeta =
      const VerificationMeta('destination');
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
      'destination', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _airlineMeta =
      const VerificationMeta('airline');
  @override
  late final GeneratedColumn<String> airline = GeneratedColumn<String>(
      'airline', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cabinClassMeta =
      const VerificationMeta('cabinClass');
  @override
  late final GeneratedColumn<String> cabinClass = GeneratedColumn<String>(
      'cabin_class', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _milesRequiredMeta =
      const VerificationMeta('milesRequired');
  @override
  late final GeneratedColumn<double> milesRequired = GeneratedColumn<double>(
      'miles_required', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _milesCurrentMeta =
      const VerificationMeta('milesCurrent');
  @override
  late final GeneratedColumn<double> milesCurrent = GeneratedColumn<double>(
      'miles_current', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<int> targetDate = GeneratedColumn<int>(
      'target_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        destination,
        airline,
        cabinClass,
        milesRequired,
        milesCurrent,
        targetDate,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'travel_goals';
  @override
  VerificationContext validateIntegrity(Insertable<TravelGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
          _destinationMeta,
          destination.isAcceptableOrUnknown(
              data['destination']!, _destinationMeta));
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('airline')) {
      context.handle(_airlineMeta,
          airline.isAcceptableOrUnknown(data['airline']!, _airlineMeta));
    } else if (isInserting) {
      context.missing(_airlineMeta);
    }
    if (data.containsKey('cabin_class')) {
      context.handle(
          _cabinClassMeta,
          cabinClass.isAcceptableOrUnknown(
              data['cabin_class']!, _cabinClassMeta));
    } else if (isInserting) {
      context.missing(_cabinClassMeta);
    }
    if (data.containsKey('miles_required')) {
      context.handle(
          _milesRequiredMeta,
          milesRequired.isAcceptableOrUnknown(
              data['miles_required']!, _milesRequiredMeta));
    } else if (isInserting) {
      context.missing(_milesRequiredMeta);
    }
    if (data.containsKey('miles_current')) {
      context.handle(
          _milesCurrentMeta,
          milesCurrent.isAcceptableOrUnknown(
              data['miles_current']!, _milesCurrentMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TravelGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TravelGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      destination: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}destination'])!,
      airline: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}airline'])!,
      cabinClass: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cabin_class'])!,
      milesRequired: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}miles_required'])!,
      milesCurrent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}miles_current'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TravelGoalsTable createAlias(String alias) {
    return $TravelGoalsTable(attachedDatabase, alias);
  }
}

class TravelGoal extends DataClass implements Insertable<TravelGoal> {
  final String id;
  final String userId;
  final String destination;
  final String airline;
  final String cabinClass;
  final double milesRequired;
  final double milesCurrent;
  final int? targetDate;
  final int createdAt;
  const TravelGoal(
      {required this.id,
      required this.userId,
      required this.destination,
      required this.airline,
      required this.cabinClass,
      required this.milesRequired,
      required this.milesCurrent,
      this.targetDate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['destination'] = Variable<String>(destination);
    map['airline'] = Variable<String>(airline);
    map['cabin_class'] = Variable<String>(cabinClass);
    map['miles_required'] = Variable<double>(milesRequired);
    map['miles_current'] = Variable<double>(milesCurrent);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<int>(targetDate);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TravelGoalsCompanion toCompanion(bool nullToAbsent) {
    return TravelGoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      destination: Value(destination),
      airline: Value(airline),
      cabinClass: Value(cabinClass),
      milesRequired: Value(milesRequired),
      milesCurrent: Value(milesCurrent),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdAt: Value(createdAt),
    );
  }

  factory TravelGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TravelGoal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      destination: serializer.fromJson<String>(json['destination']),
      airline: serializer.fromJson<String>(json['airline']),
      cabinClass: serializer.fromJson<String>(json['cabinClass']),
      milesRequired: serializer.fromJson<double>(json['milesRequired']),
      milesCurrent: serializer.fromJson<double>(json['milesCurrent']),
      targetDate: serializer.fromJson<int?>(json['targetDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'destination': serializer.toJson<String>(destination),
      'airline': serializer.toJson<String>(airline),
      'cabinClass': serializer.toJson<String>(cabinClass),
      'milesRequired': serializer.toJson<double>(milesRequired),
      'milesCurrent': serializer.toJson<double>(milesCurrent),
      'targetDate': serializer.toJson<int?>(targetDate),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  TravelGoal copyWith(
          {String? id,
          String? userId,
          String? destination,
          String? airline,
          String? cabinClass,
          double? milesRequired,
          double? milesCurrent,
          Value<int?> targetDate = const Value.absent(),
          int? createdAt}) =>
      TravelGoal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        destination: destination ?? this.destination,
        airline: airline ?? this.airline,
        cabinClass: cabinClass ?? this.cabinClass,
        milesRequired: milesRequired ?? this.milesRequired,
        milesCurrent: milesCurrent ?? this.milesCurrent,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        createdAt: createdAt ?? this.createdAt,
      );
  TravelGoal copyWithCompanion(TravelGoalsCompanion data) {
    return TravelGoal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      destination:
          data.destination.present ? data.destination.value : this.destination,
      airline: data.airline.present ? data.airline.value : this.airline,
      cabinClass:
          data.cabinClass.present ? data.cabinClass.value : this.cabinClass,
      milesRequired: data.milesRequired.present
          ? data.milesRequired.value
          : this.milesRequired,
      milesCurrent: data.milesCurrent.present
          ? data.milesCurrent.value
          : this.milesCurrent,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TravelGoal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('destination: $destination, ')
          ..write('airline: $airline, ')
          ..write('cabinClass: $cabinClass, ')
          ..write('milesRequired: $milesRequired, ')
          ..write('milesCurrent: $milesCurrent, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, destination, airline, cabinClass,
      milesRequired, milesCurrent, targetDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TravelGoal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.destination == this.destination &&
          other.airline == this.airline &&
          other.cabinClass == this.cabinClass &&
          other.milesRequired == this.milesRequired &&
          other.milesCurrent == this.milesCurrent &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt);
}

class TravelGoalsCompanion extends UpdateCompanion<TravelGoal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> destination;
  final Value<String> airline;
  final Value<String> cabinClass;
  final Value<double> milesRequired;
  final Value<double> milesCurrent;
  final Value<int?> targetDate;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TravelGoalsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.destination = const Value.absent(),
    this.airline = const Value.absent(),
    this.cabinClass = const Value.absent(),
    this.milesRequired = const Value.absent(),
    this.milesCurrent = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TravelGoalsCompanion.insert({
    required String id,
    required String userId,
    required String destination,
    required String airline,
    required String cabinClass,
    required double milesRequired,
    this.milesCurrent = const Value.absent(),
    this.targetDate = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        destination = Value(destination),
        airline = Value(airline),
        cabinClass = Value(cabinClass),
        milesRequired = Value(milesRequired),
        createdAt = Value(createdAt);
  static Insertable<TravelGoal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? destination,
    Expression<String>? airline,
    Expression<String>? cabinClass,
    Expression<double>? milesRequired,
    Expression<double>? milesCurrent,
    Expression<int>? targetDate,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (destination != null) 'destination': destination,
      if (airline != null) 'airline': airline,
      if (cabinClass != null) 'cabin_class': cabinClass,
      if (milesRequired != null) 'miles_required': milesRequired,
      if (milesCurrent != null) 'miles_current': milesCurrent,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TravelGoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? destination,
      Value<String>? airline,
      Value<String>? cabinClass,
      Value<double>? milesRequired,
      Value<double>? milesCurrent,
      Value<int?>? targetDate,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TravelGoalsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      airline: airline ?? this.airline,
      cabinClass: cabinClass ?? this.cabinClass,
      milesRequired: milesRequired ?? this.milesRequired,
      milesCurrent: milesCurrent ?? this.milesCurrent,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
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
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (airline.present) {
      map['airline'] = Variable<String>(airline.value);
    }
    if (cabinClass.present) {
      map['cabin_class'] = Variable<String>(cabinClass.value);
    }
    if (milesRequired.present) {
      map['miles_required'] = Variable<double>(milesRequired.value);
    }
    if (milesCurrent.present) {
      map['miles_current'] = Variable<double>(milesCurrent.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<int>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TravelGoalsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('destination: $destination, ')
          ..write('airline: $airline, ')
          ..write('cabinClass: $cabinClass, ')
          ..write('milesRequired: $milesRequired, ')
          ..write('milesCurrent: $milesCurrent, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $BankAccountsTable bankAccounts = $BankAccountsTable(this);
  late final $CreditCardsTable creditCards = $CreditCardsTable(this);
  late final $StatementsTable statements = $StatementsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $MilesWalletTable milesWallet = $MilesWalletTable(this);
  late final $TravelGoalsTable travelGoals = $TravelGoalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        bankAccounts,
        creditCards,
        statements,
        transactions,
        milesWallet,
        travelGoals
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String firstName,
  required String lastName,
  required String email,
  required String googleId,
  Value<String?> displayName,
  Value<String?> photoUrl,
  Value<String?> rewardFocus,
  Value<String> currencyPref,
  required int createdAt,
  Value<int?> lastLoginAt,
  Value<int?> sessionExpires,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> firstName,
  Value<String> lastName,
  Value<String> email,
  Value<String> googleId,
  Value<String?> displayName,
  Value<String?> photoUrl,
  Value<String?> rewardFocus,
  Value<String> currencyPref,
  Value<int> createdAt,
  Value<int?> lastLoginAt,
  Value<int?> sessionExpires,
  Value<int> rowid,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BankAccountsTable, List<BankAccount>>
      _bankAccountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.bankAccounts,
          aliasName: $_aliasNameGenerator(db.users.id, db.bankAccounts.userId));

  $$BankAccountsTableProcessedTableManager get bankAccountsRefs {
    final manager = $$BankAccountsTableTableManager($_db, $_db.bankAccounts)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bankAccountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CreditCardsTable, List<CreditCard>>
      _creditCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.creditCards,
          aliasName: $_aliasNameGenerator(db.users.id, db.creditCards.userId));

  $$CreditCardsTableProcessedTableManager get creditCardsRefs {
    final manager = $$CreditCardsTableTableManager($_db, $_db.creditCards)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StatementsTable, List<Statement>>
      _statementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.statements,
          aliasName: $_aliasNameGenerator(db.users.id, db.statements.userId));

  $$StatementsTableProcessedTableManager get statementsRefs {
    final manager = $$StatementsTableTableManager($_db, $_db.statements)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_statementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName: $_aliasNameGenerator(db.users.id, db.transactions.userId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MilesWalletTable, List<MilesWalletData>>
      _milesWalletRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.milesWallet,
          aliasName: $_aliasNameGenerator(db.users.id, db.milesWallet.userId));

  $$MilesWalletTableProcessedTableManager get milesWalletRefs {
    final manager = $$MilesWalletTableTableManager($_db, $_db.milesWallet)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_milesWalletRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TravelGoalsTable, List<TravelGoal>>
      _travelGoalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.travelGoals,
          aliasName: $_aliasNameGenerator(db.users.id, db.travelGoals.userId));

  $$TravelGoalsTableProcessedTableManager get travelGoalsRefs {
    final manager = $$TravelGoalsTableTableManager($_db, $_db.travelGoals)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_travelGoalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get googleId => $composableBuilder(
      column: $table.googleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rewardFocus => $composableBuilder(
      column: $table.rewardFocus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyPref => $composableBuilder(
      column: $table.currencyPref, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionExpires => $composableBuilder(
      column: $table.sessionExpires,
      builder: (column) => ColumnFilters(column));

  Expression<bool> bankAccountsRefs(
      Expression<bool> Function($$BankAccountsTableFilterComposer f) f) {
    final $$BankAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bankAccounts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BankAccountsTableFilterComposer(
              $db: $db,
              $table: $db.bankAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> creditCardsRefs(
      Expression<bool> Function($$CreditCardsTableFilterComposer f) f) {
    final $$CreditCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.creditCards,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CreditCardsTableFilterComposer(
              $db: $db,
              $table: $db.creditCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> statementsRefs(
      Expression<bool> Function($$StatementsTableFilterComposer f) f) {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.statements,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StatementsTableFilterComposer(
              $db: $db,
              $table: $db.statements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> milesWalletRefs(
      Expression<bool> Function($$MilesWalletTableFilterComposer f) f) {
    final $$MilesWalletTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.milesWallet,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MilesWalletTableFilterComposer(
              $db: $db,
              $table: $db.milesWallet,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> travelGoalsRefs(
      Expression<bool> Function($$TravelGoalsTableFilterComposer f) f) {
    final $$TravelGoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.travelGoals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TravelGoalsTableFilterComposer(
              $db: $db,
              $table: $db.travelGoals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get googleId => $composableBuilder(
      column: $table.googleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rewardFocus => $composableBuilder(
      column: $table.rewardFocus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyPref => $composableBuilder(
      column: $table.currencyPref,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionExpires => $composableBuilder(
      column: $table.sessionExpires,
      builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get googleId =>
      $composableBuilder(column: $table.googleId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get rewardFocus => $composableBuilder(
      column: $table.rewardFocus, builder: (column) => column);

  GeneratedColumn<String> get currencyPref => $composableBuilder(
      column: $table.currencyPref, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => column);

  GeneratedColumn<int> get sessionExpires => $composableBuilder(
      column: $table.sessionExpires, builder: (column) => column);

  Expression<T> bankAccountsRefs<T extends Object>(
      Expression<T> Function($$BankAccountsTableAnnotationComposer a) f) {
    final $$BankAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bankAccounts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BankAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.bankAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> creditCardsRefs<T extends Object>(
      Expression<T> Function($$CreditCardsTableAnnotationComposer a) f) {
    final $$CreditCardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.creditCards,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CreditCardsTableAnnotationComposer(
              $db: $db,
              $table: $db.creditCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> statementsRefs<T extends Object>(
      Expression<T> Function($$StatementsTableAnnotationComposer a) f) {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.statements,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StatementsTableAnnotationComposer(
              $db: $db,
              $table: $db.statements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> milesWalletRefs<T extends Object>(
      Expression<T> Function($$MilesWalletTableAnnotationComposer a) f) {
    final $$MilesWalletTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.milesWallet,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MilesWalletTableAnnotationComposer(
              $db: $db,
              $table: $db.milesWallet,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> travelGoalsRefs<T extends Object>(
      Expression<T> Function($$TravelGoalsTableAnnotationComposer a) f) {
    final $$TravelGoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.travelGoals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TravelGoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.travelGoals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool bankAccountsRefs,
        bool creditCardsRefs,
        bool statementsRefs,
        bool transactionsRefs,
        bool milesWalletRefs,
        bool travelGoalsRefs})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> googleId = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> rewardFocus = const Value.absent(),
            Value<String> currencyPref = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastLoginAt = const Value.absent(),
            Value<int?> sessionExpires = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            googleId: googleId,
            displayName: displayName,
            photoUrl: photoUrl,
            rewardFocus: rewardFocus,
            currencyPref: currencyPref,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            sessionExpires: sessionExpires,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String firstName,
            required String lastName,
            required String email,
            required String googleId,
            Value<String?> displayName = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> rewardFocus = const Value.absent(),
            Value<String> currencyPref = const Value.absent(),
            required int createdAt,
            Value<int?> lastLoginAt = const Value.absent(),
            Value<int?> sessionExpires = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            googleId: googleId,
            displayName: displayName,
            photoUrl: photoUrl,
            rewardFocus: rewardFocus,
            currencyPref: currencyPref,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            sessionExpires: sessionExpires,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {bankAccountsRefs = false,
              creditCardsRefs = false,
              statementsRefs = false,
              transactionsRefs = false,
              milesWalletRefs = false,
              travelGoalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bankAccountsRefs) db.bankAccounts,
                if (creditCardsRefs) db.creditCards,
                if (statementsRefs) db.statements,
                if (transactionsRefs) db.transactions,
                if (milesWalletRefs) db.milesWallet,
                if (travelGoalsRefs) db.travelGoals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bankAccountsRefs)
                    await $_getPrefetchedData<User, $UsersTable, BankAccount>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._bankAccountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .bankAccountsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (creditCardsRefs)
                    await $_getPrefetchedData<User, $UsersTable, CreditCard>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._creditCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .creditCardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (statementsRefs)
                    await $_getPrefetchedData<User, $UsersTable, Statement>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._statementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .statementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<User, $UsersTable, Transaction>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (milesWalletRefs)
                    await $_getPrefetchedData<User, $UsersTable,
                            MilesWalletData>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._milesWalletRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .milesWalletRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (travelGoalsRefs)
                    await $_getPrefetchedData<User, $UsersTable, TravelGoal>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._travelGoalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .travelGoalsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool bankAccountsRefs,
        bool creditCardsRefs,
        bool statementsRefs,
        bool transactionsRefs,
        bool milesWalletRefs,
        bool travelGoalsRefs})>;
typedef $$BankAccountsTableCreateCompanionBuilder = BankAccountsCompanion
    Function({
  required String id,
  required String userId,
  required String bankName,
  required String accountType,
  Value<String?> accountNumber,
  Value<double> openingBalance,
  Value<double> currentBalance,
  Value<String> currency,
  Value<String?> sourceStatementId,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BankAccountsTableUpdateCompanionBuilder = BankAccountsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> bankName,
  Value<String> accountType,
  Value<String?> accountNumber,
  Value<double> openingBalance,
  Value<double> currentBalance,
  Value<String> currency,
  Value<String?> sourceStatementId,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$BankAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $BankAccountsTable, BankAccount> {
  $$BankAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.bankAccounts.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BankAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountNumber => $composableBuilder(
      column: $table.accountNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BankAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountNumber => $composableBuilder(
      column: $table.accountNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BankAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<String> get accountNumber => $composableBuilder(
      column: $table.accountNumber, builder: (column) => column);

  GeneratedColumn<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance, builder: (column) => column);

  GeneratedColumn<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BankAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BankAccountsTable,
    BankAccount,
    $$BankAccountsTableFilterComposer,
    $$BankAccountsTableOrderingComposer,
    $$BankAccountsTableAnnotationComposer,
    $$BankAccountsTableCreateCompanionBuilder,
    $$BankAccountsTableUpdateCompanionBuilder,
    (BankAccount, $$BankAccountsTableReferences),
    BankAccount,
    PrefetchHooks Function({bool userId})> {
  $$BankAccountsTableTableManager(_$AppDatabase db, $BankAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> bankName = const Value.absent(),
            Value<String> accountType = const Value.absent(),
            Value<String?> accountNumber = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<double> currentBalance = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> sourceStatementId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BankAccountsCompanion(
            id: id,
            userId: userId,
            bankName: bankName,
            accountType: accountType,
            accountNumber: accountNumber,
            openingBalance: openingBalance,
            currentBalance: currentBalance,
            currency: currency,
            sourceStatementId: sourceStatementId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String bankName,
            required String accountType,
            Value<String?> accountNumber = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<double> currentBalance = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> sourceStatementId = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BankAccountsCompanion.insert(
            id: id,
            userId: userId,
            bankName: bankName,
            accountType: accountType,
            accountNumber: accountNumber,
            openingBalance: openingBalance,
            currentBalance: currentBalance,
            currency: currency,
            sourceStatementId: sourceStatementId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BankAccountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$BankAccountsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$BankAccountsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BankAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BankAccountsTable,
    BankAccount,
    $$BankAccountsTableFilterComposer,
    $$BankAccountsTableOrderingComposer,
    $$BankAccountsTableAnnotationComposer,
    $$BankAccountsTableCreateCompanionBuilder,
    $$BankAccountsTableUpdateCompanionBuilder,
    (BankAccount, $$BankAccountsTableReferences),
    BankAccount,
    PrefetchHooks Function({bool userId})>;
typedef $$CreditCardsTableCreateCompanionBuilder = CreditCardsCompanion
    Function({
  required String id,
  required String userId,
  required String bankName,
  required String cardName,
  required String cardType,
  required String rewardType,
  Value<String?> lastFour,
  Value<String?> sourceStatementId,
  required int createdAt,
  Value<int> rowid,
});
typedef $$CreditCardsTableUpdateCompanionBuilder = CreditCardsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> bankName,
  Value<String> cardName,
  Value<String> cardType,
  Value<String> rewardType,
  Value<String?> lastFour,
  Value<String?> sourceStatementId,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$CreditCardsTableReferences
    extends BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard> {
  $$CreditCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.creditCards.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CreditCardsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardName => $composableBuilder(
      column: $table.cardName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rewardType => $composableBuilder(
      column: $table.rewardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastFour => $composableBuilder(
      column: $table.lastFour, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CreditCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardName => $composableBuilder(
      column: $table.cardName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rewardType => $composableBuilder(
      column: $table.rewardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastFour => $composableBuilder(
      column: $table.lastFour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CreditCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get cardName =>
      $composableBuilder(column: $table.cardName, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get rewardType => $composableBuilder(
      column: $table.rewardType, builder: (column) => column);

  GeneratedColumn<String> get lastFour =>
      $composableBuilder(column: $table.lastFour, builder: (column) => column);

  GeneratedColumn<String> get sourceStatementId => $composableBuilder(
      column: $table.sourceStatementId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CreditCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CreditCardsTable,
    CreditCard,
    $$CreditCardsTableFilterComposer,
    $$CreditCardsTableOrderingComposer,
    $$CreditCardsTableAnnotationComposer,
    $$CreditCardsTableCreateCompanionBuilder,
    $$CreditCardsTableUpdateCompanionBuilder,
    (CreditCard, $$CreditCardsTableReferences),
    CreditCard,
    PrefetchHooks Function({bool userId})> {
  $$CreditCardsTableTableManager(_$AppDatabase db, $CreditCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> bankName = const Value.absent(),
            Value<String> cardName = const Value.absent(),
            Value<String> cardType = const Value.absent(),
            Value<String> rewardType = const Value.absent(),
            Value<String?> lastFour = const Value.absent(),
            Value<String?> sourceStatementId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CreditCardsCompanion(
            id: id,
            userId: userId,
            bankName: bankName,
            cardName: cardName,
            cardType: cardType,
            rewardType: rewardType,
            lastFour: lastFour,
            sourceStatementId: sourceStatementId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String bankName,
            required String cardName,
            required String cardType,
            required String rewardType,
            Value<String?> lastFour = const Value.absent(),
            Value<String?> sourceStatementId = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CreditCardsCompanion.insert(
            id: id,
            userId: userId,
            bankName: bankName,
            cardName: cardName,
            cardType: cardType,
            rewardType: rewardType,
            lastFour: lastFour,
            sourceStatementId: sourceStatementId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CreditCardsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$CreditCardsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$CreditCardsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CreditCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CreditCardsTable,
    CreditCard,
    $$CreditCardsTableFilterComposer,
    $$CreditCardsTableOrderingComposer,
    $$CreditCardsTableAnnotationComposer,
    $$CreditCardsTableCreateCompanionBuilder,
    $$CreditCardsTableUpdateCompanionBuilder,
    (CreditCard, $$CreditCardsTableReferences),
    CreditCard,
    PrefetchHooks Function({bool userId})>;
typedef $$StatementsTableCreateCompanionBuilder = StatementsCompanion Function({
  required String id,
  required String userId,
  required String fileName,
  required String filePath,
  required String fileType,
  required int fileSizeBytes,
  Value<String?> fileHash,
  Value<String?> bankOrCard,
  Value<String?> accountType,
  Value<int?> periodStart,
  Value<int?> periodEnd,
  Value<String> status,
  Value<String?> aiModelUsed,
  Value<int> transactionCount,
  required int uploadedAt,
  Value<int?> processedAt,
  Value<int> rowid,
});
typedef $$StatementsTableUpdateCompanionBuilder = StatementsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> fileName,
  Value<String> filePath,
  Value<String> fileType,
  Value<int> fileSizeBytes,
  Value<String?> fileHash,
  Value<String?> bankOrCard,
  Value<String?> accountType,
  Value<int?> periodStart,
  Value<int?> periodEnd,
  Value<String> status,
  Value<String?> aiModelUsed,
  Value<int> transactionCount,
  Value<int> uploadedAt,
  Value<int?> processedAt,
  Value<int> rowid,
});

final class $$StatementsTableReferences
    extends BaseReferences<_$AppDatabase, $StatementsTable, Statement> {
  $$StatementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.statements.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.statements.id, db.transactions.statementId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.statementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StatementsTableFilterComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileHash => $composableBuilder(
      column: $table.fileHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankOrCard => $composableBuilder(
      column: $table.bankOrCard, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiModelUsed => $composableBuilder(
      column: $table.aiModelUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.statementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StatementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileHash => $composableBuilder(
      column: $table.fileHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankOrCard => $composableBuilder(
      column: $table.bankOrCard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiModelUsed => $composableBuilder(
      column: $table.aiModelUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StatementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatementsTable> {
  $$StatementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get bankOrCard => $composableBuilder(
      column: $table.bankOrCard, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<int> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<int> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get aiModelUsed => $composableBuilder(
      column: $table.aiModelUsed, builder: (column) => column);

  GeneratedColumn<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount, builder: (column) => column);

  GeneratedColumn<int> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);

  GeneratedColumn<int> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.statementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StatementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StatementsTable,
    Statement,
    $$StatementsTableFilterComposer,
    $$StatementsTableOrderingComposer,
    $$StatementsTableAnnotationComposer,
    $$StatementsTableCreateCompanionBuilder,
    $$StatementsTableUpdateCompanionBuilder,
    (Statement, $$StatementsTableReferences),
    Statement,
    PrefetchHooks Function({bool userId, bool transactionsRefs})> {
  $$StatementsTableTableManager(_$AppDatabase db, $StatementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> fileType = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<String?> fileHash = const Value.absent(),
            Value<String?> bankOrCard = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<int?> periodStart = const Value.absent(),
            Value<int?> periodEnd = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> aiModelUsed = const Value.absent(),
            Value<int> transactionCount = const Value.absent(),
            Value<int> uploadedAt = const Value.absent(),
            Value<int?> processedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StatementsCompanion(
            id: id,
            userId: userId,
            fileName: fileName,
            filePath: filePath,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            fileHash: fileHash,
            bankOrCard: bankOrCard,
            accountType: accountType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            status: status,
            aiModelUsed: aiModelUsed,
            transactionCount: transactionCount,
            uploadedAt: uploadedAt,
            processedAt: processedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String fileName,
            required String filePath,
            required String fileType,
            required int fileSizeBytes,
            Value<String?> fileHash = const Value.absent(),
            Value<String?> bankOrCard = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<int?> periodStart = const Value.absent(),
            Value<int?> periodEnd = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> aiModelUsed = const Value.absent(),
            Value<int> transactionCount = const Value.absent(),
            required int uploadedAt,
            Value<int?> processedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StatementsCompanion.insert(
            id: id,
            userId: userId,
            fileName: fileName,
            filePath: filePath,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            fileHash: fileHash,
            bankOrCard: bankOrCard,
            accountType: accountType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            status: status,
            aiModelUsed: aiModelUsed,
            transactionCount: transactionCount,
            uploadedAt: uploadedAt,
            processedAt: processedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StatementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$StatementsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$StatementsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Statement, $StatementsTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$StatementsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StatementsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.statementId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StatementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StatementsTable,
    Statement,
    $$StatementsTableFilterComposer,
    $$StatementsTableOrderingComposer,
    $$StatementsTableAnnotationComposer,
    $$StatementsTableCreateCompanionBuilder,
    $$StatementsTableUpdateCompanionBuilder,
    (Statement, $$StatementsTableReferences),
    Statement,
    PrefetchHooks Function({bool userId, bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String userId,
  required String accountId,
  required String accountType,
  required int date,
  required String merchant,
  required String description,
  required double amount,
  Value<String> currency,
  required String category,
  Value<String?> mccCode,
  Value<double> milesEarned,
  Value<double> cashbackEarned,
  Value<String?> statementId,
  Value<double?> aiConfidence,
  Value<int> userCorrected,
  required int createdAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> accountId,
  Value<String> accountType,
  Value<int> date,
  Value<String> merchant,
  Value<String> description,
  Value<double> amount,
  Value<String> currency,
  Value<String> category,
  Value<String?> mccCode,
  Value<double> milesEarned,
  Value<double> cashbackEarned,
  Value<String?> statementId,
  Value<double?> aiConfidence,
  Value<int> userCorrected,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.transactions.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StatementsTable _statementIdTable(_$AppDatabase db) =>
      db.statements.createAlias(
          $_aliasNameGenerator(db.transactions.statementId, db.statements.id));

  $$StatementsTableProcessedTableManager? get statementId {
    final $_column = $_itemColumn<String>('statement_id');
    if ($_column == null) return null;
    final manager = $$StatementsTableTableManager($_db, $_db.statements)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_statementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mccCode => $composableBuilder(
      column: $table.mccCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get milesEarned => $composableBuilder(
      column: $table.milesEarned, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cashbackEarned => $composableBuilder(
      column: $table.cashbackEarned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userCorrected => $composableBuilder(
      column: $table.userCorrected, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StatementsTableFilterComposer get statementId {
    final $$StatementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.statementId,
        referencedTable: $db.statements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StatementsTableFilterComposer(
              $db: $db,
              $table: $db.statements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mccCode => $composableBuilder(
      column: $table.mccCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get milesEarned => $composableBuilder(
      column: $table.milesEarned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cashbackEarned => $composableBuilder(
      column: $table.cashbackEarned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userCorrected => $composableBuilder(
      column: $table.userCorrected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StatementsTableOrderingComposer get statementId {
    final $$StatementsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.statementId,
        referencedTable: $db.statements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StatementsTableOrderingComposer(
              $db: $db,
              $table: $db.statements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get mccCode =>
      $composableBuilder(column: $table.mccCode, builder: (column) => column);

  GeneratedColumn<double> get milesEarned => $composableBuilder(
      column: $table.milesEarned, builder: (column) => column);

  GeneratedColumn<double> get cashbackEarned => $composableBuilder(
      column: $table.cashbackEarned, builder: (column) => column);

  GeneratedColumn<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence, builder: (column) => column);

  GeneratedColumn<int> get userCorrected => $composableBuilder(
      column: $table.userCorrected, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StatementsTableAnnotationComposer get statementId {
    final $$StatementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.statementId,
        referencedTable: $db.statements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StatementsTableAnnotationComposer(
              $db: $db,
              $table: $db.statements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool userId, bool statementId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> accountType = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<String> merchant = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> mccCode = const Value.absent(),
            Value<double> milesEarned = const Value.absent(),
            Value<double> cashbackEarned = const Value.absent(),
            Value<String?> statementId = const Value.absent(),
            Value<double?> aiConfidence = const Value.absent(),
            Value<int> userCorrected = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            userId: userId,
            accountId: accountId,
            accountType: accountType,
            date: date,
            merchant: merchant,
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            mccCode: mccCode,
            milesEarned: milesEarned,
            cashbackEarned: cashbackEarned,
            statementId: statementId,
            aiConfidence: aiConfidence,
            userCorrected: userCorrected,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String accountId,
            required String accountType,
            required int date,
            required String merchant,
            required String description,
            required double amount,
            Value<String> currency = const Value.absent(),
            required String category,
            Value<String?> mccCode = const Value.absent(),
            Value<double> milesEarned = const Value.absent(),
            Value<double> cashbackEarned = const Value.absent(),
            Value<String?> statementId = const Value.absent(),
            Value<double?> aiConfidence = const Value.absent(),
            Value<int> userCorrected = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            userId: userId,
            accountId: accountId,
            accountType: accountType,
            date: date,
            merchant: merchant,
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            mccCode: mccCode,
            milesEarned: milesEarned,
            cashbackEarned: cashbackEarned,
            statementId: statementId,
            aiConfidence: aiConfidence,
            userCorrected: userCorrected,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, statementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$TransactionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (statementId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.statementId,
                    referencedTable:
                        $$TransactionsTableReferences._statementIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._statementIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool userId, bool statementId})>;
typedef $$MilesWalletTableCreateCompanionBuilder = MilesWalletCompanion
    Function({
  required String id,
  required String userId,
  required String programName,
  required String programType,
  Value<double> balance,
  Value<int?> expiryDate,
  required int lastUpdated,
  Value<int> rowid,
});
typedef $$MilesWalletTableUpdateCompanionBuilder = MilesWalletCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> programName,
  Value<String> programType,
  Value<double> balance,
  Value<int?> expiryDate,
  Value<int> lastUpdated,
  Value<int> rowid,
});

final class $$MilesWalletTableReferences
    extends BaseReferences<_$AppDatabase, $MilesWalletTable, MilesWalletData> {
  $$MilesWalletTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.milesWallet.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MilesWalletTableFilterComposer
    extends Composer<_$AppDatabase, $MilesWalletTable> {
  $$MilesWalletTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programName => $composableBuilder(
      column: $table.programName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programType => $composableBuilder(
      column: $table.programType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MilesWalletTableOrderingComposer
    extends Composer<_$AppDatabase, $MilesWalletTable> {
  $$MilesWalletTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programName => $composableBuilder(
      column: $table.programName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programType => $composableBuilder(
      column: $table.programType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MilesWalletTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilesWalletTable> {
  $$MilesWalletTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programName => $composableBuilder(
      column: $table.programName, builder: (column) => column);

  GeneratedColumn<String> get programType => $composableBuilder(
      column: $table.programType, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);

  GeneratedColumn<int> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MilesWalletTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MilesWalletTable,
    MilesWalletData,
    $$MilesWalletTableFilterComposer,
    $$MilesWalletTableOrderingComposer,
    $$MilesWalletTableAnnotationComposer,
    $$MilesWalletTableCreateCompanionBuilder,
    $$MilesWalletTableUpdateCompanionBuilder,
    (MilesWalletData, $$MilesWalletTableReferences),
    MilesWalletData,
    PrefetchHooks Function({bool userId})> {
  $$MilesWalletTableTableManager(_$AppDatabase db, $MilesWalletTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilesWalletTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilesWalletTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilesWalletTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> programName = const Value.absent(),
            Value<String> programType = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<int?> expiryDate = const Value.absent(),
            Value<int> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MilesWalletCompanion(
            id: id,
            userId: userId,
            programName: programName,
            programType: programType,
            balance: balance,
            expiryDate: expiryDate,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String programName,
            required String programType,
            Value<double> balance = const Value.absent(),
            Value<int?> expiryDate = const Value.absent(),
            required int lastUpdated,
            Value<int> rowid = const Value.absent(),
          }) =>
              MilesWalletCompanion.insert(
            id: id,
            userId: userId,
            programName: programName,
            programType: programType,
            balance: balance,
            expiryDate: expiryDate,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MilesWalletTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$MilesWalletTableReferences._userIdTable(db),
                    referencedColumn:
                        $$MilesWalletTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MilesWalletTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MilesWalletTable,
    MilesWalletData,
    $$MilesWalletTableFilterComposer,
    $$MilesWalletTableOrderingComposer,
    $$MilesWalletTableAnnotationComposer,
    $$MilesWalletTableCreateCompanionBuilder,
    $$MilesWalletTableUpdateCompanionBuilder,
    (MilesWalletData, $$MilesWalletTableReferences),
    MilesWalletData,
    PrefetchHooks Function({bool userId})>;
typedef $$TravelGoalsTableCreateCompanionBuilder = TravelGoalsCompanion
    Function({
  required String id,
  required String userId,
  required String destination,
  required String airline,
  required String cabinClass,
  required double milesRequired,
  Value<double> milesCurrent,
  Value<int?> targetDate,
  required int createdAt,
  Value<int> rowid,
});
typedef $$TravelGoalsTableUpdateCompanionBuilder = TravelGoalsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> destination,
  Value<String> airline,
  Value<String> cabinClass,
  Value<double> milesRequired,
  Value<double> milesCurrent,
  Value<int?> targetDate,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$TravelGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $TravelGoalsTable, TravelGoal> {
  $$TravelGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.travelGoals.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TravelGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $TravelGoalsTable> {
  $$TravelGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get airline => $composableBuilder(
      column: $table.airline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cabinClass => $composableBuilder(
      column: $table.cabinClass, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get milesRequired => $composableBuilder(
      column: $table.milesRequired, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get milesCurrent => $composableBuilder(
      column: $table.milesCurrent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TravelGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $TravelGoalsTable> {
  $$TravelGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get airline => $composableBuilder(
      column: $table.airline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cabinClass => $composableBuilder(
      column: $table.cabinClass, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get milesRequired => $composableBuilder(
      column: $table.milesRequired,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get milesCurrent => $composableBuilder(
      column: $table.milesCurrent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TravelGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TravelGoalsTable> {
  $$TravelGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
      column: $table.destination, builder: (column) => column);

  GeneratedColumn<String> get airline =>
      $composableBuilder(column: $table.airline, builder: (column) => column);

  GeneratedColumn<String> get cabinClass => $composableBuilder(
      column: $table.cabinClass, builder: (column) => column);

  GeneratedColumn<double> get milesRequired => $composableBuilder(
      column: $table.milesRequired, builder: (column) => column);

  GeneratedColumn<double> get milesCurrent => $composableBuilder(
      column: $table.milesCurrent, builder: (column) => column);

  GeneratedColumn<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TravelGoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TravelGoalsTable,
    TravelGoal,
    $$TravelGoalsTableFilterComposer,
    $$TravelGoalsTableOrderingComposer,
    $$TravelGoalsTableAnnotationComposer,
    $$TravelGoalsTableCreateCompanionBuilder,
    $$TravelGoalsTableUpdateCompanionBuilder,
    (TravelGoal, $$TravelGoalsTableReferences),
    TravelGoal,
    PrefetchHooks Function({bool userId})> {
  $$TravelGoalsTableTableManager(_$AppDatabase db, $TravelGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TravelGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TravelGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TravelGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> destination = const Value.absent(),
            Value<String> airline = const Value.absent(),
            Value<String> cabinClass = const Value.absent(),
            Value<double> milesRequired = const Value.absent(),
            Value<double> milesCurrent = const Value.absent(),
            Value<int?> targetDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TravelGoalsCompanion(
            id: id,
            userId: userId,
            destination: destination,
            airline: airline,
            cabinClass: cabinClass,
            milesRequired: milesRequired,
            milesCurrent: milesCurrent,
            targetDate: targetDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String destination,
            required String airline,
            required String cabinClass,
            required double milesRequired,
            Value<double> milesCurrent = const Value.absent(),
            Value<int?> targetDate = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TravelGoalsCompanion.insert(
            id: id,
            userId: userId,
            destination: destination,
            airline: airline,
            cabinClass: cabinClass,
            milesRequired: milesRequired,
            milesCurrent: milesCurrent,
            targetDate: targetDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TravelGoalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$TravelGoalsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$TravelGoalsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TravelGoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TravelGoalsTable,
    TravelGoal,
    $$TravelGoalsTableFilterComposer,
    $$TravelGoalsTableOrderingComposer,
    $$TravelGoalsTableAnnotationComposer,
    $$TravelGoalsTableCreateCompanionBuilder,
    $$TravelGoalsTableUpdateCompanionBuilder,
    (TravelGoal, $$TravelGoalsTableReferences),
    TravelGoal,
    PrefetchHooks Function({bool userId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db, _db.bankAccounts);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db, _db.creditCards);
  $$StatementsTableTableManager get statements =>
      $$StatementsTableTableManager(_db, _db.statements);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$MilesWalletTableTableManager get milesWallet =>
      $$MilesWalletTableTableManager(_db, _db.milesWallet);
  $$TravelGoalsTableTableManager get travelGoals =>
      $$TravelGoalsTableTableManager(_db, _db.travelGoals);
}
