// workspace_access.dart
//
// The single choke point every workspace-scoped endpoint method calls
// FIRST, before touching any repository. This is what "workspace-scoped
// row isolation enforced at the repository layer... from the very first
// query written" (DEVELOPMENT_PLAN.md Phase 1d) actually looks like in
// code: one function, one place, that every endpoint routes through,
// rather than each endpoint hand-rolling its own access check.
//
// USAGE (inside any endpoint method):
//
//   Future<Bot> updateBotName(Session session, String accessToken,
//       int workspaceId, int botId, String name) async {
//     await requireWorkspaceAccess(
//       accessToken: accessToken,
//       workspaceId: workspaceId,
//     );
//     // ...only now touch BotRepository...
//   }
//
// WHY accessToken IS A PLAIN PARAMETER, NOT A HEADER:
//   Serverpod Mini endpoint methods are plain Dart methods called through
//   the generated client — there's no implicit "Authorization header"
//   concept the way there is in a raw HTTP framework. The dashboard's
//   generated client call sites pass the current Supabase access token
//   explicitly (kept in the Jaspr app's in-memory session state). This is
//   slightly more verbose per call than a header-based approach, but it
//   makes every endpoint's auth requirement visible in its own signature —
//   there's no way to accidentally forget auth on a method whose signature
//   doesn't even have anywhere to put a token.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/session_verifier.dart';
import 'package:kola_server/src/services/repository/workspace_member_repository.dart';

/// Thrown when a verified, genuine user still doesn't have access to the
/// specific workspace (or lacks a required role) they're asking about.
/// Deliberately a different exception type from [InvalidSessionException]
/// — one means "who even are you", the other means "I know who you are,
/// but no."
class WorkspaceAccessDeniedException implements Exception {
  final String message;
  const WorkspaceAccessDeniedException(this.message);

  @override
  String toString() => 'WorkspaceAccessDeniedException: $message';
}

const _sessionVerifier = SessionVerifier();

/// Verifies [accessToken] and confirms the resulting user is a member of
/// [workspaceId]. If [allowedRoles] is provided, also confirms the
/// member's role is one of them (e.g. only 'owner' can change billing).
///
/// Returns the caller's [WorkspaceMember] row on success — endpoints that
/// need to know the caller's role can read it off the return value instead
/// of querying again.
///
/// Throws [InvalidSessionException] if the token itself doesn't check out,
/// or [WorkspaceAccessDeniedException] if the token is valid but this user
/// has no access to this workspace (or the wrong role).
Future<WorkspaceMember> requireWorkspaceAccess({
  required String accessToken,
  required int workspaceId,
  List<String>? allowedRoles,
}) async {
  final session = await _sessionVerifier.verify(accessToken);

  final memberRepo = getIt<WorkspaceMemberRepository>();
  final membership = await memberRepo.findByWorkspaceAndUser(
    workspaceId,
    session.userId,
  );

  if (membership == null) {
    throw WorkspaceAccessDeniedException(
      'User ${session.userId} is not a member of workspace $workspaceId',
    );
  }

  if (allowedRoles != null && !allowedRoles.contains(membership.role)) {
    throw WorkspaceAccessDeniedException(
      'Role ${membership.role} is not permitted (requires one of: '
      '${allowedRoles.join(", ")})',
    );
  }

  return membership;
}
