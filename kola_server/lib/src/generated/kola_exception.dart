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

abstract class KolaException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  KolaException._({
    required this.message,
    this.code,
  });

  factory KolaException({
    required String message,
    String? code,
  }) = _KolaExceptionImpl;

  factory KolaException.fromJson(Map<String, dynamic> jsonSerialization) {
    return KolaException(
      message: jsonSerialization['message'] as String,
      code: jsonSerialization['code'] as String?,
    );
  }

  String message;

  String? code;

  /// Returns a shallow copy of this [KolaException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  KolaException copyWith({
    String? message,
    String? code,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'KolaException',
      'message': message,
      if (code != null) 'code': code,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'KolaException',
      'message': message,
      if (code != null) 'code': code,
    };
  }

  @override
  String toString() {
    return 'KolaException(message: $message, code: $code)';
  }
}

class _Undefined {}

class _KolaExceptionImpl extends KolaException {
  _KolaExceptionImpl({
    required String message,
    String? code,
  }) : super._(
         message: message,
         code: code,
       );

  /// Returns a shallow copy of this [KolaException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  KolaException copyWith({
    String? message,
    Object? code = _Undefined,
  }) {
    return KolaException(
      message: message ?? this.message,
      code: code is String? ? code : this.code,
    );
  }
}
