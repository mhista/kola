// workspace_repository.dart
//
// All database read/write operations for Workspace records — the tenant
// root every other domain model hangs off of (SRS.md §5/§6).
//
// PATTERN:
//   Every method speaks only in Serverpod model types (Workspace).
//   Supabase JSON is handled entirely inside this file via WorkspaceDto.
//   Callers (endpoints, services) never see raw Maps.
//
// MULTI-TENANCY NOTE:
//   Workspace itself has no parent to scope by — it IS the isolation
//   boundary. Every OTHER repository in this project (bot, channel,
//   workspace_member, and everything added in later phases) must filter
//   by workspaceId on every query. This repository is where that
//   boundary starts.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/workspace_dto.dart';
import 'supabase_client.dart';

final _log = Logger('WorkspaceRepository');

const _dto = WorkspaceDto();

class WorkspaceRepository {
  const WorkspaceRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Find a workspace by its Supabase integer PK.
  /// Returns null if no workspace exists with this id.
  Future<Workspace?> findById(int id) async {
    _log.fine('findById($id)');
    final response = await supabase
        .from('workspaces')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Get every workspace currently in the given [status] — used by the
  /// Phase 5 trial state machine to find workspaces whose trial window
  /// has just crossed the 48-hour or 14-day mark.
  Future<List<Workspace>> listByStatus(String status) async {
    _log.fine('listByStatus($status)');
    final response = await supabase
        .from('workspaces')
        .select()
        .eq('status', status);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every workspace on [plan] — added for §3.4 push notifications'
  /// "audience: one plan tier" targeting (deferred until this pass).
  /// Uncapped by design: an announcement audience needs the true count,
  /// not a 50-row preview.
  Future<List<Workspace>> listByPlan(String plan) async {
    _log.fine('listByPlan($plan)');
    final response = await supabase.from('workspaces').select().eq('plan', plan);
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every workspace, uncapped — §3.4's "audience: all" targeting.
  /// Deliberately separate from [search] (which caps at 50 for the
  /// workspace list UI) rather than overloading that method's contract.
  Future<List<Workspace>> listAllUncapped() async {
    _log.fine('listAllUncapped()');
    final response = await supabase.from('workspaces').select();
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// ADMIN_APP_SPEC.md §3.2 — "search by name, ID, owner email, or
  /// connected phone number." This implements the FIRST TWO only (name
  /// substring, exact numeric id) — owner email lives in Supabase Auth's
  /// `auth.users` table (not exposed over PostgREST the way `workspaces`
  /// is) and connected phone number lives inside each channel's
  /// encrypted credential, neither of which this pass wires up. Stated
  /// honestly as a real, narrow gap rather than silently only covering
  /// name/id and calling it "search." See kola_admin's workspace page
  /// for where this shows up as a UI-level caveat too.
  ///
  /// Empty/null [query] returns the most recently created workspaces —
  /// the useful default when an admin just wants to see what's new,
  /// capped at [limit] since this has no pagination yet.
  Future<List<Workspace>> search({String? query, int limit = 50}) async {
    _log.fine('search(query=$query, limit=$limit)');
    final trimmed = query?.trim() ?? '';

    if (trimmed.isEmpty) {
      final response = await supabase
          .from('workspaces')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((row) => _dto.fromRow(row as Map<String, dynamic>))
          .toList();
    }

    final asId = int.tryParse(trimmed);
    if (asId != null) {
      final response = await supabase
          .from('workspaces')
          .select()
          .eq('id', asId)
          .limit(limit);
      return (response as List)
          .map((row) => _dto.fromRow(row as Map<String, dynamic>))
          .toList();
    }

    final response = await supabase
        .from('workspaces')
        .select()
        .ilike('name', '%$trimmed%')
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Create a new workspace, computing its trial window from [now].
  ///
  /// This is the ONLY place trial dates get computed from scratch — every
  /// other read of trialFullAccessEndsAt/trialEndsAt is a plain column
  /// read, never re-derived, so the trial window can never silently drift
  /// if this method is called at a slightly different time than the
  /// workspace's actual createdAt.
  Future<Workspace> create({
    required String name,
    String? industryTag,
    String? ownerName,
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now().toUtc();
    _log.info('Creating workspace name=$name');

    final workspace = Workspace(
      name: name,
      industryTag: industryTag,
      ownerName: ownerName,
      plan: 'free',
      status: 'trialing',
      trialStartedAt: createdAt,
      trialFullAccessEndsAt: createdAt.add(const Duration(hours: 48)),
      trialEndsAt: createdAt.add(const Duration(days: 14)),
      // PHASE 10 — a workspace is NEVER created internal. Internal
      // status is granted from kola_admin only, deliberately: a
      // customer-reachable creation path that could mint an internal
      // workspace would unlock every unreleased feature on the platform.
      isInternal: false,
      // Launch market. Once region selection exists at signup this
      // becomes a parameter; defaulting here keeps every workspace
      // created today priced exactly as it is now.
      region: 'NG',
      // Migration 035's own default — a new workspace is never
      // VAT-registered by default; turning it on is a Settings decision
      // the owner makes knowingly.
      taxRateBps: 0,
      // Migrations 057/058 — both customer-facing surfaces default OFF.
      // Publishing a catalog or leaving a customer display running is a
      // decision an owner makes deliberately in Settings, never something
      // that happens to a workspace just by existing.
      publicCatalogEnabled: false,
      customerDisplayEnabled: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final row = _dto.toRow(workspace, includeId: false);
    row['created_at'] = createdAt.toIso8601String();

    final response = await supabase
        .from('workspaces')
        .insert(row)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Update mutable fields on an existing workspace. Matches on id.
  Future<Workspace> update(Workspace workspace) async {
    _log.info('Updating workspace id=${workspace.id}');
    final row = _dto.toRow(workspace, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('workspaces')
        .update(row)
        .eq('id', workspace.id!)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Transition a workspace's lifecycle status (see workspace.spy.yaml for
  /// the 'trialing' | 'active' | 'paused' values). Kept as a dedicated
  /// method rather than a generic update so every status change is easy
  /// to grep for and audit later — this is the single most consequential
  /// field on the model (it decides whether a bot responds to customers).
  Future<Workspace> setStatus(int workspaceId, String status) async {
    _log.info('setStatus workspaceId=$workspaceId status=$status');
    final response = await supabase
        .from('workspaces')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Task #148 — the one write KolaBillingWebhookHandler makes on a
  /// confirmed Kola subscription payment: flips both plan and status
  /// together, atomically, since "paid but still shown as trialing" (or
  /// the reverse) is exactly the kind of half-updated state a generic
  /// two-call update() would risk if the second call ever failed. Same
  /// "dedicated method for the most consequential fields" reasoning as
  /// [setStatus] above.
  Future<Workspace> setPlanAndStatus({
    required int workspaceId,
    required String plan,
    required String status,
  }) async {
    _log.info('setPlanAndStatus workspaceId=$workspaceId plan=$plan status=$status');
    final response = await supabase
        .from('workspaces')
        .update({
          'plan': plan,
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// kola_admin, ADMIN_APP_SPEC.md §3.2 — a pure plan change with no
  /// status side-effect, distinct from [setPlanAndStatus] (which is
  /// specifically KolaBillingWebhookHandler's atomic "payment confirmed"
  /// write). An admin manually comping/downgrading a plan should not
  /// silently also flip trialing->active or active->trialing — those are
  /// two different admin actions on purpose (this one, and
  /// [suspend]/[reinstate] below).
  Future<Workspace> setPlan(int workspaceId, String plan) async {
    _log.info('setPlan workspaceId=$workspaceId plan=$plan');
    final response = await supabase
        .from('workspaces')
        .update({
          'plan': plan,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// kola_admin, ADMIN_APP_SPEC.md §3.2 — pushes both trial cutover dates
  /// forward by [days] without touching `status`, so a workspace that's
  /// already `active` (paying) is unaffected — extending a trial only
  /// means something for a workspace still `trialing`, but this doesn't
  /// gate on that: an admin extending a paying workspace's trial dates is
  /// harmless (they're not read while `status == 'active'`) and refusing
  /// it here would just be a surprising extra rule to remember.
  Future<Workspace> extendTrial(int workspaceId, int days) async {
    _log.info('extendTrial workspaceId=$workspaceId days=$days');
    final current = await findById(workspaceId);
    if (current == null) {
      throw ArgumentError('No workspace with id $workspaceId');
    }
    final extension = Duration(days: days);
    final response = await supabase
        .from('workspaces')
        .update({
          'trial_full_access_ends_at':
              current.trialFullAccessEndsAt.add(extension).toIso8601String(),
          'trial_ends_at': current.trialEndsAt.add(extension).toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// kola_admin, ADMIN_APP_SPEC.md §3.2 — restarts the trial window from
  /// [now] and puts the workspace back into `trialing`, same computation
  /// [create] uses for a brand-new workspace. A genuinely different
  /// action from [extendTrial]: this is for a `paused` workspace an admin
  /// wants to give a fresh full trial window, not a small nudge to an
  /// already-running one.
  Future<Workspace> resetTrial(int workspaceId, {DateTime? now}) async {
    final startedAt = now ?? DateTime.now().toUtc();
    _log.info('resetTrial workspaceId=$workspaceId');
    final response = await supabase
        .from('workspaces')
        .update({
          'status': 'trialing',
          'trial_started_at': startedAt.toIso8601String(),
          'trial_full_access_ends_at':
              startedAt.add(const Duration(hours: 48)).toIso8601String(),
          'trial_ends_at': startedAt.add(const Duration(days: 14)).toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// PHASE 10 / kola_admin — the ONLY place `is_internal` is written from
  /// (see workspace.spy.yaml's field comment: no customer-reachable path
  /// exists to this column at all). Kept as its own dedicated method,
  /// same "consequential field gets its own named method" pattern as
  /// [setStatus], specifically so this one write is trivially greppable
  /// and never accidentally folded into a generic update() call site.
  Future<Workspace> setInternal(int workspaceId, bool isInternal) async {
    _log.info('setInternal workspaceId=$workspaceId isInternal=$isInternal');
    final response = await supabase
        .from('workspaces')
        .update({
          'is_internal': isInternal,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', workspaceId)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
