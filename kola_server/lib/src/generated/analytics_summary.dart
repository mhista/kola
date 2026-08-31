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
import 'analytics_daily_point.dart' as _i2;
import 'analytics_segment.dart' as _i3;
import 'package:kola_server/src/generated/protocol.dart' as _i4;

abstract class AnalyticsSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AnalyticsSummary._({
    required this.workspaceId,
    required this.periodDays,
    required this.currency,
    required this.dailyRevenue,
    required this.segments,
  });

  factory AnalyticsSummary({
    required int workspaceId,
    required int periodDays,
    required String currency,
    required List<_i2.AnalyticsDailyPoint> dailyRevenue,
    required List<_i3.AnalyticsSegment> segments,
  }) = _AnalyticsSummaryImpl;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsSummary(
      workspaceId: jsonSerialization['workspaceId'] as int,
      periodDays: jsonSerialization['periodDays'] as int,
      currency: jsonSerialization['currency'] as String,
      dailyRevenue: _i4.Protocol().deserialize<List<_i2.AnalyticsDailyPoint>>(
        jsonSerialization['dailyRevenue'],
      ),
      segments: _i4.Protocol().deserialize<List<_i3.AnalyticsSegment>>(
        jsonSerialization['segments'],
      ),
    );
  }

  int workspaceId;

  int periodDays;

  String currency;

  List<_i2.AnalyticsDailyPoint> dailyRevenue;

  List<_i3.AnalyticsSegment> segments;

  /// Returns a shallow copy of this [AnalyticsSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnalyticsSummary copyWith({
    int? workspaceId,
    int? periodDays,
    String? currency,
    List<_i2.AnalyticsDailyPoint>? dailyRevenue,
    List<_i3.AnalyticsSegment>? segments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsSummary',
      'workspaceId': workspaceId,
      'periodDays': periodDays,
      'currency': currency,
      'dailyRevenue': dailyRevenue.toJson(valueToJson: (v) => v.toJson()),
      'segments': segments.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsSummary',
      'workspaceId': workspaceId,
      'periodDays': periodDays,
      'currency': currency,
      'dailyRevenue': dailyRevenue.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'segments': segments.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AnalyticsSummaryImpl extends AnalyticsSummary {
  _AnalyticsSummaryImpl({
    required int workspaceId,
    required int periodDays,
    required String currency,
    required List<_i2.AnalyticsDailyPoint> dailyRevenue,
    required List<_i3.AnalyticsSegment> segments,
  }) : super._(
         workspaceId: workspaceId,
         periodDays: periodDays,
         currency: currency,
         dailyRevenue: dailyRevenue,
         segments: segments,
       );

  /// Returns a shallow copy of this [AnalyticsSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnalyticsSummary copyWith({
    int? workspaceId,
    int? periodDays,
    String? currency,
    List<_i2.AnalyticsDailyPoint>? dailyRevenue,
    List<_i3.AnalyticsSegment>? segments,
  }) {
    return AnalyticsSummary(
      workspaceId: workspaceId ?? this.workspaceId,
      periodDays: periodDays ?? this.periodDays,
      currency: currency ?? this.currency,
      dailyRevenue:
          dailyRevenue ?? this.dailyRevenue.map((e0) => e0.copyWith()).toList(),
      segments: segments ?? this.segments.map((e0) => e0.copyWith()).toList(),
    );
  }
}
