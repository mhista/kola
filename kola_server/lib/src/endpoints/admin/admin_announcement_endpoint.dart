// admin_announcement_endpoint.dart — kola_admin, ADMIN_APP_SPEC.md §3.4
// "push notifications," build-order step 7, deferred until this pass.
//
// WHAT THIS COVERS: compose a subject/body, target an audience (all
// workspaces / one plan tier / a named list of workspace ids), preview
// the exact recipient list and count before sending, then send — fanned
// out per-workspace through the EXISTING OwnerNotificationDispatcher
// (the same mechanism escalation notices and trial-ending notices
// already use), so this adds zero new delivery code, just a new caller.
//
// DELIBERATE SCOPE CUTS, STATED HONESTLY:
//   - No "workspaces with a feature enabled" audience mode. The spec
//     lists it; this pass only builds all/plan/named-list. Adding it
//     later is a straightforward extra branch in [_resolveAudience]
//     once needed, not a redesign.
//   - No persisted PlatformAnnouncement record/draft/history. The spec
//     suggests one as a "new model required," but persisting it would
//     mean a new migration + a new generated model neither
//     serverpod-generate'd nor dart-analyze'd in this environment (no
//     Dart toolchain here — see this project's standing constraint).
//     Instead: every send writes a normal admin_audit_log row (subject,
//     recipient count, audience description, note) — a real, permanent
//     record of what went out and to how many, just not a queryable
//     "announcements" table of its own yet.
//   - No dollar cost estimate. No per-channel message pricing is tracked
//     anywhere in this codebase (WhatsApp/Telegram/email costs vary by
//     provider and aren't metered here) — showing a fabricated "$X"
//     would be a fabricated number. [previewAudience] instead returns
//     the real, concrete thing this platform DOES know: exactly how
//     many workspaces (and which ones) would receive this.
//
// AUTHORISATION: broadcasting to every customer-facing owner on the
// platform is a big lever — Operator level, consistent with every other
// platform-wide mutating action in this codebase (workspace suspend,
// plan change).

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/admin/admin_user.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/notifications/owner_notification_dispatcher.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';

class AdminAnnouncementEndpoint extends Endpoint {
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  OwnerNotificationDispatcher get _dispatcher => getIt<OwnerNotificationDispatcher>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  Future<List<Workspace>> _resolveAudience(String audience, String audienceValue) async {
    switch (audience) {
      case 'all':
        return _workspaces.listAllUncapped();
      case 'plan':
        return _workspaces.listByPlan(audienceValue);
      case 'named':
        final ids = audienceValue
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toSet();
        final out = <Workspace>[];
        for (final id in ids) {
          final w = await _workspaces.findById(id);
          if (w != null) out.add(w);
        }
        return out;
      default:
        throw KolaException(message: 'Unknown audience "$audience" — use all, plan, or named.');
    }
  }

  /// Resolves the audience and returns "id|name|plan" lines — the
  /// preview step the spec asks for, shown before send is enabled in the
  /// UI. Support level: read-only, no message goes out.
  Future<List<String>> previewAudience(
    Session session,
    String adminToken,
    String audience,
    String audienceValue,
  ) async {
    await requireAdminLevel(adminToken: adminToken);
    final workspaces = await _resolveAudience(audience, audienceValue);
    return workspaces.map((w) => '${w.id}|${w.name}|${w.plan}').toList();
  }

  /// Sends [subject]/[body] to every workspace in the resolved audience
  /// via OwnerNotificationDispatcher.notify — same fan-out, same
  /// per-channel rate limiting, as any other owner notification. Returns
  /// "sentCount|totalCount". Operator level (see file header).
  Future<String> sendAnnouncement(
    Session session,
    String adminToken,
    String audience,
    String audienceValue,
    String subject,
    String body,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to send a platform announcement.');
    }
    if (subject.trim().isEmpty || body.trim().isEmpty) {
      throw KolaException(message: 'Subject and body are both required.');
    }
    final admin = await requireAdminLevel(
      adminToken: adminToken,
      minimumLevel: AdminLevel.operator_,
    );

    final workspaces = await _resolveAudience(audience, audienceValue);
    var sent = 0;
    for (final w in workspaces) {
      final result = await _dispatcher.notify(workspaceId: w.id!, subject: subject, body: body);
      if (result.anySent) sent++;
    }

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'announcement.send',
      afterValue: 'audience=$audience($audienceValue) recipients=${workspaces.length} sent=$sent subject="$subject"',
      note: note,
    ));

    return '$sent|${workspaces.length}';
  }
}
