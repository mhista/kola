// admin_accounts_endpoint.dart — kola_admin, "Admin accounts" as its
// own page (deferred nav item, built this pass).
//
// READ-ONLY LIST + ACTIVATE/DEACTIVATE ONLY — deliberately not full CRUD.
// admin_auth_endpoint.dart's own header already states there is no
// account-creation RPC path by design (see AdminUserRepository.create's
// header); this pass doesn't reopen that decision. What it DOES add is
// the realistic day-2 need: "someone left, cut their access" — a single
// boolean flip on [AdminUser.active], which AdminAuthService.verify
// already reads live on every call (same staleness posture as `level`).
//
// OWNER-ONLY: the spec's authorization table (§2) says Operator "cannot
// manage admin accounts" — this endpoint reads that as Owner-only even
// for viewing, the conservative reading, consistent with this project's
// existing precedent of holding "who else has the keys" to the same bar
// as setInternal/flip-to-released (AdminWorkspaceEndpoint.setInternal's
// header explains that reasoning in full).
//
// SELF-LOCKOUT PROTECTION (added in a robustness pass): [setActive]
// refuses to deactivate the caller's own account, and refuses to
// deactivate the last remaining active Owner. Neither check existed in
// the initial build — both are real ways to lock every admin out with
// no recovery path short of a direct database edit.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/admin/admin_user.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/repository/admin_user_repository.dart';

class AdminAccountsEndpoint extends Endpoint {
  AdminUserRepository get _users => getIt<AdminUserRepository>();
  AdminAuditLogRepository get _audit => getIt<AdminAuditLogRepository>();

  /// "id|email|level|active|mustResetPassword|lastSeenAt" lines — see file
  /// header on why this is a formatted list rather than a new wire type;
  /// AdminUser itself is a plain internal class here too (not generated
  /// for RPC, same posture as AdminAuditLogEntry).
  Future<List<String>> listAdmins(Session session, String adminToken) async {
    await requireAdminLevel(adminToken: adminToken, minimumLevel: AdminLevel.owner);
    final admins = await _users.listAll();
    return admins
        .map((a) =>
            '${a.id}|${a.email}|${a.level}|${a.active}|${a.mustResetPassword}|${a.lastSeenAt?.toIso8601String() ?? "-"}')
        .toList();
  }

  Future<String> setActive(
    Session session,
    String adminToken,
    int accountId,
    bool active,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw KolaException(message: 'A reason is required to change an admin account\'s access.');
    }
    final admin = await requireAdminLevel(adminToken: adminToken, minimumLevel: AdminLevel.owner);

    final target = await _users.findById(accountId);
    if (target == null) {
      throw KolaException(message: 'No admin account with id $accountId.');
    }

    // SELF-LOCKOUT PROTECTION — added as a robustness pass after the
    // initial build. Neither check existed originally, and either gap
    // is a real way to lock every admin out with no recovery path
    // short of a direct database edit (the same class of problem the
    // password-hashing incident earlier in this project caused, just
    // self-inflicted instead of a CPU-budget accident).
    if (!active) {
      if (target.email == admin.email) {
        throw KolaException(
          message: "You can't deactivate your own account. Ask another Owner to do it.",
        );
      }
      if (target.level == AdminLevel.owner) {
        final allAdmins = await _users.listAll();
        final otherActiveOwners = allAdmins.where(
          (a) => a.id != accountId && a.level == AdminLevel.owner && a.active,
        );
        if (otherActiveOwners.isEmpty) {
          throw KolaException(
            message: 'This is the last active Owner account — deactivating it would '
                'lock everyone out. Promote or activate another Owner first.',
          );
        }
      }
    }

    final updated = await _users.setActive(accountId, active);

    await _audit.record(AdminAuditLogEntry(
      actorEmail: admin.email,
      actorLevel: admin.level,
      action: 'admin_account.set_active',
      beforeValue: '${target.email}: active=${target.active}',
      afterValue: '${target.email}: active=$active',
      note: note,
    ));

    return updated.active.toString();
  }
}
