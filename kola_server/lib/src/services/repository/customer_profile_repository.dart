// customer_profile_repository.dart
//
// All database read/write operations for CustomerProfile records (task
// #132 / Phase 8b).
//
// MULTI-TENANCY: [findByConversationScoped] filters by workspaceId, same
// convention as every other per-conversation repository in this
// project. [listWithUpcomingDates] is deliberately global (no
// workspaceId param) — same precedent as SupportTicketRepository.
// listOpenPastDeadline / ChannelRepository.listConnected: a background
// sweep needs every candidate row across every workspace in one query,
// not a workspace-by-workspace loop.
//
// N+1-SHAPED ON PURPOSE FOR NOW: [listWithUpcomingDates] fetches every
// profile with a non-null birthday or anniversary and leaves the actual
// "is it today" month/day comparison to the caller
// (CustomerCampaignSweepService), rather than trying to push a
// month/day-only match into a Postgres filter here. Fine at today's
// scale (a business's customer count with a saved birthday is small);
// a proper `where extract(month from birthday) = ? and extract(day...)`
// filter is a straightforward follow-up once that stops being true —
// same "flagged as acceptable now, not hidden" posture as
// WorkspaceEndpoint.listMyWorkspaces' own N+1 comment.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/customer_profile_dto.dart';
import 'supabase_client.dart';

final _log = Logger('CustomerProfileRepository');

const _dto = CustomerProfileDto();

class CustomerProfileRepository {
  const CustomerProfileRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<CustomerProfile?> findByConversationScoped(int conversationId, int workspaceId) async {
    _log.fine('findByConversationScoped($conversationId, workspaceId=$workspaceId)');
    final response = await supabase
        .from('customer_profiles')
        .select()
        .eq('conversation_id', conversationId)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every profile with a saved birthday OR anniversary, across every
  /// workspace — see file header on why this is global and why the
  /// actual date-matching happens one layer up. Fetches every
  /// customer_profiles row and filters the null-check in Dart rather
  /// than building an `.or(...)` PostgREST filter for it — this table is
  /// small and sparse by nature (most conversations never get a
  /// profile), so a full-table fetch here costs nothing meaningful at
  /// today's scale, and keeps the query itself simple/unambiguous.
  Future<List<CustomerProfile>> listWithUpcomingDates() async {
    _log.fine('listWithUpcomingDates()');
    final response = await supabase.from('customer_profiles').select();

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .where((profile) => profile.birthday != null || profile.anniversary != null)
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create-or-merge for one conversation's profile. Deliberately NOT a
  /// full create-or-REPLACE like OwnerNotificationSettingsRepository.
  /// upsert: a bot captures birthday/anniversary incrementally across
  /// separate conversation turns (separate Errand invocations), each
  /// only knowing about the ONE field it just asked the customer for —
  /// a plain replace would silently null out whichever field wasn't
  /// mentioned this time. [birthday]/[anniversary] passed as null here
  /// mean "don't touch this field," not "clear it" — there is
  /// deliberately no way to clear a previously-set date through this
  /// method; that's a real limitation, not an oversight, flagged rather
  /// than solved with a guess at what "clear my birthday" should look
  /// like from a bot conversation.
  Future<CustomerProfile> upsertPartial({
    required int workspaceId,
    required int conversationId,
    DateTime? birthday,
    DateTime? anniversary,
  }) async {
    final existing = await findByConversationScoped(conversationId, workspaceId);
    final now = DateTime.now().toUtc();

    final merged = CustomerProfile(
      id: existing?.id,
      workspaceId: workspaceId,
      conversationId: conversationId,
      birthday: birthday ?? existing?.birthday,
      anniversary: anniversary ?? existing?.anniversary,
      lastBirthdayGreetingYear: existing?.lastBirthdayGreetingYear,
      lastAnniversaryGreetingYear: existing?.lastAnniversaryGreetingYear,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _log.info('Upserting customer profile workspaceId=$workspaceId conversationId=$conversationId');
    final row = _dto.toRow(merged, includeId: false);
    row['created_at'] = merged.createdAt.toIso8601String();
    final response = await supabase
        .from('customer_profiles')
        .upsert(row, onConflict: 'conversation_id')
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Records that a greeting for [year] was just sent, so
  /// CustomerCampaignSweepService's dedupe (see the model's own header)
  /// never double-sends for the same calendar year.
  Future<void> markGreetingSent(int profileId, {required bool isBirthday, required int year}) async {
    _log.info('markGreetingSent(profileId=$profileId, isBirthday=$isBirthday, year=$year)');
    await supabase
        .from('customer_profiles')
        .update({
          if (isBirthday) 'last_birthday_greeting_year': year,
          if (!isBirthday) 'last_anniversary_greeting_year': year,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', profileId);
  }
}
