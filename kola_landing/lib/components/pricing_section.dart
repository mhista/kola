// pricing_section.dart
//
// Monthly/yearly toggle + three plan cards, per PRD.md §10's Naira
// pricing. When mode == 'waitlist', every card's action button scrolls
// to the #waitlist section instead of a real signup flow — matches the
// isWaitlist branch in Kola Landing.dc.html.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/pricing_plan.dart';
import '../interop.dart' as interop;

class PricingSection extends StatelessComponent {
  const PricingSection({
    required this.mode,
    required this.yearly,
    required this.onSetMonthly,
    required this.onSetYearly,
  });

  final String mode;
  final bool yearly;
  final void Function() onSetMonthly;
  final void Function() onSetYearly;

  static const _plans = [
    PricingPlan(
      name: 'Free',
      badge: 'For trying kola out',
      monthlyPriceNgn: 0,
      usdEquivalent: '\$0',
      features: ['5 conversations / day', '1 bot', 'WhatsApp or Telegram', 'Community support'],
      ctaLabel: 'Start free',
    ),
    PricingPlan(
      name: 'Pro',
      badge: 'Most popular · bonus month free yearly',
      monthlyPriceNgn: 45000,
      usdEquivalent: '≈ \$28 USD',
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
      monthlyPriceNgn: 120000,
      usdEquivalent: '≈ \$75 USD',
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
          children: [Component.text('Simple pricing, priced for Naija.')],
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
              [Component.text(plan.priceLabel(yearly: yearly))],
            ),
            span(attributes: {'style': 'font-size:14px;color:${KolaColors.textFaint}'}, [Component.text('/mo')]),
          ],
        ),
        div(
          attributes: {'style': 'font-size:13px;color:${KolaColors.textFaint};margin-bottom:24px'},
          [Component.text(plan.usdEquivalent)],
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
