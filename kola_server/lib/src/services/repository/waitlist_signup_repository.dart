// waitlist_signup_repository.dart
//
// All database read/write operations for WaitlistSignup records.
//
// UPSERT-BY-EMAIL: the landing page has three separate forms that could
// plausibly all be filled in by the same visitor (hero form now, footer
// form on a later visit). Rather than erroring on the unique email
// constraint, [upsertByEmail] treats a repeat signup as "update what they
// told us this time," matching the actual user expectation of "I already
// gave you my email, this shouldn't be an error."

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/waitlist_signup_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WaitlistSignupRepository');

const _dto = WaitlistSignupDto();

class WaitlistSignupRepository {
  const WaitlistSignupRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<WaitlistSignup?> findByEmail(String email) async {
    _log.fine('findByEmail($email)');
    final response = await supabase
        .from('waitlist_signups')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Total signup count — the one number worth showing on an internal
  /// dashboard or a pitch-deck traction slide once it's non-zero
  /// (DECK_DESIGN_PROMPT.md Slide 12).
  Future<int> countAll() async {
    final rows = await supabase.from('waitlist_signups').select('id');
    return (rows as List).length;
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create-or-update a signup by email — see class-level note on why this
  /// is an upsert rather than a plain insert.
  Future<WaitlistSignup> upsertByEmail({
    required String email,
    String? name,
    String? phone,
    String? businessType,
    required String source,
  }) async {
    _log.info('upsertByEmail email=$email source=$source');

    final signup = WaitlistSignup(
      name: name,
      email: email,
      phone: phone,
      businessType: businessType,
      source: source,
      createdAt: DateTime.now().toUtc(),
    );

    final row = _dto.toRow(signup, includeId: false);
    row['created_at'] = signup.createdAt.toIso8601String();

    final response = await supabase
        .from('waitlist_signups')
        .upsert(row, onConflict: 'email')
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
