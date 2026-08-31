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
import 'public_catalog_item.dart' as _i2;
import 'package:kola_server/src/generated/protocol.dart' as _i3;

abstract class PublicCatalog
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PublicCatalog._({
    required this.businessName,
    required this.items,
  });

  factory PublicCatalog({
    required String businessName,
    required List<_i2.PublicCatalogItem> items,
  }) = _PublicCatalogImpl;

  factory PublicCatalog.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicCatalog(
      businessName: jsonSerialization['businessName'] as String,
      items: _i3.Protocol().deserialize<List<_i2.PublicCatalogItem>>(
        jsonSerialization['items'],
      ),
    );
  }

  String businessName;

  List<_i2.PublicCatalogItem> items;

  /// Returns a shallow copy of this [PublicCatalog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PublicCatalog copyWith({
    String? businessName,
    List<_i2.PublicCatalogItem>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicCatalog',
      'businessName': businessName,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicCatalog',
      'businessName': businessName,
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PublicCatalogImpl extends PublicCatalog {
  _PublicCatalogImpl({
    required String businessName,
    required List<_i2.PublicCatalogItem> items,
  }) : super._(
         businessName: businessName,
         items: items,
       );

  /// Returns a shallow copy of this [PublicCatalog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PublicCatalog copyWith({
    String? businessName,
    List<_i2.PublicCatalogItem>? items,
  }) {
    return PublicCatalog(
      businessName: businessName ?? this.businessName,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
