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

abstract class EndOfDayReport implements _i1.SerializableModel {
  EndOfDayReport._({
    required this.workspaceId,
    required this.reportDate,
    required this.grossMinor,
    required this.transactionCount,
    required this.refundsMinor,
    required this.refundCount,
    required this.byPaymentMethodJson,
    this.insightText,
  });

  factory EndOfDayReport({
    required int workspaceId,
    required DateTime reportDate,
    required int grossMinor,
    required int transactionCount,
    required int refundsMinor,
    required int refundCount,
    required String byPaymentMethodJson,
    String? insightText,
  }) = _EndOfDayReportImpl;

  factory EndOfDayReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return EndOfDayReport(
      workspaceId: jsonSerialization['workspaceId'] as int,
      reportDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['reportDate'],
      ),
      grossMinor: jsonSerialization['grossMinor'] as int,
      transactionCount: jsonSerialization['transactionCount'] as int,
      refundsMinor: jsonSerialization['refundsMinor'] as int,
      refundCount: jsonSerialization['refundCount'] as int,
      byPaymentMethodJson: jsonSerialization['byPaymentMethodJson'] as String,
      insightText: jsonSerialization['insightText'] as String?,
    );
  }

  int workspaceId;

  DateTime reportDate;

  int grossMinor;

  int transactionCount;

  int refundsMinor;

  int refundCount;

  String byPaymentMethodJson;

  String? insightText;

  /// Returns a shallow copy of this [EndOfDayReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EndOfDayReport copyWith({
    int? workspaceId,
    DateTime? reportDate,
    int? grossMinor,
    int? transactionCount,
    int? refundsMinor,
    int? refundCount,
    String? byPaymentMethodJson,
    String? insightText,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EndOfDayReport',
      'workspaceId': workspaceId,
      'reportDate': reportDate.toJson(),
      'grossMinor': grossMinor,
      'transactionCount': transactionCount,
      'refundsMinor': refundsMinor,
      'refundCount': refundCount,
      'byPaymentMethodJson': byPaymentMethodJson,
      if (insightText != null) 'insightText': insightText,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EndOfDayReportImpl extends EndOfDayReport {
  _EndOfDayReportImpl({
    required int workspaceId,
    required DateTime reportDate,
    required int grossMinor,
    required int transactionCount,
    required int refundsMinor,
    required int refundCount,
    required String byPaymentMethodJson,
    String? insightText,
  }) : super._(
         workspaceId: workspaceId,
         reportDate: reportDate,
         grossMinor: grossMinor,
         transactionCount: transactionCount,
         refundsMinor: refundsMinor,
         refundCount: refundCount,
         byPaymentMethodJson: byPaymentMethodJson,
         insightText: insightText,
       );

  /// Returns a shallow copy of this [EndOfDayReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EndOfDayReport copyWith({
    int? workspaceId,
    DateTime? reportDate,
    int? grossMinor,
    int? transactionCount,
    int? refundsMinor,
    int? refundCount,
    String? byPaymentMethodJson,
    Object? insightText = _Undefined,
  }) {
    return EndOfDayReport(
      workspaceId: workspaceId ?? this.workspaceId,
      reportDate: reportDate ?? this.reportDate,
      grossMinor: grossMinor ?? this.grossMinor,
      transactionCount: transactionCount ?? this.transactionCount,
      refundsMinor: refundsMinor ?? this.refundsMinor,
      refundCount: refundCount ?? this.refundCount,
      byPaymentMethodJson: byPaymentMethodJson ?? this.byPaymentMethodJson,
      insightText: insightText is String? ? insightText : this.insightText,
    );
  }
}
