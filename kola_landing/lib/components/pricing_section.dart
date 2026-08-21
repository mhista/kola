// pricing_section.dart
//
// Two plans. Numbers are the real ones from PlanLimits — ₦10,000/month,
// 50 messages/day, 1 bot, 3 errands, 5 knowledge documents — not
// illustrative figures.
//
// THE BOTTOM NOTE used to announce Meta's 1 October 2026 pricing change.
// Removed deliberately: telling a prospect that messaging is about to get
// more expensive plants a worry they did not arrive with, makes the whole
// category look costly, and does not even differentiate — that change
// lands on every platform equally. It belongs in the dashboard and the
// docs, where someone is managing real spend, not on a page trying to
// earn a first yes.
//
// The slot now answers the fear an SME buyer actually turns up with:
// hidden costs. The cost-management capability is still communicated —
// just as a reassurance rather than a warning.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../i18n/region.dart';
import '../i18n/strings.dart';

class PricingSection extends StatelessComponent {
  const PricingSection({required this.s, required this.mode, required this.region});

  final Strings s;
  final String mode;

  /// Which region's price to show. Resolved once in app.dart — no
  /// component hardcodes a currency. See i18n/region.dart on why pricing
  /// is regional by purchasing power rather than one converted number.
  final Region region;
  bool get _isWaitlist => mode != 'launched';

  // Phase D of the agent architecture correction — product-facing copy
  // says "agent"; the underlying limit is still PlanLimits.
  // cappedFreeBotCap server-side (Bot stays the internal identifier, see
  // agent_lifecycle_events.dart's header for why). Same word, two
  // audiences, same discipline as everywhere else in this rename.
  static const _free = [
    'Sales counter, offline included',
    '50 customer messages / day',
    '1 agent, 3 errands',
    '5 knowledge documents',
  ];

  static const _pro = [
    'Everything in Free, uncapped',
    'Unlimited agents and errands',
    'Full knowledge base',
    'Priority support',
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'pricing',
        'style': 'max-width:1000px;margin:120px auto 0;padding:0 32px;text-align:center',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 14px',
          },
          [Component.text(s.pricingTitle)],
        ),
        if (_isWaitlist)
          div(
            attributes: {
              'style': 'background:${KolaColors.waitlistBannerBg};color:${KolaColors.orange};'
                  'font-size:13px;font-weight:600;padding:10px 18px;border-radius:16px;'
                  'margin:0 auto 44px;max-width:440px',
            },
            [Component.text(s.pricingWaitlistNote)],
          )
        else
          div(attributes: {'style': 'height:30px'}, []),
        div(
          classes: 'kola-grid-2',
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(2,1fr);gap:24px;'
                'text-align:left;max-width:640px;margin:0 auto 36px',
          },
          [
            _plan(
              name: s.planFree,
              sub: s.planFreeSub,
              price: region.symbolLeads
                  ? '${region.currencySymbol}0'
                  : '0 ${region.currencySymbol}',
              suffix: null,
              features: _free,
              featured: false,
            ),
            _plan(
              name: s.planPro,
              sub: s.planProSub,
              price: region.formattedProPrice,
              suffix: '/mo',
              features: _pro,
              featured: true,
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:13px;color:${KolaColors.textFaint};'
                'margin:0 auto 28px;max-width:640px',
          },
          [
            Component.text(s.pricingRegionNote(region.currencyCode)),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaColors.pillBg};border-radius:16px;padding:22px 26px;'
                'max-width:640px;margin:0 auto;text-align:left',
          },
          [
            div(
              attributes: {'style': 'font-size:14px;font-weight:600;margin-bottom:6px'},
              [Component.text(s.pricingNoSurprisesTitle)],
            ),
            div(
              attributes: {
                'style': 'font-size:13.5px;color:${KolaColors.textMuted};line-height:1.6',
              },
              [
                Component.text(s.pricingNoSurprisesBody),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Component _plan({
    required String name,
    required String sub,
    required String price,
    required String? suffix,
    required List<String> features,
    required bool featured,
  }) {
    return div(
      attributes: {
        'style': 'background:${KolaColors.cardBg};'
            'border:1px solid ${featured ? KolaColors.accent : KolaColors.border};'
            'border-radius:22px;padding:30px;position:relative',
      },
      [
        if (featured)
          div(
            attributes: {
              'style': 'position:absolute;top:-13px;left:30px;'
                  'background:${KolaColors.accent};color:${KolaColors.accentText};'
                  'font-size:12px;font-weight:600;padding:5px 14px;border-radius:100px',
            },
            [Component.text(s.planPopular)],
          ),
        div(
          attributes: {'style': 'font-size:18px;font-weight:600;margin-bottom:6px'},
          [Component.text(name)],
        ),
        div(
          attributes: {
            'style': 'font-size:13px;color:${KolaColors.badgeBrown};margin-bottom:18px',
          },
          [Component.text(sub)],
        ),
        div(
          attributes: {
            'style': 'display:flex;align-items:baseline;gap:4px;margin-bottom:18px',
          },
          [
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.serif};font-size:32px;font-weight:600',
              },
              [Component.text(price)],
            ),
            if (suffix != null)
              span(
                attributes: {'style': 'font-size:13px;color:${KolaColors.textFaint}'},
                [Component.text(suffix)],
              ),
          ],
        ),
        for (final f in features)
          div(
            attributes: {
              'style': 'display:flex;gap:8px;font-size:13.5px;color:${KolaColors.textBody};'
                  'padding:7px 0;border-top:1px solid ${KolaColors.pillBg};line-height:1.45',
            },
            [
              span(
                attributes: {
                  'style': 'color:${KolaColors.success};flex:none',
                  'aria-hidden': 'true',
                },
                [Component.text('✓')],
              ),
              span([Component.text(f)]),
            ],
          ),
      ],
    );
  }
}
