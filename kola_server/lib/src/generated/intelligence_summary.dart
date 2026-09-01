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
import 'intelligence_product.dart' as _i2;
import 'package:kola_server/src/generated/protocol.dart' as _i3;

abstract class IntelligenceSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  IntelligenceSummary._({
    required this.workspaceId,
    required this.periodDays,
    required this.currency,
    required this.revenueMinor,
    this.revenueDeltaPct,
    required this.topProducts,
    required this.narrative,
    required this.narrativeIsTemplate,
  });

  factory IntelligenceSummary({
    required int workspaceId,
    required int periodDays,
    required String currency,
    required int revenueMinor,
    double? revenueDeltaPct,
    required List<_i2.IntelligenceProduct> topProducts,
    required String narrative,
    required bool narrativeIsTemplate,
  }) = _IntelligenceSummaryImpl;

  factory IntelligenceSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return IntelligenceSummary(
      workspaceId: jsonSerialization['workspaceId'] as int,
      periodDays: jsonSerialization['periodDays'] as int,
      currency: jsonSerialization['currency'] as String,
      revenueMinor: jsonSerialization['revenueMinor'] as int,
      revenueDeltaPct: (jsonSerialization['revenueDeltaPct'] as num?)
          ?.toDouble(),
      topProducts: _i3.Protocol().deserialize<List<_i2.IntelligenceProduct>>(
        jsonSerialization['topProducts'],
      ),
      narrative: jsonSerialization['narrative'] as String,
      narrativeIsTemplate: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['narrativeIsTemplate'],
      ),
    );
  }

  int workspaceId;

  int periodDays;

  String currency;

  int revenueMinor;

  double? revenueDeltaPct;

  List<_i2.IntelligenceProduct> topProducts;

  String narrative;

  bool narrativeIsTemplate;

  /// Returns a shallow copy of this [IntelligenceSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IntelligenceSummary copyWith({
    int? workspaceId,
    int? periodDays,
    String? currency,
    int? revenueMinor,
    double? revenueDeltaPct,
    List<_i2.IntelligenceProduct>? topProducts,
    String? narrative,
    bool? narrativeIsTemplate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IntelligenceSummary',
      'workspaceId': workspaceId,
      'periodDays': periodDays,
      'currency': currency,
      'revenueMinor': revenueMinor,
      if (revenueDeltaPct != null) 'revenueDeltaPct': revenueDeltaPct,
      'topProducts': topProducts.toJson(valueToJson: (v) => v.toJson()),
      'narrative': narrative,
      'narrativeIsTemplate': narrativeIsTemplate,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IntelligenceSummary',
      'workspaceId': workspaceId,
      'periodDays': periodDays,
      'currency': currency,
      'revenueMinor': revenueMinor,
      if (revenueDeltaPct != null) 'revenueDeltaPct': revenueDeltaPct,
      'topProducts': topProducts.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'narrative': narrative,
      'narrativeIsTemplate': narrativeIsTemplate,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IntelligenceSummaryImpl extends IntelligenceSummary {
  _IntelligenceSummaryImpl({
    required int workspaceId,
    required int periodDays,
    required String currency,
    required int revenueMinor,
    double? revenueDeltaPct,
    required List<_i2.IntelligenceProduct> topProducts,
    required String narrative,
    required bool narrativeIsTemplate,
  }) : super._(
         workspaceId: workspaceId,
         periodDays: periodDays,
         currency: currency,
         revenueMinor: revenueMinor,
         revenueDeltaPct: revenueDeltaPct,
         topProducts: topProducts,
         narrative: narrative,
         narrativeIsTemplate: narrativeIsTemplate,
       );

  /// Returns a shallow copy of this [IntelligenceSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IntelligenceSummary copyWith({
    int? workspaceId,
    int? periodDays,
    String? currency,
    int? revenueMinor,
    Object? revenueDeltaPct = _Undefined,
    List<_i2.IntelligenceProduct>? topProducts,
    String? narrative,
    bool? narrativeIsTemplate,
  }) {
    return IntelligenceSummary(
      workspaceId: workspaceId ?? this.workspaceId,
      periodDays: periodDays ?? this.periodDays,
      currency: currency ?? this.currency,
      revenueMinor: revenueMinor ?? this.revenueMinor,
      revenueDeltaPct: revenueDeltaPct is double?
          ? revenueDeltaPct
          : this.revenueDeltaPct,
      topProducts:
          topProducts ?? this.topProducts.map((e0) => e0.copyWith()).toList(),
      narrative: narrative ?? this.narrative,
      narrativeIsTemplate: narrativeIsTemplate ?? this.narrativeIsTemplate,
    );
  }
}
