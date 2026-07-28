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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class WaitlistSignup implements _i1.SerializableModel {
  WaitlistSignup._({
    this.id,
    this.name,
    required this.email,
    this.phone,
    this.businessType,
    required this.source,
    required this.createdAt,
  });

  factory WaitlistSignup({
    int? id,
    String? name,
    required String email,
    String? phone,
    String? businessType,
    required String source,
    required DateTime createdAt,
  }) = _WaitlistSignupImpl;

  factory WaitlistSignup.fromJson(Map<String, dynamic> jsonSerialization) {
    return WaitlistSignup(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String?,
      email: jsonSerialization['email'] as String,
      phone: jsonSerialization['phone'] as String?,
      businessType: jsonSerialization['businessType'] as String?,
      source: jsonSerialization['source'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  String? name;

  String email;

  String? phone;

  String? businessType;

  String source;

  DateTime createdAt;

  /// Returns a shallow copy of this [WaitlistSignup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WaitlistSignup copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? businessType,
    String? source,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WaitlistSignup',
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (businessType != null) 'businessType': businessType,
      'source': source,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WaitlistSignupImpl extends WaitlistSignup {
  _WaitlistSignupImpl({
    int? id,
    String? name,
    required String email,
    String? phone,
    String? businessType,
    required String source,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         email: email,
         phone: phone,
         businessType: businessType,
         source: source,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WaitlistSignup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WaitlistSignup copyWith({
    Object? id = _Undefined,
    Object? name = _Undefined,
    String? email,
    Object? phone = _Undefined,
    Object? businessType = _Undefined,
    String? source,
    DateTime? createdAt,
  }) {
    return WaitlistSignup(
      id: id is int? ? id : this.id,
      name: name is String? ? name : this.name,
      email: email ?? this.email,
      phone: phone is String? ? phone : this.phone,
      businessType: businessType is String? ? businessType : this.businessType,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
