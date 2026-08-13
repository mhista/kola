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

abstract class ProductMedia implements _i1.SerializableModel {
  ProductMedia._({
    this.id,
    required this.productId,
    required this.kind,
    required this.imagekitFileId,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    required this.position,
    required this.createdAt,
  });

  factory ProductMedia({
    int? id,
    required int productId,
    required String kind,
    required String imagekitFileId,
    required String url,
    String? thumbnailUrl,
    int? width,
    int? height,
    required int position,
    required DateTime createdAt,
  }) = _ProductMediaImpl;

  factory ProductMedia.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProductMedia(
      id: jsonSerialization['id'] as int?,
      productId: jsonSerialization['productId'] as int,
      kind: jsonSerialization['kind'] as String,
      imagekitFileId: jsonSerialization['imagekitFileId'] as String,
      url: jsonSerialization['url'] as String,
      thumbnailUrl: jsonSerialization['thumbnailUrl'] as String?,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      position: jsonSerialization['position'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int productId;

  String kind;

  String imagekitFileId;

  String url;

  String? thumbnailUrl;

  int? width;

  int? height;

  int position;

  DateTime createdAt;

  /// Returns a shallow copy of this [ProductMedia]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductMedia copyWith({
    int? id,
    int? productId,
    String? kind,
    String? imagekitFileId,
    String? url,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? position,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductMedia',
      if (id != null) 'id': id,
      'productId': productId,
      'kind': kind,
      'imagekitFileId': imagekitFileId,
      'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'position': position,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductMediaImpl extends ProductMedia {
  _ProductMediaImpl({
    int? id,
    required int productId,
    required String kind,
    required String imagekitFileId,
    required String url,
    String? thumbnailUrl,
    int? width,
    int? height,
    required int position,
    required DateTime createdAt,
  }) : super._(
         id: id,
         productId: productId,
         kind: kind,
         imagekitFileId: imagekitFileId,
         url: url,
         thumbnailUrl: thumbnailUrl,
         width: width,
         height: height,
         position: position,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ProductMedia]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductMedia copyWith({
    Object? id = _Undefined,
    int? productId,
    String? kind,
    String? imagekitFileId,
    String? url,
    Object? thumbnailUrl = _Undefined,
    Object? width = _Undefined,
    Object? height = _Undefined,
    int? position,
    DateTime? createdAt,
  }) {
    return ProductMedia(
      id: id is int? ? id : this.id,
      productId: productId ?? this.productId,
      kind: kind ?? this.kind,
      imagekitFileId: imagekitFileId ?? this.imagekitFileId,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl is String? ? thumbnailUrl : this.thumbnailUrl,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
