// require_admin_level.dart — kola_admin, step 1.
//
// The admin-side twin of workspace_access.dart's requireWorkspaceAccess
// — DELIBERATELY A SEPARATE FUNCTION, not an extension or overload of
// it, per ADMIN_APP_SPEC.md §2: "the two authorisation models must not
// be able to be confused for one another at a call site." Every method
// on every endpoint under lib/src/endpoints/admin/ calls this first,
// the same way every workspace-scoped endpoint calls
// requireWorkspaceAccess first.
//
// SERVER-SIDE ENFORCEMENT, NOT A UI CONVENIENCE: kola_admin's Jaspr app
// is compiled JavaScript in a browser and is fully untrusted — hiding a
// button for a Support-level admin does not stop a Support-level admin
// from calling the underlying RPC method directly. This function is the
// actual control.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';

import 'admin_auth_service.dart';
import 'admin_user.dart';

/// Verifies [adminToken] and confirms the resulting admin's level is at
/// least [minimumLevel] (default: any authenticated admin). Returns the
/// verified [AdminSession] — callers that need the actor's email/level
/// for an audit log entry read it off the return value instead of
/// re-verifying.
///
/// Throws [KolaException] with code 'admin_session_invalid' if the
/// token itself doesn't check out, or 'admin_access_denied' if the
/// token is valid but the account's level is below [minimumLevel].
Future<AdminSession> requireAdminLevel({
  required String adminToken,
  String minimumLevel = AdminLevel.support,
}) async {
  final auth = getIt<AdminAuthService>();

  final AdminSession session;
  try {
    session = await auth.verify(adminToken);
  } on AdminAuthException catch (e) {
    throw KolaException(code: 'admin_session_invalid', message: e.message);
  }

  if (!AdminLevel.atLeast(session.level, minimumLevel)) {
    throw KolaException(
      code: 'admin_access_denied',
      message:
          'This action requires $minimumLevel level or higher (you are ${session.level}).',
    );
  }

  return session;
}
