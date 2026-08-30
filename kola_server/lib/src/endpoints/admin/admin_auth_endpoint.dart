// admin_auth_endpoint.dart — kola_admin, step 1.
//
// Login only. DELIBERATELY no signup/register method — see
// ADMIN_APP_SPEC.md §2: "No self-registration, ever. An admin account
// is created by an existing admin." That is satisfied here by NOT
// exposing account creation over RPC at all in this pass:
// AdminUserRepository.create exists and is real, but nothing calls it
// from a public endpoint. The very first admin account has to be
// created directly against the database (or via a one-off script run
// by someone with production DB access) — a deliberate, narrow gap
// consistent with "no path by which registering as a customer can
// result in admin access" being the load-bearing guarantee, not a
// convenience feature to build around it. A real "admin invites admin"
// endpoint is real future work, gated behind Owner level, not something
// this pass should improvise without deciding its own abuse-prevention
// shape first.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/admin/admin_auth_service.dart';
import 'package:kola_server/src/services/admin/admin_audit_log.dart';
import 'package:kola_server/src/services/repository/admin_audit_log_repository.dart';
import 'package:kola_server/src/services/admin/require_admin_level.dart';

class AdminAuthEndpoint extends Endpoint {
  AdminAuthService get _auth => getIt<AdminAuthService>();
  AdminAuditLogRepository get _auditLog => getIt<AdminAuditLogRepository>();

  /// Verifies [email]/[password] and returns a signed admin session
  /// token (4-hour lifetime — see AdminAuthService's header) for use as
  /// the `adminToken` parameter on every other admin endpoint method.
  ///
  /// Throws [KolaException] with code 'admin_login_failed' on any
  /// failure — deliberately one generic message regardless of whether
  /// the email doesn't exist, the password is wrong, or the account is
  /// deactivated. See AdminAuthService.login's header on why.
  Future<String> login(
    Session session,
    String email,
    String password,
  ) async {
    try {
      return await _auth.login(email: email, password: password);
    } on AdminAuthException catch (e) {
      throw KolaException(code: 'admin_login_failed', message: e.message);
    }
  }

  /// Whether the caller must change their password before doing anything
  /// else — kola_admin calls this immediately after login and, if true,
  /// blocks every other route behind the forced reset screen. Backed by
  /// AdminSession.mustResetPassword, which is read live off the account
  /// row on every call — see admin_auth_service.dart's verify().
  Future<bool> mustResetPassword(Session session, String adminToken) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    return admin.mustResetPassword;
  }

  /// Changes the caller's own password. Requires the CURRENT password —
  /// see AdminAuthService.changePassword's header for why that holds
  /// even during a forced first-login reset. This is the only method
  /// that ever clears must_reset_password.
  ///
  /// Throws [KolaException] with code 'admin_password_change_failed' on
  /// any validation failure (wrong current password, new password too
  /// short, new password same as current, or an inactive account).
  Future<void> changePassword(
    Session session,
    String adminToken,
    String currentPassword,
    String newPassword,
  ) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    try {
      await _auth.changePassword(
        adminUserId: admin.adminUserId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AdminAuthException catch (e) {
      throw KolaException(
        code: 'admin_password_change_failed',
        message: e.message,
      );
    }

    // Audit AFTER success, not before — an audit entry for a change that
    // failed validation would be noise, not signal. Same "record on
    // success only" posture as AdminFeatureEndpoint's mutating methods.
    await _auditLog.record(
      AdminAuditLogEntry(
        actorEmail: admin.email,
        actorLevel: admin.level,
        action: 'admin.password_reset',
        note: 'Self-service password change (forced-reset or voluntary).',
      ),
    );
  }
}
