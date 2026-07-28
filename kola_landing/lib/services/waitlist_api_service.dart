// waitlist_api_service.dart
//
// Talks directly to Supabase's REST API (PostgREST) to record a waitlist
// signup — no Serverpod round-trip, no auth. Same architectural choice
// degenbot_web already made for its dashboard reads/writes
// (lib/services/api_service.dart there): a Jaspr client-mode bundle
// calling Supabase directly with the anon key is a proven, working
// pattern in this codebase family, and there is no auth requirement here
// that would justify going through kola_server's WaitlistEndpoint instead
// (that endpoint still exists — see kola_server/lib/src/endpoints/
// waitlist_endpoint.dart — for any future internal/admin caller that
// needs the same logic from inside our own trusted server code).
//
// REQUIRED SUPABASE SETUP (Row Level Security):
//   Anonymous (anon-key) requests must be allowed to INSERT into
//   waitlist_signups, but NOT to SELECT/UPDATE/DELETE — visitors can add
//   themselves to the list, never read who else is on it or touch an
//   existing row.
//
//     alter table waitlist_signups enable row level security;
//     create policy "anon can insert waitlist signups"
//       on waitlist_signups for insert
//       to anon
//       with check (true);
//
// WHY THIS IS A PLAIN INSERT, NOT AN UPSERT (fixed a real bug — read
// before changing this back):
//   This used to call PostgREST with `?on_conflict=email` plus
//   `Prefer: resolution=merge-duplicates`, to mirror
//   WaitlistSignupRepository.upsertByEmail's server-side behavior (a
//   repeat signup updates the row instead of erroring). That's broken
//   for an ANON-key caller specifically: Postgres requires UPDATE
//   privilege/RLS policy on the table for ANY `INSERT ... ON CONFLICT DO
//   UPDATE` statement to even be planned — not just when a conflict
//   actually occurs at runtime. Since anon deliberately has no UPDATE
//   policy here (see the header comment above — visitors should never be
//   able to modify an existing row, including someone else's, which is
//   exactly what a permissive anon UPDATE policy would allow), EVERY
//   submission through the upsert path failed with RLS error 42501,
//   fresh email or repeat — the "on_conflict"/"merge-duplicates" pair
//   forced Postgres to check for UPDATE permission unconditionally.
//
//   The fix: plain INSERT, no on_conflict. If the email already exists,
//   Postgres raises a unique_violation (Postgres code 23505), which
//   PostgREST surfaces as HTTP 409 — submit() below treats that 409 as a
//   successful "you're already on the list" outcome rather than an
//   error, since that's the correct UX either way and it never needs
//   UPDATE privilege at all. The server-side upsertByEmail() path
//   (kola_server, using the service_role key) is completely unaffected —
//   service_role bypasses RLS entirely, so it never hit this bug.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class WaitlistApiService {
  WaitlistApiService()
    : _endpoint = Uri.parse('${Env.supabaseUrl}/rest/v1/waitlist_signups'),
      _headers = {
        'apikey': Env.supabaseAnonKey,
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      };

  final Uri _endpoint;
  final Map<String, String> _headers;

  /// Submits a waitlist signup. [source] identifies which on-page form
  /// this came from ('hero' | 'waitlist_section' | 'footer'). A repeat
  /// submission of an already-registered email is treated as success
  /// (see this file's header comment for why) — only a genuine error
  /// response throws, and callers show their own error state for that.
  Future<void> submit({
    required String email,
    required String source,
    String? name,
    String? phone,
    String? businessType,
  }) async {
    final trimmedEmail = email.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmedEmail)) {
      throw const FormatException('Please enter a valid email address.');
    }

    final body = jsonEncode({
      'email': trimmedEmail,
      'source': source,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (businessType != null && businessType.trim().isNotEmpty)
        'business_type': businessType.trim(),
    });

    final response = await http.post(_endpoint, headers: _headers, body: body);

    // 409 Conflict == unique_violation on email — already on the list,
    // which is a successful outcome from the visitor's point of view.
    if (response.statusCode == 409) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Waitlist signup failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
