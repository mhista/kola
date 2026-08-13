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
import 'api_key.dart' as _i2;
import 'package:kola_client/src/protocol/protocol.dart' as _i3;

abstract class CreatedApiKey implements _i1.SerializableModel {
  CreatedApiKey._({
    required this.key,
    required this.plaintext,
  });

  factory CreatedApiKey({
    required _i2.ApiKey key,
    required String plaintext,
  }) = _CreatedApiKeyImpl;

  factory CreatedApiKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return CreatedApiKey(
      key: _i3.Protocol().deserialize<_i2.ApiKey>(jsonSerialization['key']),
      plaintext: jsonSerialization['plaintext'] as String,
    );
  }

  _i2.ApiKey key;

  String plaintext;

  /// Returns a shallow copy of this [CreatedApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreatedApiKey copyWith({
    _i2.ApiKey? key,
    String? plaintext,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreatedApiKey',
      'key': key.toJson(),
      'plaintext': plaintext,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CreatedApiKeyImpl extends CreatedApiKey {
  _CreatedApiKeyImpl({
    required _i2.ApiKey key,
    required String plaintext,
  }) : super._(
         key: key,
         plaintext: plaintext,
       );

  /// Returns a shallow copy of this [CreatedApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreatedApiKey copyWith({
    _i2.ApiKey? key,
    String? plaintext,
  }) {
    return CreatedApiKey(
      key: key ?? this.key.copyWith(),
      plaintext: plaintext ?? this.plaintext,
    );
  }
}
