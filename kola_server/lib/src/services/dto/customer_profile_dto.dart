// customer_profile_dto.dart
//
// Translates between:
//   Serverpod model  → CustomerProfile  (generated/customer_profile.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: customer_profiles
// Schema: docs/migrations/012_customer_profiles.sql (task #132 / Phase 8b).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class CustomerProfileDto extends BaseDto<CustomerProfile> {
  const CustomerProfileDto();

  @override
  CustomerProfile fromRow(Map<String, dynamic> row) {
    return CustomerProfile(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      conversationId: row['conversation_id'] as int,
      birthday: row['birthday'] == null ? null : DateTime.parse(row['birthday'] as String),
      anniversary: row['anniversary'] == null ? null : DateTime.parse(row['anniversary'] as String),
      lastBirthdayGreetingYear: row['last_birthday_greeting_year'] as int?,
      lastAnniversaryGreetingYear: row['last_anniversary_greeting_year'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(CustomerProfile model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'conversation_id': model.conversationId,
      'birthday': model.birthday?.toIso8601String(),
      'anniversary': model.anniversary?.toIso8601String(),
      'last_birthday_greeting_year': model.lastBirthdayGreetingYear,
      'last_anniversary_greeting_year': model.lastAnniversaryGreetingYear,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
