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

abstract class AnalyticsSegment implements _i1.SerializableModel {
  AnalyticsSegment._({
    required this.label,
    required this.conversations,
    required this.orders,
    required this.revenueMinor,
    this.deltaPct,
  });

  factory AnalyticsSegment({
    required String label,
    required int conversations,
    required int orders,
    required int revenueMinor,
    double? deltaPct,
  }) = _AnalyticsSegmentImpl;

  factory AnalyticsSegment.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsSegment(
      label: jsonSerialization['label'] as String,
      conversations: jsonSerialization['conversations'] as int,
      orders: jsonSerialization['orders'] as int,
      revenueMinor: jsonSerialization['revenueMinor'] as int,
      deltaPct: (jsonSerialization['deltaPct'] as num?)?.toDouble(),
    );
  }

  String label;

  int conversations;

  int orders;

  int revenueMinor;

  double? deltaPct;

  /// Returns a shallow copy of this [AnalyticsSegment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnalyticsSegment copyWith({
    String? label,
    int? conversations,
    int? orders,
    int? revenueMinor,
    double? deltaPct,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsSegment',
      'label': label,
      'conversations': conversations,
      'orders': orders,
      'revenueMinor': revenueMinor,
      if (deltaPct != null) 'deltaPct': deltaPct,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnalyticsSegmentImpl extends AnalyticsSegment {
  _AnalyticsSegmentImpl({
    required String label,
    required int conversations,
    required int orders,
    required int revenueMinor,
    double? deltaPct,
  }) : super._(
         label: label,
         conversations: conversations,
         orders: orders,
         revenueMinor: revenueMinor,
         deltaPct: deltaPct,
       );

  /// Returns a shallow copy of this [AnalyticsSegment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnalyticsSegment copyWith({
    String? label,
    int? conversations,
    int? orders,
    int? revenueMinor,
    Object? deltaPct = _Undefined,
  }) {
    return AnalyticsSegment(
      label: label ?? this.label,
      conversations: conversations ?? this.conversations,
      orders: orders ?? this.orders,
      revenueMinor: revenueMinor ?? this.revenueMinor,
      deltaPct: deltaPct is double? ? deltaPct : this.deltaPct,
    );
  }
}
