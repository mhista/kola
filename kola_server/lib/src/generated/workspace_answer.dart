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
import 'workspace_answer_action.dart' as _i2;
import 'knowledge_search_hit.dart' as _i3;
import 'package:kola_server/src/generated/protocol.dart' as _i4;

abstract class WorkspaceAnswer
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceAnswer._({
    required this.answer,
    required this.productIds,
    required this.actions,
    required this.citations,
    required this.generated,
    required this.providerName,
  });

  factory WorkspaceAnswer({
    required String answer,
    required List<int> productIds,
    required List<_i2.WorkspaceAnswerAction> actions,
    required List<_i3.KnowledgeSearchHit> citations,
    required bool generated,
    required String providerName,
  }) = _WorkspaceAnswerImpl;

  factory WorkspaceAnswer.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceAnswer(
      answer: jsonSerialization['answer'] as String,
      productIds: _i4.Protocol().deserialize<List<int>>(
        jsonSerialization['productIds'],
      ),
      actions: _i4.Protocol().deserialize<List<_i2.WorkspaceAnswerAction>>(
        jsonSerialization['actions'],
      ),
      citations: _i4.Protocol().deserialize<List<_i3.KnowledgeSearchHit>>(
        jsonSerialization['citations'],
      ),
      generated: _i1.BoolJsonExtension.fromJson(jsonSerialization['generated']),
      providerName: jsonSerialization['providerName'] as String,
    );
  }

  String answer;

  List<int> productIds;

  List<_i2.WorkspaceAnswerAction> actions;

  List<_i3.KnowledgeSearchHit> citations;

  bool generated;

  String providerName;

  /// Returns a shallow copy of this [WorkspaceAnswer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceAnswer copyWith({
    String? answer,
    List<int>? productIds,
    List<_i2.WorkspaceAnswerAction>? actions,
    List<_i3.KnowledgeSearchHit>? citations,
    bool? generated,
    String? providerName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceAnswer',
      'answer': answer,
      'productIds': productIds.toJson(),
      'actions': actions.toJson(valueToJson: (v) => v.toJson()),
      'citations': citations.toJson(valueToJson: (v) => v.toJson()),
      'generated': generated,
      'providerName': providerName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceAnswer',
      'answer': answer,
      'productIds': productIds.toJson(),
      'actions': actions.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'citations': citations.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'generated': generated,
      'providerName': providerName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _WorkspaceAnswerImpl extends WorkspaceAnswer {
  _WorkspaceAnswerImpl({
    required String answer,
    required List<int> productIds,
    required List<_i2.WorkspaceAnswerAction> actions,
    required List<_i3.KnowledgeSearchHit> citations,
    required bool generated,
    required String providerName,
  }) : super._(
         answer: answer,
         productIds: productIds,
         actions: actions,
         citations: citations,
         generated: generated,
         providerName: providerName,
       );

  /// Returns a shallow copy of this [WorkspaceAnswer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceAnswer copyWith({
    String? answer,
    List<int>? productIds,
    List<_i2.WorkspaceAnswerAction>? actions,
    List<_i3.KnowledgeSearchHit>? citations,
    bool? generated,
    String? providerName,
  }) {
    return WorkspaceAnswer(
      answer: answer ?? this.answer,
      productIds: productIds ?? this.productIds.map((e0) => e0).toList(),
      actions: actions ?? this.actions.map((e0) => e0.copyWith()).toList(),
      citations:
          citations ?? this.citations.map((e0) => e0.copyWith()).toList(),
      generated: generated ?? this.generated,
      providerName: providerName ?? this.providerName,
    );
  }
}
