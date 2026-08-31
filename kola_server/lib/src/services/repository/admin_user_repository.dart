// admin_user_repository.dart — kola_admin, step 1.
//
// Database access for admin_users. DELIBERATELY separate from every
// workspace-scoped repository in this project (SRS.md §5's isolation
// rule does not apply here — see admin_user.dart's header on why admin
// identity has no relationship to workspace_members at all) and from
// FeatureFlagRepository's "platform state, writes only from kola_admin"
// posture — this one IS the identity kola_admin authenticates against,
// so it is read from the login path and written to only when an admin
// creates another admin account.

import 'package:logging/logging.dart';
import '../admin/admin_user.dart';
import 'supabase_client.dart';

final _log = Logger('AdminUserRepository');

class AdminUserRepository {
  const AdminUserRepository();

  Future<AdminUser?> findByEmail(String email) async {
    final response = await supabase
        .from('admin_users')
        .select()
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();

    if (response == null) return null;
    return AdminUser.fromRow(response);
  }

  Future<AdminUser?> findById(int id) async {
    final response =
        await supabase.from('admin_users').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return AdminUser.fromRow(response);
  }

  /// Creates a new admin account. Called only from server-side tooling
  /// or by an existing admin — there is no customer-reachable path to
  /// this method, and no public endpoint exposes it directly (see
  /// admin_auth_endpoint.dart's header: account creation is deliberately
  /// NOT wired to any RPC method in this pass — see that file for the
  /// honest reason why).
  Future<AdminUser> create({
    required String email,
    required String passwordHash,
    required String level,
  }) async {
    _log.warning('Creating admin account: $email ($level)');
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await supabase
        .from('admin_users')
        .insert({
          'email': email.trim().toLowerCase(),
          'password_hash': passwordHash,
          'level': level,
          'mfa_enabled': false,
          'active': true,
          // Migration 055 — every new account starts forced into a
          // reset on first login, no exceptions. Whoever creates this
          // account hands the recipient a placeholder; this column is
          // what turns "hand someone a password" into "hand someone a
          // one-time credential."
          'must_reset_password': true,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return AdminUser.fromRow(response);
  }

  /// Read path added for step "Admin accounts as its own page" (deferred
  /// until this pass). Deliberately still no CREATE via RPC (see
  /// [create]'s header — account creation stays a direct-DB/tooling-only
  /// path); this only lets an Owner see who has access today and
  /// deactivate an account, which is the realistic day-2 need ("someone
  /// left the team, cut their access now") without reopening the
  /// no-self-registration decision.
  Future<List<AdminUser>> listAll() async {
    final response = await supabase
        .from('admin_users')
        .select()
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => AdminUser.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Flips [AdminUser.active]. The only lever this pass adds for revoking
  /// a departed admin's access short of a direct DB edit — deliberately
  /// narrower than full account management (no level change, no email
  /// change) to keep this addition small and auditable.
  Future<AdminUser> setActive(int id, bool active) async {
    final response = await supabase
        .from('admin_users')
        .update({
          'active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return AdminUser.fromRow(response);
  }

  /// The ONLY writer of either `mfa_secret` or `mfa_enabled` — always
  /// sets both together so the two columns can never drift out of sync
  /// (mfa_enabled = true with a null secret, or vice versa, would be a
  /// broken state nothing else in this codebase checks for). Pass an
  /// encrypted secret to enroll, or null to disable MFA entirely.
  Future<AdminUser> setMfaSecret(int id, String? encryptedSecret) async {
    final response = await supabase
        .from('admin_users')
        .update({
          'mfa_secret': encryptedSecret,
          'mfa_enabled': encryptedSecret != null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return AdminUser.fromRow(response);
  }

  Future<void> touchLastSeen(int id) async {
    await supabase.from('admin_users').update({
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Sets a new password hash and clears [AdminUser.mustResetPassword]
  /// in the same write — the only place either column changes after
  /// account creation. Called only from AdminAuthService.changePassword,
  /// which has already verified the caller's current password.
  Future<void> updatePassword(int id, String newPasswordHash) async {
    await supabase.from('admin_users').update({
      'password_hash': newPasswordHash,
      'must_reset_password': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
