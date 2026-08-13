// billing_page.dart — plan, trial, usage, upgrade.
//
// REBUILT on the new design system. The previous version used
// KolaDashboardColors throughout; nothing here does.
//
// ── MONEY IS THE ONLY THING ON THIS PAGE THAT MUST NOT BE WRONG ──────
//
// getBillingSummary returns THREE fields that belong together:
//
//     paidPlanPriceMinor     the amount in MINOR units
//     priceCurrency          ISO-4217
//     priceMinorUnitDigits   how many digits are minor
//
// All three, always. An earlier version of the billing summary returned
// a flat Naira figure, which meant a Brazilian workspace was shown
// ₦10,000 and charged R$35. The three-field shape exists because of
// that bug.
//
// ZERO-DECIMAL CURRENCIES ARE THE TRAP. JPY, KRW and XOF have
// priceMinorUnitDigits = 0 — 1000 JPY is ¥1,000, not ¥10.00. Dividing
// by 100 unconditionally overstates the price by 100x for those
// markets, and it looks perfectly reasonable on screen. So the divisor
// is always computed from priceMinorUnitDigits, never assumed.
//
// The server is the authority on what is actually charged. Everything
// here is display.
//
// ── TRIAL HAS TWO DATES, NOT ONE ─────────────────────────────────────
//
// trialFullAccessEndsAt is when the good version ends. trialEndsAt is
// when the trial ends completely. Between them the workspace still
// works but capped, which is a genuinely different state and is worth
// saying out loud rather than showing one countdown that misleads.

import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class BillingPage extends StatefulComponent {
  const BillingPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.userEmail,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final String? userEmail;
  final FeatureGate gate;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  bool _upgrading = false;

  /// Set once checkout succeeds. Renders the payment link.
  String? _pendingCheckoutUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await component.client.workspace.getBillingSummary(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _summary = jsonDecode(raw) as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  Future<void> _upgrade() async {
    final s = _summary;
    final email = component.userEmail;
    if (s == null || _upgrading) return;

    if (email == null || email.isEmpty) {
      setState(() => _error =
          'No email address on this account, and the payment provider '
          'requires one to send a receipt.');
      return;
    }

    setState(() {
      _upgrading = true;
      _error = null;
    });

    try {
      final checkout = await component.client.workspace.initiateUpgrade(
        component.accessToken,
        component.workspaceId,
        (s['billingGateway'] as String?) ?? 'paystack',
        email,
      );
      if (!mounted) return;
      setState(() => _upgrading = false);

      final url = checkout.checkoutUrl;
      if (url == null || url.isEmpty) {
        setState(() => _error =
            'The payment provider did not return a checkout link. Nothing '
            'has been charged.');
        return;
      }
      // Surfaced as a LINK the owner clicks, not an automatic redirect.
      //
      // Popups are blocked by default on the mobile browsers most of
      // these owners use, so window.open would silently do nothing. And
      // being thrown onto a payment page without touching anything is
      // alarming when money is involved — a visible "Continue to
      // payment" step makes the transition deliberate.
      setState(() => _pendingCheckoutUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _upgrading = false;
        _error = 'Could not start checkout: $e';
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'max-width:820px;margin:0 auto;width:100%;'
            'padding:28px 20px 40px;display:flex;flex-direction:column;gap:18px',
      },
      [
        h1(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                'font-weight:700;color:${KolaVar.text};margin:0',
          },
          [Component.text('Billing')],
        ),
        if (_error != null) _errorBanner(),
        if (_pendingCheckoutUrl != null) _checkoutLink(),
        if (_loading)
          _skeleton()
        else if (_summary != null) ...[
          _planCard(_summary!),
          _usageCard(_summary!),
        ],
      ],
    );
  }

  // ── Plan ────────────────────────────────────────────────────────────

  Component _planCard(Map<String, dynamic> s) {
    final tier = (s['effectiveTier'] as String?) ?? '';
    final status = (s['status'] as String?) ?? '';
    final onPaid = tier == 'paid';

    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:20px;'
            'display:flex;flex-direction:column;gap:14px',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:10px;flex-wrap:wrap',
          },
          [
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.h3};font-weight:700;'
                    'color:${KolaVar.text}',
              },
              [Component.text(_planLabel(s['plan'] as String?))],
            ),
            span(
              attributes: {'style': _statusTone(tier).badgeCss},
              [Component.text(_statusLabel(tier, status))],
            ),
          ],
        ),

        _trialLine(s),

        if (!onPaid) ...[
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.mutedStrong};'
                  'line-height:1.6',
            },
            [
              Component.text(
                'The paid plan removes the daily message cap and the limit on '
                'automations. ${_priceLine(s)} a month.',
              ),
            ],
          ),
          button(
            attributes: {
              'class': 'kola-pressable',
              'type': 'button',
              'style': 'align-self:flex-start;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};border:none;'
                  'border-radius:${KolaRadius.pill};padding:10px 22px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'font-family:inherit;${_upgrading ? 'opacity:0.6' : ''}',
            },
            events: {'click': (_) => _upgrade()},
            [Component.text(_upgrading ? 'Starting checkout…' : 'Upgrade')],
          ),
        ],
      ],
    );
  }

  /// The two trial dates, stated separately.
  Component _trialLine(Map<String, dynamic> s) {
    final full = DateTime.tryParse((s['trialFullAccessEndsAt'] as String?) ?? '');
    final end = DateTime.tryParse((s['trialEndsAt'] as String?) ?? '');
    if (full == null && end == null) return div(attributes: const {}, []);

    final now = DateTime.now();
    final fullDays = full == null ? null : full.difference(now).inDays;
    final endDays = end == null ? null : end.difference(now).inDays;

    final text = (fullDays != null && fullDays > 0)
        ? 'Full access for ${_days(fullDays)}. After that it keeps working '
            'on the free limits until ${_days(endDays ?? 0)} from now.'
        : (endDays != null && endDays > 0)
            ? 'Now on free limits. The trial ends in ${_days(endDays)}.'
            : 'The trial has ended.';

    return div(
      attributes: {
        'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
            'line-height:1.6',
      },
      [Component.text(text)],
    );
  }

  // ── Usage ───────────────────────────────────────────────────────────

  Component _usageCard(Map<String, dynamic> s) => div(
        attributes: {
          'style': 'background:${KolaVar.card};'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:20px;'
              'display:flex;flex-direction:column;gap:16px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};font-weight:700;'
                  'color:${KolaVar.muted}',
            },
            [Component.text('Usage')],
          ),
          _meter(
            'Messages today',
            (s['messagesToday'] as num?)?.toInt() ?? 0,
            (s['messagesDailyCap'] as num?)?.toInt(),
          ),
          _meter(
            'Automations switched on',
            (s['activeErrandCount'] as num?)?.toInt() ?? 0,
            (s['errandCap'] as num?)?.toInt(),
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'line-height:1.6;border-top:1px solid ${KolaVar.border};'
                  'padding-top:12px',
            },
            [
              Component.text(
                'This month: ${(s['messagesThisMonth'] as num?)?.toInt() ?? 0} '
                'messages, ${(s['errandCallsThisMonth'] as num?)?.toInt() ?? 0} '
                'automation runs.',
              ),
            ],
          ),
        ],
      );

  /// One usage line. A cap of null means unlimited — shown as a count,
  /// not as a bar at 0%, which would read as "none used" on a paid plan.
  Component _meter(String label, int used, int? cap) {
    final pct = (cap == null || cap == 0)
        ? null
        : ((used / cap) * 100).clamp(0, 100).toDouble();

    final over = cap != null && used >= cap;

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:6px'},
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;gap:10px;'
                'font-size:${KolaType.small};color:${KolaVar.mutedStrong}',
          },
          [
            span([Component.text(label)]),
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};'
                    'font-variant-numeric:tabular-nums;'
                    'color:${over ? KolaVar.danger : KolaVar.text}',
              },
              [Component.text(cap == null ? '$used' : '$used / $cap')],
            ),
          ],
        ),
        if (pct != null)
          div(
            attributes: {
              'style': 'height:6px;border-radius:${KolaRadius.pill};'
                  'background:${KolaVar.pill};overflow:hidden',
            },
            [
              div(
                attributes: {
                  'style': 'height:100%;width:$pct%;'
                      'background:${over ? KolaVar.danger : KolaVar.accent}',
                },
                [],
              ),
            ],
          ),
        if (over)
          div(
            attributes: {
              'style': 'font-size:${KolaType.micro};color:${KolaVar.danger}',
            },
            // Says what the cap DOES. "Limit reached" alone does not tell
            // an owner their customers are currently being ignored.
            [
              Component.text(
                'Reached. Messages past this are not answered until tomorrow.',
              ),
            ],
          ),
      ],
    );
  }

  Component _checkoutLink() => div(
        attributes: {
          'style': 'background:${KolaVar.successBg};'
              'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:14px;'
              'display:flex;flex-direction:column;gap:10px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                  'line-height:1.5',
            },
            [
              Component.text(
                'Checkout is ready. Nothing has been charged yet — you pay on '
                'the provider\'s page.',
              ),
            ],
          ),
          a(
            attributes: {
              'class': 'kola-pressable',
              'style': 'align-self:flex-start;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};'
                  'border-radius:${KolaRadius.pill};padding:9px 20px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'text-decoration:none',
              'rel': 'noopener noreferrer',
            },
            [Component.text('Continue to payment →')],
            href: _pendingCheckoutUrl!,
          ),
        ],
      );

  Component _skeleton() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:14px'},
        [
          for (final h in const [150, 190])
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:${h}px;border-radius:${KolaRadius.lg}'},
              [],
            ),
        ],
      );

  Component _errorBanner() => div(
        attributes: {
          'role': 'alert',
          'style': 'padding:10px 14px;background:${KolaVar.dangerBg};'
              'color:${KolaVar.danger};border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};font-size:${KolaType.small}',
        },
        [Component.text(_error!)],
      );

  // ── Formatting ──────────────────────────────────────────────────────

  /// Formats the paid plan price from the three fields that belong
  /// together. See this file's header on why all three are required.
  static String _priceLine(Map<String, dynamic> s) {
    final minor = (s['paidPlanPriceMinor'] as num?)?.toInt();
    final currency = (s['priceCurrency'] as String?) ?? '';
    final digits = (s['priceMinorUnitDigits'] as num?)?.toInt() ?? 2;

    if (minor == null || currency.isEmpty) return 'Pricing unavailable';

    // Divisor from the declared digit count. NEVER a hardcoded 100 —
    // JPY, KRW and XOF are zero-decimal, and dividing those by 100
    // understates the price by 100x while looking entirely plausible.
    var divisor = 1;
    for (var i = 0; i < digits; i++) {
      divisor *= 10;
    }

    final major = minor / divisor;
    final text = digits == 0
        ? major.round().toString()
        : major.toStringAsFixed(digits);

    // Thousands separators, applied to the whole part only.
    final parts = text.split('.');
    final whole = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    final grouped = parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();

    // Currency CODE, not a symbol. '$' is ambiguous across a dozen
    // currencies and this is the number someone is about to be charged.
    return '$currency $grouped';
  }

  static String _planLabel(String? plan) => switch (plan) {
        'paid' => 'Paid plan',
        'free' => 'Free plan',
        null => 'Plan',
        _ => plan,
      };

  static String _statusLabel(String tier, String status) => switch (tier) {
        'paid' => 'Active',
        'trialFullAccess' => 'Trial',
        'cappedFree' => 'Free limits',
        'paused' => 'Paused',
        _ => status.isEmpty ? tier : status,
      };

  static KolaTone _statusTone(String tier) => switch (tier) {
        'paid' => KolaTone.positive,
        'trialFullAccess' => KolaTone.info,
        'paused' => KolaTone.negative,
        _ => KolaTone.neutral,
      };

  static String _days(int n) => n == 1 ? '1 day' : '$n days';
}
