// waitlist_endpoint.dart
//
// Public, unauthenticated endpoint — the only one in the project that
// deliberately has no auth check at all. Anyone visiting the landing page
// before they have any account can call this. See waitlist_signup.spy.yaml
// for why this model sits outside the workspace multi-tenancy boundary.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/repository/waitlist_signup_repository.dart';
import 'package:kola_server/kola_logger.dart';

class WaitlistEndpoint extends Endpoint {
  WaitlistSignupRepository get _waitlist => getIt<WaitlistSignupRepository>();

  /// Records a waitlist signup from the landing page. [source] identifies
  /// which on-page form submitted it ('hero' | 'waitlist_section' |
  /// 'footer') — see kola_landing's components for the three call sites.
  ///
  /// A basic shape check on [email] happens here rather than trusting the
  /// browser's <input type="email"> alone, since this endpoint is public
  /// and reachable by anything, not just our own landing page.
  Future<WaitlistSignup> joinWaitlist(
    Session session,
    String email,
    String source, {
    String? name,
    String? phone,
    String? businessType,
  }) async {
    final trimmedEmail = email.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmedEmail)) {
      throw KolaException(message: 'Invalid email address');
    }

    final signup = await _waitlist.upsertByEmail(
      email: trimmedEmail,
      name: (name?.trim().isEmpty ?? true) ? null : name!.trim(),
      phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      businessType: (businessType?.trim().isEmpty ?? true)
          ? null
          : businessType!.trim(),
      source: source,
    );

    Log.success(
      'Waitlist signup',
      data: {'email': trimmedEmail, 'source': source},
      session: session,
    );

    return signup;
  }
}
