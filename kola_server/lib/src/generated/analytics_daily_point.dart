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

abstract class AnalyticsDailyPoint
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AnalyticsDailyPoint._({
    required this.date,
    required this.grossMinor,
  });

  factory AnalyticsDailyPoint({
    required DateTime date,
    required int grossMinor,
  }) = _AnalyticsDailyPointImpl;

  factory AnalyticsDailyPoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsDailyPoint(
      date: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      grossMinor: jsonSerialization['grossMinor'] as int,
    );
  }

  DateTime date;

  int grossMinor;

  /// Returns a shallow copy of this [AnalyticsDailyPoint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnalyticsDailyPoint copyWith({
    DateTime? date,
    int? grossMinor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsDailyPoint',
      'date': date.toJson(),
      'grossMinor': grossMinor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsDailyPoint',
      'date': date.toJson(),
      'grossMinor': grossMinor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AnalyticsDailyPointImpl extends AnalyticsDailyPoint {
  _AnalyticsDailyPointImpl({
    required DateTime date,
    required int grossMinor,
  }) : super._(
         date: date,
         grossMinor: grossMinor,
       );

  /// Returns a shallow copy of this [AnalyticsDailyPoint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnalyticsDailyPoint copyWith({
    DateTime? date,
    int? grossMinor,
  }) {
    return AnalyticsDailyPoint(
      date: date ?? this.date,
      grossMinor: grossMinor ?? this.grossMinor,
    );
  }
}
