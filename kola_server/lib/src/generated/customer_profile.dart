/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class CustomerProfile
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CustomerProfile._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    this.birthday,
    this.anniversary,
    this.lastBirthdayGreetingYear,
    this.lastAnniversaryGreetingYear,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerProfile({
    int? id,
    required int workspaceId,
    required int conversationId,
    DateTime? birthday,
    DateTime? anniversary,
    int? lastBirthdayGreetingYear,
    int? lastAnniversaryGreetingYear,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CustomerProfileImpl;

  factory CustomerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return CustomerProfile(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      birthday: jsonSerialization['birthday'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['birthday']),
      anniversary: jsonSerialization['anniversary'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['anniversary'],
            ),
      lastBirthdayGreetingYear:
          jsonSerialization['lastBirthdayGreetingYear'] as int?,
      lastAnniversaryGreetingYear:
          jsonSerialization['lastAnniversaryGreetingYear'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  int conversationId;

  DateTime? birthday;

  DateTime? anniversary;

  int? lastBirthdayGreetingYear;

  int? lastAnniversaryGreetingYear;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [CustomerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CustomerProfile copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    DateTime? birthday,
    DateTime? anniversary,
    int? lastBirthdayGreetingYear,
    int? lastAnniversaryGreetingYear,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomerProfile',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (birthday != null) 'birthday': birthday?.toJson(),
      if (anniversary != null) 'anniversary': anniversary?.toJson(),
      if (lastBirthdayGreetingYear != null)
        'lastBirthdayGreetingYear': lastBirthdayGreetingYear,
      if (lastAnniversaryGreetingYear != null)
        'lastAnniversaryGreetingYear': lastAnniversaryGreetingYear,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CustomerProfile',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (birthday != null) 'birthday': birthday?.toJson(),
      if (anniversary != null) 'anniversary': anniversary?.toJson(),
      if (lastBirthdayGreetingYear != null)
        'lastBirthdayGreetingYear': lastBirthdayGreetingYear,
      if (lastAnniversaryGreetingYear != null)
        'lastAnniversaryGreetingYear': lastAnniversaryGreetingYear,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CustomerProfileImpl extends CustomerProfile {
  _CustomerProfileImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    DateTime? birthday,
    DateTime? anniversary,
    int? lastBirthdayGreetingYear,
    int? lastAnniversaryGreetingYear,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         birthday: birthday,
         anniversary: anniversary,
         lastBirthdayGreetingYear: lastBirthdayGreetingYear,
         lastAnniversaryGreetingYear: lastAnniversaryGreetingYear,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [CustomerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CustomerProfile copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    Object? birthday = _Undefined,
    Object? anniversary = _Undefined,
    Object? lastBirthdayGreetingYear = _Undefined,
    Object? lastAnniversaryGreetingYear = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerProfile(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      birthday: birthday is DateTime? ? birthday : this.birthday,
      anniversary: anniversary is DateTime? ? anniversary : this.anniversary,
      lastBirthdayGreetingYear: lastBirthdayGreetingYear is int?
          ? lastBirthdayGreetingYear
          : this.lastBirthdayGreetingYear,
      lastAnniversaryGreetingYear: lastAnniversaryGreetingYear is int?
          ? lastAnniversaryGreetingYear
          : this.lastAnniversaryGreetingYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
