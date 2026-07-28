// security_filter.dart
//
// Phase 3d (SRS.md §10): "A security_filter pass (already prototyped in
// Asami) runs before any AI-suggested Errand call or any AI-drafted
// outbound message that touches money, personal data, or an external
// system — this is the seam Phase 3's full fraud-prevention engine
// plugs into." Ported from asami_server's
// ai_services/core/security_filter.dart — reused, not reinvented, per
// the working convention — but trimmed to what actually applies here:
// Asami's version is a marketplace security filter with vendor/
// customer/admin roles and an e-commerce tool-permission map; Kola has
// neither concept (every end-user here is an anonymous customer
// chatting with a bot, and "tools" are Errands gated by
// Errand.permissionScope, not a role table). Kept: the pattern-based
// abuse detectors (prompt injection, SQL injection, XSS, credential
// leakage, phishing, spam/repetition) and rate limiting — these are
// generic, not e-commerce-specific. Dropped: UserType-based tool
// permissions, price/quantity/ID-format validation (Asami-specific
// business rules with no Kola equivalent yet).
//
// THREE CHECKPOINTS, MATCHING SRS.md §10's THREE TRIGGER MOMENTS:
//   1. checkInboundMessage — every customer message, BEFORE it's ever
//      handed to BotKnowledgeService/AiOrchestrator. Wired into
//      InboundMessageHandler.
//   2. checkErrandInput — every Errand invocation's input, BEFORE any
//      executor makes an external call (webhook = "an external
//      system", dbCredential = "money[-adjacent]/personal data" for
//      most real business tables). Wired into ErrandEndpoint.
//   3. checkOutboundText — an AI-drafted reply, BEFORE it's sent back
//      to a customer — lighter than #1 (the reply is grounded in
//      Bot.knowledgeSeed, not attacker-controlled, so the realistic
//      risk is narrower: an XSS-style payload getting echoed back
//      verbatim if the model quotes part of the question, not the
//      model spontaneously leaking credentials it was never given).
//
// THIS IS DELIBERATELY THE MVP GUARDRAIL, NOT THE FRAUD ENGINE: pattern
// matching over message text, same as Asami's prototype — no ML
// classifier, no behavioral scoring. SRS.md §10 explicitly frames this
// as "the seam" the real fraud-prevention engine plugs into later, not
// the engine itself.

class SecurityCheckResult {
  const SecurityCheckResult({
    required this.allowed,
    this.violationType,
    this.severity,
    this.warningMessage,
  });

  final bool allowed;
  final String? violationType;
  final String? severity;

  /// Safe to show the end customer directly when [allowed] is false —
  /// never echoes back the offending content, same care Asami's
  /// original took.
  final String? warningMessage;

  static const ok = SecurityCheckResult(allowed: true);
}

class SecurityFilter {
  // In-memory per-external-user-id rate limiting — same "Redis in
  // production" caveat Asami's version already carried; fine for a
  // single-instance MVP deployment, worth revisiting if Kola ever runs
  // more than one server instance.
  static final Map<String, List<DateTime>> _requestHistory = {};
  static const int _maxRequestsPerMinute = 30;
  static const int _maxRequestsPer5Minutes = 100;

  /// Checkpoint #1 — every inbound customer message, before it reaches
  /// the AI orchestrator at all.
  SecurityCheckResult checkInboundMessage({
    required String message,
    required String externalUserId,
  }) {
    final trimmed = message.trim();
    final lower = trimmed.toLowerCase();

    if (trimmed.isEmpty || trimmed.length < 2) {
      return const SecurityCheckResult(
        allowed: false,
        violationType: 'invalid_input',
        severity: 'low',
        warningMessage: 'Please send a message.',
      );
    }

    if (message.length > 10000) {
      return const SecurityCheckResult(
        allowed: false,
        violationType: 'excessive_length',
        severity: 'medium',
        warningMessage: 'That message is too long — please keep it under 10,000 characters.',
      );
    }

    for (final pattern in _promptInjectionPatterns) {
      if (lower.contains(pattern)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'prompt_injection',
          severity: 'critical',
          warningMessage: "I can only help with questions about this business — I can't follow instructions like that.",
        );
      }
    }

    for (final pattern in _sqlInjectionPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'sql_injection',
          severity: 'critical',
          warningMessage: 'Invalid characters detected in your message — please rephrase.',
        );
      }
    }

    for (final pattern in _xssPatterns) {
      if (lower.contains(pattern)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'xss_attempt',
          severity: 'high',
          warningMessage: 'Invalid content detected — please use plain text only.',
        );
      }
    }

    for (final pattern in _credentialPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'credential_leakage',
          severity: 'critical',
          warningMessage: "Please don't share passwords, API keys, or other credentials here.",
        );
      }
    }

    for (final pattern in _phishingPatterns) {
      if (lower.contains(pattern)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'phishing_attempt',
          severity: 'high',
          warningMessage: 'Suspicious content detected — this bot will never ask for your password or personal credentials.',
        );
      }
    }

    if (_isRepetitiveMessage(message)) {
      return const SecurityCheckResult(
        allowed: false,
        violationType: 'spam_detected',
        severity: 'low',
        warningMessage: "Please avoid repetitive messages — how can I help you?",
      );
    }

    final rateLimit = _checkRateLimit(externalUserId);
    if (!rateLimit.allowed) return rateLimit;

    return SecurityCheckResult.ok;
  }

  /// Checkpoint #2 — an Errand's input, before ANY executor
  /// (builtin/webhook/dbCredential) is allowed to run it. Scans every
  /// string value for the same injection/XSS/credential patterns as
  /// checkInboundMessage — deliberately redundant with dbCredential's
  /// structural protection (Sql.named already prevents SQL injection by
  /// construction; a named parameter can never become part of the SQL
  /// grammar) rather than a substitute for it: defense in depth, and
  /// the one check that also covers webhook Errands, which have no
  /// equivalent structural protection against what gets forwarded in
  /// the JSON body.
  SecurityCheckResult checkErrandInput(Map<String, dynamic> input) {
    for (final entry in input.entries) {
      final value = entry.value;
      if (value is! String) continue;
      final lower = value.toLowerCase();

      for (final pattern in _sqlInjectionPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
          return SecurityCheckResult(
            allowed: false,
            violationType: 'sql_injection',
            severity: 'critical',
            warningMessage: 'Invalid input in field "${entry.key}".',
          );
        }
      }
      for (final pattern in _xssPatterns) {
        if (lower.contains(pattern)) {
          return SecurityCheckResult(
            allowed: false,
            violationType: 'xss_attempt',
            severity: 'high',
            warningMessage: 'Invalid input in field "${entry.key}".',
          );
        }
      }
      for (final pattern in _credentialPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
          return SecurityCheckResult(
            allowed: false,
            violationType: 'credential_leakage',
            severity: 'critical',
            warningMessage: 'Invalid input in field "${entry.key}".',
          );
        }
      }
    }
    return SecurityCheckResult.ok;
  }

  /// Checkpoint #3 — an AI-drafted reply, before it's sent to the
  /// customer. Lighter than checkInboundMessage on purpose — see file
  /// header on why the realistic risk surface here is narrower.
  SecurityCheckResult checkOutboundText(String text) {
    final lower = text.toLowerCase();
    for (final pattern in _xssPatterns) {
      if (lower.contains(pattern)) {
        return const SecurityCheckResult(
          allowed: false,
          violationType: 'xss_attempt',
          severity: 'high',
          warningMessage: "I'm having trouble putting that into words safely — let me get a person to help.",
        );
      }
    }
    return SecurityCheckResult.ok;
  }

  SecurityCheckResult _checkRateLimit(String externalUserId) {
    final now = DateTime.now();
    final history = _requestHistory[externalUserId] ?? [];
    history.removeWhere((t) => now.difference(t).inMinutes > 5);

    final lastMinute = history.where((t) => now.difference(t).inSeconds < 60).length;
    if (lastMinute >= _maxRequestsPerMinute) {
      return const SecurityCheckResult(
        allowed: false,
        violationType: 'rate_limit_exceeded',
        severity: 'medium',
        warningMessage: "You're sending messages a bit fast — please wait a moment.",
      );
    }
    if (history.length >= _maxRequestsPer5Minutes) {
      return const SecurityCheckResult(
        allowed: false,
        violationType: 'rate_limit_exceeded',
        severity: 'high',
        warningMessage: 'Please wait a few minutes before sending more messages.',
      );
    }

    history.add(now);
    _requestHistory[externalUserId] = history;
    return SecurityCheckResult.ok;
  }

  bool _isRepetitiveMessage(String message) {
    if (RegExp(r'(.)\1{9,}').hasMatch(message)) return true;

    final words = message.toLowerCase().split(RegExp(r'\s+'));
    if (words.length > 5) {
      final uniqueRatio = words.toSet().length / words.length;
      if (uniqueRatio < 0.3) return true;
    }
    return false;
  }

  static const _promptInjectionPatterns = [
    'ignore previous instructions',
    'ignore all previous',
    'disregard previous',
    'system prompt',
    'you are now',
    'forget your role',
    'new instructions',
    'override instructions',
    'system message',
    'reset instructions',
    'jailbreak',
    'developer mode',
    'act as if',
    'pretend you are',
    'simulate being',
    'new system prompt',
    'ignore your programming',
    'bypass your restrictions',
  ];

  static const _sqlInjectionPatterns = [
    r"'\s*or\s*'",
    r'"\s*or\s*"',
    r"'\s*or\s*1\s*=\s*1",
    r'union\s+select',
    r'drop\s+table',
    r'delete\s+from',
    r'insert\s+into',
    r'update\s+.*\s+set',
    r'exec\s*\(',
    r'execute\s*\(',
    '--',
    r'/\*.*\*/',
  ];

  static const _xssPatterns = [
    '<script',
    'javascript:',
    'onerror=',
    'onload=',
    'onclick=',
    '<iframe',
    'eval(',
    'document.cookie',
    'window.location',
  ];

  static const _credentialPatterns = [
    r'api[_-]?key',
    r'access[_-]?token',
    r'secret[_-]?key',
    r'password\s*[=:]',
    r'bearer\s+[a-zA-Z0-9]',
    r'authorization:\s*',
    r'private[_-]?key',
    r'client[_-]?secret',
  ];

  static const _phishingPatterns = [
    'verify your account',
    'urgent: action required',
    'click here immediately',
    'your account will be suspended',
    'confirm your password',
    'unusual activity detected',
    'refund pending',
    'claim your prize',
  ];
}
