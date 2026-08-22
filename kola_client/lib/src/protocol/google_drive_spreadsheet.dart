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

abstract class GoogleDriveSpreadsheet implements _i1.SerializableModel {
  GoogleDriveSpreadsheet._({
    required this.id,
    required this.name,
    this.webViewLink,
    required this.alreadyConnected,
  });

  factory GoogleDriveSpreadsheet({
    required String id,
    required String name,
    String? webViewLink,
    required bool alreadyConnected,
  }) = _GoogleDriveSpreadsheetImpl;

  factory GoogleDriveSpreadsheet.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GoogleDriveSpreadsheet(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      webViewLink: jsonSerialization['webViewLink'] as String?,
      alreadyConnected: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['alreadyConnected'],
      ),
    );
  }

  String id;

  String name;

  String? webViewLink;

  bool alreadyConnected;

  /// Returns a shallow copy of this [GoogleDriveSpreadsheet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GoogleDriveSpreadsheet copyWith({
    String? id,
    String? name,
    String? webViewLink,
    bool? alreadyConnected,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GoogleDriveSpreadsheet',
      'id': id,
      'name': name,
      if (webViewLink != null) 'webViewLink': webViewLink,
      'alreadyConnected': alreadyConnected,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GoogleDriveSpreadsheetImpl extends GoogleDriveSpreadsheet {
  _GoogleDriveSpreadsheetImpl({
    required String id,
    required String name,
    String? webViewLink,
    required bool alreadyConnected,
  }) : super._(
         id: id,
         name: name,
         webViewLink: webViewLink,
         alreadyConnected: alreadyConnected,
       );

  /// Returns a shallow copy of this [GoogleDriveSpreadsheet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GoogleDriveSpreadsheet copyWith({
    String? id,
    String? name,
    Object? webViewLink = _Undefined,
    bool? alreadyConnected,
  }) {
    return GoogleDriveSpreadsheet(
      id: id ?? this.id,
      name: name ?? this.name,
      webViewLink: webViewLink is String? ? webViewLink : this.webViewLink,
      alreadyConnected: alreadyConnected ?? this.alreadyConnected,
    );
  }
}
