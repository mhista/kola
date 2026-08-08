// pricing_section.dart
//
// Monthly/yearly toggle + three plan cards.
//
// PRICES COME FROM THE ACTIVE Region, not from this file. It used to
// hold Naira amounts directly; see i18n/region.dart for why that moved
// and which of the numbers there are actually settled.
//
// When mode == 'waitlist' every card's action button is relabelled and
// scrolls to #waitlist instead of leaving for the dashboard. That mode
// is no longer the default — see config/env.dart.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../config/app_links.dart';
import '../models/pricing_plan.dart';
import '../i18n/region.dart';
import '../interop.dart' as interop;

class PricingSection extends StatelessComponent {
  const PricingSection({
    required this.mode,
    required this.region,
    required this.yearly,
    required this.onSetMonthly,
    required this.onSetYearly,
  });

  final String mode;

  /// Supplies every number and symbol on this section. Passed in rather
  /// than read from a global so the section can be rendered for any
  /// market without touching it — see i18n/region.dart.
  final Region region;
  final bool yearly;
  final void Function() onSetMonthly;
  final void Function() onSetYearly;

  static const _plans = [
    PricingPlan(
      name: 'Free',
      badge: 'For trying kymaa out',
      tier: PlanTier.free,
      features: ['5 conversations / day', '1 bot', 'WhatsApp or Telegram', 'Community support'],
      ctaLabel: 'Start free',
    ),
    PricingPlan(
      name: 'Pro',
      badge: 'Most popular · bonus month free yearly',
      tier: PlanTier.pro,
      features: [
        'Unlimited conversations',
        '5 bots',
        'WhatsApp + Telegram',
        'Custom Errands',
        'Priority support',
      ],
      ctaLabel: 'Start free trial',
      popular: true,
    ),
    PricingPlan(
      name: 'Business',
      badge: 'For growing teams',
      tier: PlanTier.business,
      features: ['Everything in Pro', 'Unlimited bots', 'Team seats', 'API & webhooks', 'Dedicated support'],
      ctaLabel: 'Talk to us',
    ),
  ];

  @override
  Component build(BuildContext context) {
    final isWaitlist = mode == 'waitlist';

    return div(
      id: 'pricing',
      attributes: {'style': 'max-width:1100px;margin:120px auto 0;padding:0 32px;text-align:center'},
      [
        Component.element(
          tag: 'h2',
          classes: 'kola-h2',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:40px;font-weight:500;'
                'margin:0 0 14px;color:${KolaColors.text}',
          },
          children: [Component.text('Simple pricing, wherever you sell.')],
        ),
        if (isWaitlist)
          div(
            attributes: {
              'style':
                  'display:inline-block;background:${KolaColors.waitlistBannerBg};color:${KolaColors.orange};'
                  'font-size:13px;font-weight:600;padding:8px 18px;border-radius:100px;margin-bottom:48px;'
                  'max-width:420px;white-space:normal',
            },
            [
              Component.text('Launching soon — '),
              a(
                attributes: {'style': 'color:${KolaColors.orange};text-decoration:underline'},
                [Component.text('join the waitlist')],
                href: '#waitlist',
              ),
              Component.text(' to lock in this pricing'),
            ],
          ),
        div(
          attributes: {
            'style': 'display:inline-flex;background:${KolaColors.pillBg};border-radius:100px;padding:4px;margin-bottom:48px',
          },
          [
            button(
              attributes: {'style': _toggleStyle(!yearly)},
              events: {'click': (e) => onSetMonthly()},
              [Component.text('Monthly')],
            ),
            button(
              attributes: {'style': _toggleStyle(yearly)},
              events: {'click': (e) => onSetYearly()},
              [Component.text('Yearly · save 15%')],
            ),
          ],
        ),
        div(
          classes: 'kola-grid-3',
          attributes: {'style': 'text-align:left'},
          [for (final plan in _plans) _planCard(plan, isWaitlist)],
        ),
      ],
    );
  }

  String _toggleStyle(bool active) {
    final bg = active ? KolaColors.dark : 'transparent';
    final color = active ? KolaColors.darkText : KolaColors.textMutedLight;
    return 'border:none;padding:10px 22px;border-radius:100px;font-size:14px;font-weight:600;'
        'cursor:pointer;font-family:inherit;background:$bg;color:$color';
  }

  Component _planCard(PricingPlan plan, bool isWaitlist) {
    final actionBg = isWaitlist ? KolaColors.dark : (plan.popular ? KolaColors.accent : KolaColors.pillBg);
    final actionColor = isWaitlist ? KolaColors.darkText : (plan.popular ? '#FFF6EE' : KolaColors.text);
    final actionLabel = isWaitlist ? 'Join waitlist' : plan.ctaLabel;

    return div(
      classes: 'kola-card-lift',
      attributes: {
        'style':
            'background:${KolaColors.cardBg};border:1px solid ${plan.popular ? KolaColors.accent : KolaColors.border};'
            'border-radius:22px;padding:32px;position:relative',
      },
      [
        if (plan.popular)
          div(
            attributes: {
              'style':
                  'position:absolute;top:-13px;left:32px;background:${KolaColors.accent};color:#FFF6EE;'
                  'font-size:12px;font-weight:600;padding:5px 14px;border-radius:100px',
            },
            [Component.text('Most popular')],
          ),
        div(
          attributes: {'style': 'font-size:19px;font-weight:600;margin-bottom:6px;color:${KolaColors.text}'},
          [Component.text(plan.name)],
        ),
        div(
          attributes: {'style': 'font-size:13px;color:${KolaColors.badgeBrown};margin-bottom:20px'},
          [Component.text(plan.badge)],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:baseline;gap:4px;margin-bottom:24px'},
          [
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.serif};font-size:38px;font-weight:600;color:${KolaColors.text}',
              },
              [Component.text(plan.priceLabel(region: region, yearly: yearly))],
            ),
            span(attributes: {'style': 'font-size:14px;color:${KolaColors.textFaint}'}, [Component.text('/mo')]),
          ],
        ),
        div(
          attributes: {'style': 'font-size:13px;color:${KolaColors.textFaint};margin-bottom:24px'},
          // Names the currency explicitly. '$' alone means at least a
          // dozen different currencies, and a reader in Singapore or
          // Canada should not have to guess which one this is.
          [Component.text('per month · ${region.currencyCode}')],
        ),
        for (final feat in plan.features)
          div(
            attributes: {
              'style':
                  'display:flex;gap:8px;align-items:flex-start;font-size:14px;color:${KolaColors.textBody};'
                  'padding:8px 0;border-top:1px solid ${KolaColors.pillBg}',
            },
            [
              span(attributes: {'style': 'color:${KolaColors.success}'}, [Component.text('✓')]),
              span([Component.text(feat)]),
            ],
          ),
        // A "Start free" plan CTA leaves for the dashboard; everything
        // else still scrolls to the waitlist.
        //
        // RENDERED AS AN ANCHOR, not a button with a click handler.
        // A thing that navigates should be a link: middle-click and
        // "open in new tab" work, the destination shows in the status
        // bar, and it survives JavaScript failing to load. A button
        // that happens to change location has none of that.
        if (!isWaitlist && actionLabel.startsWith('Start free'))
          a(
            classes: 'kola-btn-lift',
            attributes: {
              'style':
                  'display:block;box-sizing:border-box;text-align:center;text-decoration:none;'
                  'width:100%;margin-top:24px;border:none;border-radius:100px;padding:13px;font-size:14.5px;'
                  'font-weight:600;cursor:pointer;font-family:inherit;background:$actionBg;color:$actionColor',
            },
            [Component.text(actionLabel)],
            href: AppLinks.dashboard,
          )
        else
          button(
            classes: 'kola-btn-lift',
            attributes: {
              'style':
                  'width:100%;margin-top:24px;border:none;border-radius:100px;padding:13px;font-size:14.5px;'
                  'font-weight:600;cursor:pointer;font-family:inherit;background:$actionBg;color:$actionColor',
            },
            events: {'click': (e) => interop.scrollToId('waitlist')},
            [Component.text(actionLabel)],
          ),
      ],
    );
  }
}
