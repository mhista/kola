// admin_auth_service.dart — kola_admin, step 1 of ADMIN_APP_SPEC.md's
// build order ("nothing else can be built safely first").
//
// WHY THIS SERVER ISSUES ITS OWN TOKENS HERE, UNLIKE EVERYWHERE ELSE:
// every customer-facing session in this codebase is verified, never
// issued — session_verifier.dart's whole header explains why Kola
// deliberately never reimplements Supabase Auth. Admin identity is
// different on purpose (ADMIN_APP_SPEC.md §2: "a separate Supabase Auth
// project, or at minimum a separate user table... there must be no path
// by which registering as a customer can result in admin access"). A
// second full Supabase Auth *project* is a real infrastructure decision
// this pass cannot make unilaterally (a new project, a new set of
// credentials, a new bill) — so this pass takes the spec's own stated
// minimum instead: a separate table (admin_users, migration 054) with
// this server issuing and verifying its OWN short-lived JWTs, signed
// with a secret (ADMIN_JWT_SECRET) that is NEVER the same key as
// SUPABASE_JWT_SECRET. That is a real, correct security boundary — a
// forged customer token cannot become an admin token, because they are
// different keys entirely — even though it is not literally "a second
// Supabase project." Upgrading to one later is additive, not a rewrite:
// only this file's login() method would change.
//
// SESSION LIFETIME: 4 hours, matching the spec's "hours, not weeks."
//
// MFA: ADMIN_APP_SPEC.md §2 says "MFA required. Not optional, not
// encouraged." STATED HONESTLY, NOT SILENTLY SKIPPED: no MFA/TOTP
// verification exists in this pass. AdminUser.mfaEnabled is a real
// column so a later pass can wire real TOTP without a second migration,
// but login() below does not check it. This is a genuine, named gap —
// treat any production use of this admin app before that gap closes as
// running with a lowered security bar than the spec calls for.

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
import 'package:kola_server/src/services/repository/admin_user_repository.dart';

import 'admin_password_hasher.dart';
import 'admin_user.dart';

/// The identity + level claims a verified admin token carries — the
/// admin-side twin of session_verifier.dart's VerifiedSession.
class AdminSession {
  const AdminSession({
    required this.adminUserId,
    required this.email,
    required this.level,
    required this.mustResetPassword,
  });

  final int adminUserId;
  final String email;
  final String level;

  /// Migration 055 — true until this admin has changed their own
  /// password at least once via [AdminAuthService.changePassword].
  /// kola_admin checks this right after login and, if true, blocks
  /// every other route behind a forced reset screen — see
  /// AdminAuthEndpoint.mustResetPassword and app.dart's redirect guard.
  final bool mustResetPassword;
}

/// Thrown on any admin auth failure — bad credentials, inactive
/// account, expired/invalid token. Deliberately one exception type with
/// a generic message for login failures specifically (see [login]):
/// distinguishing "wrong email" from "wrong password" in the response
/// is a user-enumeration leak this app has no reason to accept.
class AdminAuthException implements Exception {
  const AdminAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminAuthService {
  AdminAuthService({required AdminUserRepository users}) : _users = users;

  final AdminUserRepository _users;

  static const _sessionLifetime = Duration(hours: 4);

  /// Verifies [email]/[password] and returns a signed session token.
  /// Same "generic failure message" posture Supabase Auth itself uses —
  /// bad email and bad password both fail identically here.
  Future<String> login({required String email, required String password}) async {
    final user = await _users.findByEmail(email);
    if (user == null || !user.active) {
      // Constant-effort even on a miss: hash against a dummy value so a
      // timing difference between "no such account" and "wrong
      // password" isn't observable. The dummy hash is a fixed,
      // non-secret PBKDF2 output — its only job is to make this branch
      // cost roughly the same as the real one below.
      await AdminPasswordHasher.verify(
        password,
        '210000:AAAAAAAAAAAAAAAAAAAAAA==:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      );
      throw const AdminAuthException('Invalid email or password.');
    }

    if (!await AdminPasswordHasher.verify(password, user.passwordHash)) {
      throw const AdminAuthException('Invalid email or password.');
    }

    if (Env.adminJwtSecret.isEmpty) {
      Log.error('AdminAuthService.login: ADMIN_JWT_SECRET is not set.');
      throw const AdminAuthException(
        'Admin sign-in is not configured on this server yet.',
      );
    }

    unawaited(_users.touchLastSeen(user.id));

    final jwt = JWT({
      'sub': user.id.toString(),
      'email': user.email,
      'level': user.level,
    });

    return jwt.sign(
      SecretKey(Env.adminJwtSecret),
      expiresIn: _sessionLifetime,
    );
  }

  /// Verifies an admin session token. Throws [AdminAuthException] if
  /// invalid, expired, or the account has since been deactivated —
  /// deactivation is checked on every call, not just at login, so
  /// revoking an admin's access takes effect immediately rather than
  /// waiting out their existing token's 4-hour lifetime.
  Future<AdminSession> verify(String token) async {
    if (token.isEmpty) {
      throw const AdminAuthException('No admin session token provided.');
    }
    if (Env.adminJwtSecret.isEmpty) {
      throw const AdminAuthException(
        'Admin sign-in is not configured on this server yet.',
      );
    }

    try {
      final jwt = JWT.verify(token, SecretKey(Env.adminJwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      final userId = int.tryParse(payload['sub'] as String? ?? '');
      final email = payload['email'] as String?;
      final level = payload['level'] as String?;

      if (userId == null || email == null || level == null) {
        throw const AdminAuthException('Malformed admin session token.');
      }

      // Re-check the live account, not just the token's claims — a
      // token signed an hour ago for an admin who was just deactivated
      // must stop working now, not at its original 4-hour expiry.
      final user = await _users.findById(userId);
      if (user == null || !user.active) {
        throw const AdminAuthException('This admin account is no longer active.');
      }
      if (user.level != level) {
        // The account's level changed since this token was issued —
        // fail rather than trust a stale claim; re-login picks up the
        // new level.
        throw const AdminAuthException('Admin session is stale — sign in again.');
      }

      return AdminSession(
        adminUserId: userId,
        email: email,
        level: level,
        // Read live off the account row, same as `active` and `level`
        // above — never trusted from the token, since a reset that
        // happens mid-session (or a brand-new token minted before a
        // reset) must be reflected on the very next call, not after a
        // re-login.
        mustResetPassword: user.mustResetPassword,
      );
    } on JWTExpiredException {
      throw const AdminAuthException('Admin session expired — sign in again.');
    } on JWTException catch (e) {
      throw AdminAuthException('Invalid admin session: ${e.message}');
    }
  }

  /// Changes the caller's own password. The only path that ever clears
  /// [AdminUser.mustResetPassword] — see AdminUserRepository.updatePassword.
  ///
  /// Requires the CURRENT password, even during a forced first-login
  /// reset: the temporary password was handed to this admin by whoever
  /// created the account (or, for the very first accounts, generated
  /// and shared once), so proving it is still "something you have," not
  /// an extra hoop — and it keeps this endpoint from being a second,
  /// weaker way to take over an account that doesn't require knowing
  /// the current credential at all.
  Future<void> changePassword({
    required int adminUserId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _users.findById(adminUserId);
    if (user == null || !user.active) {
      throw const AdminAuthException('This admin account is no longer active.');
    }
    if (!await AdminPasswordHasher.verify(currentPassword, user.passwordHash)) {
      throw const AdminAuthException('Current password is incorrect.');
    }
    if (newPassword.length < 12) {
      throw const AdminAuthException('New password must be at least 12 characters.');
    }
    if (newPassword == currentPassword) {
      throw const AdminAuthException('New password must be different from the current one.');
    }

    final newHash = await AdminPasswordHasher.hash(newPassword);
    await _users.updatePassword(user.id, newHash);
  }
}

// Small local helper so login()'s deliberate dummy-hash call above
// doesn't need to await it inline and slow the real error path further
// than the timing-safety goal requires.
void unawaited(Future<void> future) {}
