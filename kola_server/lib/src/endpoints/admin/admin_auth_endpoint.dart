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
  /// [totpCode] is only needed for an account with MFA enrolled — first
  /// call with it omitted; if the account requires MFA, this throws
  /// [KolaException] with code 'admin_mfa_required' rather than
  /// 'admin_login_failed', and kola_admin's login page prompts for a
  /// code and calls this again with the same email/password plus
  /// [totpCode] filled in. See AdminAuthService.login's header for the
  /// full two-step reasoning.
  ///
  /// Throws [KolaException] with code 'admin_login_failed' on any other
  /// failure — deliberately one generic message regardless of whether
  /// the email doesn't exist, the password is wrong, the account is
  /// deactivated, or (once past the MFA gate) the code was wrong.
  Future<String> login(
    Session session,
    String email,
    String password, {
    String? totpCode,
  }) async {
    try {
      return await _auth.login(email: email, password: password, totpCode: totpCode);
    } on AdminMfaRequiredException {
      throw KolaException(
        code: 'admin_mfa_required',
        message: 'Enter the 6-digit code from your authenticator app.',
      );
    } on AdminAuthException catch (e) {
      throw KolaException(code: 'admin_login_failed', message: e.message);
    }
  }

  /// Step 1 of MFA enrollment — generates a fresh TOTP secret and its
  /// otpauth:// URI, returned as "secretBase32|otpauthUri" (see this
  /// project's "avoid a new wire type when a formatted String is
  /// enough" precedent). Nothing is persisted by this call; see
  /// [confirmMfaEnrollment].
  Future<String> beginMfaEnrollment(Session session, String adminToken) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    final result = _auth.beginMfaEnrollment(email: admin.email);
    return '${result.secretBase32}|${result.otpauthUri}';
  }

  /// Step 2 — proves the admin's authenticator app actually produced a
  /// valid code for [secretBase32] before it becomes the account's real
  /// MFA secret. Throws [KolaException] with code 'admin_mfa_confirm_failed'
  /// if the code doesn't match.
  Future<void> confirmMfaEnrollment(
    Session session,
    String adminToken,
    String secretBase32,
    String code,
  ) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    try {
      await _auth.confirmMfaEnrollment(
        adminUserId: admin.adminUserId,
        secretBase32: secretBase32,
        code: code,
      );
    } on AdminAuthException catch (e) {
      throw KolaException(code: 'admin_mfa_confirm_failed', message: e.message);
    }

    await _auditLog.record(
      AdminAuditLogEntry(
        actorEmail: admin.email,
        actorLevel: admin.level,
        action: 'admin.mfa_enrolled',
        note: 'MFA enrollment completed via authenticator app.',
      ),
    );
  }

  /// Disables MFA on the caller's own account — requires the current
  /// password, same posture as [changePassword]. Throws [KolaException]
  /// with code 'admin_mfa_disable_failed' on a wrong password.
  Future<void> disableMfa(
    Session session,
    String adminToken,
    String currentPassword,
  ) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    try {
      await _auth.disableMfa(adminUserId: admin.adminUserId, currentPassword: currentPassword);
    } on AdminAuthException catch (e) {
      throw KolaException(code: 'admin_mfa_disable_failed', message: e.message);
    }

    await _auditLog.record(
      AdminAuditLogEntry(
        actorEmail: admin.email,
        actorLevel: admin.level,
        action: 'admin.mfa_disabled',
        note: 'MFA disabled by the account holder.',
      ),
    );
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

  /// Whether the caller's account currently has MFA enrolled — read
  /// live, same staleness posture as [mustResetPassword]. kola_admin's
  /// security page uses this to show "enable" vs. "disable" MFA.
  Future<bool> mfaEnabled(Session session, String adminToken) async {
    final admin = await requireAdminLevel(adminToken: adminToken);
    return admin.mfaEnabled;
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
