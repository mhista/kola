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

abstract class Bot implements _i1.SerializableModel {
  Bot._({
    this.id,
    required this.workspaceId,
    required this.name,
    required this.archetype,
    required this.status,
    this.knowledgeSeed,
    this.costSavingTelegramLink,
    this.costSavingAlternateWhatsapp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bot({
    int? id,
    required int workspaceId,
    required String name,
    required String archetype,
    required String status,
    String? knowledgeSeed,
    String? costSavingTelegramLink,
    String? costSavingAlternateWhatsapp,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BotImpl;

  factory Bot.fromJson(Map<String, dynamic> jsonSerialization) {
    return Bot(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      archetype: jsonSerialization['archetype'] as String,
      status: jsonSerialization['status'] as String,
      knowledgeSeed: jsonSerialization['knowledgeSeed'] as String?,
      costSavingTelegramLink:
          jsonSerialization['costSavingTelegramLink'] as String?,
      costSavingAlternateWhatsapp:
          jsonSerialization['costSavingAlternateWhatsapp'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  String name;

  String archetype;

  String status;

  String? knowledgeSeed;

  String? costSavingTelegramLink;

  String? costSavingAlternateWhatsapp;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Bot copyWith({
    int? id,
    int? workspaceId,
    String? name,
    String? archetype,
    String? status,
    String? knowledgeSeed,
    String? costSavingTelegramLink,
    String? costSavingAlternateWhatsapp,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Bot',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'archetype': archetype,
      'status': status,
      if (knowledgeSeed != null) 'knowledgeSeed': knowledgeSeed,
      if (costSavingTelegramLink != null)
        'costSavingTelegramLink': costSavingTelegramLink,
      if (costSavingAlternateWhatsapp != null)
        'costSavingAlternateWhatsapp': costSavingAlternateWhatsapp,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotImpl extends Bot {
  _BotImpl({
    int? id,
    required int workspaceId,
    required String name,
    required String archetype,
    required String status,
    String? knowledgeSeed,
    String? costSavingTelegramLink,
    String? costSavingAlternateWhatsapp,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         archetype: archetype,
         status: status,
         knowledgeSeed: knowledgeSeed,
         costSavingTelegramLink: costSavingTelegramLink,
         costSavingAlternateWhatsapp: costSavingAlternateWhatsapp,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Bot copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    String? archetype,
    String? status,
    Object? knowledgeSeed = _Undefined,
    Object? costSavingTelegramLink = _Undefined,
    Object? costSavingAlternateWhatsapp = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bot(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      archetype: archetype ?? this.archetype,
      status: status ?? this.status,
      knowledgeSeed: knowledgeSeed is String?
          ? knowledgeSeed
          : this.knowledgeSeed,
      costSavingTelegramLink: costSavingTelegramLink is String?
          ? costSavingTelegramLink
          : this.costSavingTelegramLink,
      costSavingAlternateWhatsapp: costSavingAlternateWhatsapp is String?
          ? costSavingAlternateWhatsapp
          : this.costSavingAlternateWhatsapp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
