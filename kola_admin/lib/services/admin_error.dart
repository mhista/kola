// admin_error.dart — shared error-handling helpers for kola_admin pages.
//
// WHY THIS EXISTS: release_control_page.dart established a real pattern
// (a private _isSessionError/_describe pair) for turning a raw
// KolaException string into something an admin can act on, and for
// telling a stale-token error apart from every other kind of failure.
// The six pages added in the "build everything admin related" pass each
// reimplemented their own bare `'Something went wrong: $e'` instead of
// reusing it — this file is the fix: one shared implementation, used by
// every page, so a session expiring mid-use behaves the same way
// everywhere (a clear message, then an automatic sign-out) instead of
// differently depending on which page happened to be open.

/// True if [e]'s message indicates the admin token itself is no longer
/// valid (expired, forged, or the account was deactivated/reset since
/// the token was issued) — see AdminAuthService.verify's header.
bool isAdminSessionError(Object e) => e.toString().contains('admin_session_invalid');

/// True if [e]'s message indicates the token is valid but the account's
/// level doesn't permit the attempted action.
bool isAdminAccessDenied(Object e) => e.toString().contains('admin_access_denied');

/// A human-readable message for any error surfaced by an admin RPC call.
/// Callers that want to react to a session error specifically (redirect
/// to login) should check [isAdminSessionError] separately — this
/// function only produces the text to show.
String describeAdminError(Object e) {
  if (isAdminSessionError(e)) return 'Your session has expired. Please sign in again.';
  if (isAdminAccessDenied(e)) return "Your admin level doesn't permit this action.";
  return 'Something went wrong: $e';
}
