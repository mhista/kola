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

class AdminAuthEndpoint extends Endpoint {
  AdminAuthService get _auth => getIt<AdminAuthService>();

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
}
