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

abstract class WorkspaceAnswerAction implements _i1.SerializableModel {
  WorkspaceAnswerAction._({
    required this.intent,
    required this.label,
    required this.route,
    this.productId,
  });

  factory WorkspaceAnswerAction({
    required String intent,
    required String label,
    required String route,
    int? productId,
  }) = _WorkspaceAnswerActionImpl;

  factory WorkspaceAnswerAction.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceAnswerAction(
      intent: jsonSerialization['intent'] as String,
      label: jsonSerialization['label'] as String,
      route: jsonSerialization['route'] as String,
      productId: jsonSerialization['productId'] as int?,
    );
  }

  String intent;

  String label;

  String route;

  int? productId;

  /// Returns a shallow copy of this [WorkspaceAnswerAction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceAnswerAction copyWith({
    String? intent,
    String? label,
    String? route,
    int? productId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceAnswerAction',
      'intent': intent,
      'label': label,
      'route': route,
      if (productId != null) 'productId': productId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceAnswerActionImpl extends WorkspaceAnswerAction {
  _WorkspaceAnswerActionImpl({
    required String intent,
    required String label,
    required String route,
    int? productId,
  }) : super._(
         intent: intent,
         label: label,
         route: route,
         productId: productId,
       );

  /// Returns a shallow copy of this [WorkspaceAnswerAction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceAnswerAction copyWith({
    String? intent,
    String? label,
    String? route,
    Object? productId = _Undefined,
  }) {
    return WorkspaceAnswerAction(
      intent: intent ?? this.intent,
      label: label ?? this.label,
      route: route ?? this.route,
      productId: productId is int? ? productId : this.productId,
    );
  }
}
