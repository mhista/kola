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

abstract class ConnectorFieldSpec
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConnectorFieldSpec._({
    required this.key,
    required this.label,
    required this.placeholder,
    required this.secret,
  });

  factory ConnectorFieldSpec({
    required String key,
    required String label,
    required String placeholder,
    required bool secret,
  }) = _ConnectorFieldSpecImpl;

  factory ConnectorFieldSpec.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectorFieldSpec(
      key: jsonSerialization['key'] as String,
      label: jsonSerialization['label'] as String,
      placeholder: jsonSerialization['placeholder'] as String,
      secret: _i1.BoolJsonExtension.fromJson(jsonSerialization['secret']),
    );
  }

  String key;

  String label;

  String placeholder;

  bool secret;

  /// Returns a shallow copy of this [ConnectorFieldSpec]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectorFieldSpec copyWith({
    String? key,
    String? label,
    String? placeholder,
    bool? secret,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectorFieldSpec',
      'key': key,
      'label': label,
      'placeholder': placeholder,
      'secret': secret,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConnectorFieldSpec',
      'key': key,
      'label': label,
      'placeholder': placeholder,
      'secret': secret,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConnectorFieldSpecImpl extends ConnectorFieldSpec {
  _ConnectorFieldSpecImpl({
    required String key,
    required String label,
    required String placeholder,
    required bool secret,
  }) : super._(
         key: key,
         label: label,
         placeholder: placeholder,
         secret: secret,
       );

  /// Returns a shallow copy of this [ConnectorFieldSpec]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectorFieldSpec copyWith({
    String? key,
    String? label,
    String? placeholder,
    bool? secret,
  }) {
    return ConnectorFieldSpec(
      key: key ?? this.key,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      secret: secret ?? this.secret,
    );
  }
}
