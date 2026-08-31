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
import 'till_display_item.dart' as _i2;
import 'package:kola_server/src/generated/protocol.dart' as _i3;

abstract class TillDisplayState
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TillDisplayState._({
    required this.businessName,
    required this.status,
    required this.items,
    required this.subtotalMinor,
    required this.currency,
    required this.updatedAt,
  });

  factory TillDisplayState({
    required String businessName,
    required String status,
    required List<_i2.TillDisplayItem> items,
    required int subtotalMinor,
    required String currency,
    required DateTime updatedAt,
  }) = _TillDisplayStateImpl;

  factory TillDisplayState.fromJson(Map<String, dynamic> jsonSerialization) {
    return TillDisplayState(
      businessName: jsonSerialization['businessName'] as String,
      status: jsonSerialization['status'] as String,
      items: _i3.Protocol().deserialize<List<_i2.TillDisplayItem>>(
        jsonSerialization['items'],
      ),
      subtotalMinor: jsonSerialization['subtotalMinor'] as int,
      currency: jsonSerialization['currency'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String businessName;

  String status;

  List<_i2.TillDisplayItem> items;

  int subtotalMinor;

  String currency;

  DateTime updatedAt;

  /// Returns a shallow copy of this [TillDisplayState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TillDisplayState copyWith({
    String? businessName,
    String? status,
    List<_i2.TillDisplayItem>? items,
    int? subtotalMinor,
    String? currency,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TillDisplayState',
      'businessName': businessName,
      'status': status,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'subtotalMinor': subtotalMinor,
      'currency': currency,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TillDisplayState',
      'businessName': businessName,
      'status': status,
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'subtotalMinor': subtotalMinor,
      'currency': currency,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TillDisplayStateImpl extends TillDisplayState {
  _TillDisplayStateImpl({
    required String businessName,
    required String status,
    required List<_i2.TillDisplayItem> items,
    required int subtotalMinor,
    required String currency,
    required DateTime updatedAt,
  }) : super._(
         businessName: businessName,
         status: status,
         items: items,
         subtotalMinor: subtotalMinor,
         currency: currency,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TillDisplayState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TillDisplayState copyWith({
    String? businessName,
    String? status,
    List<_i2.TillDisplayItem>? items,
    int? subtotalMinor,
    String? currency,
    DateTime? updatedAt,
  }) {
    return TillDisplayState(
      businessName: businessName ?? this.businessName,
      status: status ?? this.status,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
