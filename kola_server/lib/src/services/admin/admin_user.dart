// admin_user.dart — kola_admin, step 1.
//
// Deliberately a PLAIN Dart class, not a Serverpod-generated model
// (contrast with FeatureFlag/WorkspaceFeatureOverride, which ARE
// generated models). Nothing in this pass ever sends an AdminUser row
// across the wire to kola_admin — login returns a signed token string,
// not this object — so there is no reason to hand-write the generated-
// model boilerplate (toJson/copyWith/Protocol registration) for
// something with no RPC use yet. Same precedent as VerifiedSession in
// session_verifier.dart: an internal-only shape stays a plain class
// until something actually needs to serialize it.
//
// If a later pass builds an admin-user-management UI (ADMIN_APP_SPEC.md
// never actually specifies one explicitly — accounts are created "by an
// existing admin", which this pass reads as a direct-database action
// for the first account and a server-side-only method for subsequent
// ones, not a dashboard form), THAT is when this earns real Serverpod-
// model treatment.

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.level,
    required this.mfaEnabled,
    this.mfaSecret,
    required this.active,
    required this.mustResetPassword,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String email;
  final String passwordHash;

  /// 'support' | 'operator' | 'owner' — see ADMIN_APP_SPEC.md §2.
  final String level;

  /// Migration 056: true once this admin has completed TOTP enrollment
  /// (see AdminAuthService.confirmMfaEnrollment) — real verification now
  /// exists, no longer the honest-gap placeholder this column started
  /// as. Always kept in sync with [mfaSecret] being non-null by
  /// AdminUserRepository.setMfaSecret, the only writer of either.
  final bool mfaEnabled;

  /// AES-256-GCM-encrypted TOTP secret (AdminMfaSecretEncryptionService)
  /// — null until enrollment completes. Never decrypted anywhere except
  /// inside AdminAuthService's login()/confirmMfaEnrollment() calls,
  /// immediately before verifying a code; never sent to kola_admin.
  final String? mfaSecret;

  final bool active;

  /// Migration 055. True for every account until it changes its own
  /// password via AdminAuthEndpoint.changePassword — set true on
  /// creation (see AdminUserRepository.create's default) and never
  /// silently cleared by anything else. AdminAuthService.verify()
  /// surfaces this on every session so kola_admin can gate the whole
  /// app behind a forced reset screen until it's cleared.
  final bool mustResetPassword;

  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AdminUser.fromRow(Map<String, dynamic> row) => AdminUser(
        id: row['id'] as int,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String,
        level: row['level'] as String,
        mfaEnabled: row['mfa_enabled'] as bool? ?? false,
        mfaSecret: row['mfa_secret'] as String?,
        active: row['active'] as bool? ?? true,
        mustResetPassword: row['must_reset_password'] as bool? ?? true,
        lastSeenAt: row['last_seen_at'] == null
            ? null
            : DateTime.parse(row['last_seen_at'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
}

/// The three administration levels, deliberately few — see
/// ADMIN_APP_SPEC.md §2's own reasoning on why level proliferation
/// produces permission systems nobody understands.
abstract class AdminLevel {
  static const support = 'support';
  static const operator_ = 'operator';
  static const owner = 'owner';

  static const all = [support, operator_, owner];

  /// Ordering for "at least this level" checks — support < operator <
  /// owner. A plain index lookup rather than an enum so a bad string
  /// from the database fails loud (ArgumentError on indexOf returning
  /// -1... actually returns -1 silently) — see [rank] below, which
  /// makes that failure explicit instead.
  static int rank(String level) {
    final i = all.indexOf(level);
    if (i == -1) {
      throw ArgumentError('Unknown admin level "$level"');
    }
    return i;
  }

  static bool atLeast(String actual, String required) =>
      rank(actual) >= rank(required);
}
