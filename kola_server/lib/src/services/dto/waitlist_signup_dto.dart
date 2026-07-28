// waitlist_signup_dto.dart
//
// Translates between:
//   Serverpod model  → WaitlistSignup  (generated/waitlist_signup.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: waitlist_signups
// Schema + RLS policy: docs/migrations/002_waitlist_signups.sql (source of
// truth — not duplicated here to avoid the two drifting apart over time).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class WaitlistSignupDto extends BaseDto<WaitlistSignup> {
  const WaitlistSignupDto();

  @override
  WaitlistSignup fromRow(Map<String, dynamic> row) {
    return WaitlistSignup(
      id: row['id'] as int?,
      name: row['name'] as String?,
      email: row['email'] as String,
      phone: row['phone'] as String?,
      businessType: row['business_type'] as String?,
      source: row['source'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(WaitlistSignup model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'name': model.name,
      'email': model.email,
      'phone': model.phone,
      'business_type': model.businessType,
      'source': model.source,
      // created_at is set by Supabase default — this row is never updated
    };
  }
}
