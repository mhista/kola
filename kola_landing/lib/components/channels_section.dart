// channels_section.dart
//
// "Built for how your customers already message you" — the tabbed
// Conversational/Proactive/Notification copy next to a WhatsApp-style
// phone mockup. Tab state is owned by app.dart (passed down as
// activeTab + onTabChange) so it survives alongside every other bit of
// page state in one place, matching the rest of this page's pattern.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class _Message {
  const _Message(this.text, {required this.mine, required this.time});
  final String text;
  final bool mine;
  final String time;
}

class _TabContent {
  const _TabContent({
    required this.label,
    required this.body,
    required this.phoneTitle,
    required this.initial,
    required this.messages,
  });
  final String label;
  final String body;
  final String phoneTitle;
  final String initial;
  final List<_Message> messages;
}

class ChannelsSection extends StatelessComponent {
  const ChannelsSection({required this.activeTab, required this.onTabChange});

  final String activeTab;
  final void Function(String tab) onTabChange;

  static const _tabs = {
    'conversational': _TabContent(
      label: 'Conversational',
      body:
          "A customer messages your agent with a question — a price, a delivery date, "
          "whether something is in stock. kolaa answers instantly, in the customer's "
          'own words, pulling from what you\'ve taught it.',
      phoneTitle: "Aisha's Fashion House",
      initial: 'A',
      messages: [
        _Message('Do you have the red ankara in size 12?', mine: false, time: '10:14'),
        _Message('Yes! We have it in stock — ₦18,500. Want me to hold it for you?', mine: true, time: '10:14'),
      ],
    ),
    'proactive': _TabContent(
      label: 'Proactive',
      body:
          "kolaa doesn't just wait for questions — it can open the conversation. "
          'Negotiate a price, follow up on an abandoned cart, or nudge a customer '
          'who went quiet.',
      phoneTitle: 'Lekki Foods',
      initial: 'L',
      messages: [
        _Message("Hi! You added jollof combo x2 to cart but didn't check out — still want it?", mine: true, time: '6:02'),
        _Message('Oh yes, sorry! Send payment link', mine: false, time: '6:03'),
      ],
    ),
    'notification': _TabContent(
      label: 'Notification',
      body:
          'Order confirmations, delivery updates, appointment reminders, OTPs — '
          'sent automatically the moment an Errand fires, no manual typing.',
      phoneTitle: 'Kingsway Clinic',
      initial: 'K',
      messages: [
        _Message('Reminder: your appointment with Dr. Ade is tomorrow at 10am.', mine: true, time: '9:00'),
        _Message('Got it, thank you!', mine: false, time: '9:01'),
      ],
    ),
  };

  @override
  Component build(BuildContext context) {
    final tab = _tabs[activeTab] ?? _tabs['conversational']!;

    return div(
      id: 'reveal-channels',
      attributes: {'style': 'max-width:1100px;margin:110px auto 0;padding:0 32px'},
      [
        div(
          attributes: {
            'style':
                'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px',
          },
          // Phase D of the agent architecture correction — was
          // "WhatsApp & Telegram bots", naming the channels as the
          // product. They're channels an agent uses, not the agent.
          [Component.text('Channels your agent can use')],
        ),
        Component.element(
          tag: 'h2',
          classes: 'kola-h2',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:40px;font-weight:500;'
                'margin:0 0 44px;max-width:640px;color:${KolaColors.text}',
          },
          children: [Component.text('Built for how your customers already message you.')],
        ),
        div(classes: 'kola-grid-channels', [
          // ── Left: tabs + copy ──────────────────────────────────────
          div([
            div(
              attributes: {
                'style': 'display:flex;gap:26px;border-bottom:1px solid ${KolaColors.border};margin-bottom:26px',
              },
              [
                for (final entry in _tabs.entries)
                  div(
                    attributes: {
                      'style':
                          'padding-bottom:14px;font-size:15px;font-weight:600;cursor:pointer;'
                          'color:${entry.key == activeTab ? KolaColors.text : KolaColors.textFaint};'
                          'border-bottom:2px solid ${entry.key == activeTab ? KolaColors.accent : "transparent"}',
                    },
                    events: {'click': (e) => onTabChange(entry.key)},
                    [Component.text(entry.value.label)],
                  ),
              ],
            ),
            div(
              attributes: {'style': 'font-size:16px;color:${KolaColors.textNav};line-height:1.7'},
              [Component.text(tab.body)],
            ),
          ]),

          // ── Right: phone mockup ────────────────────────────────────
          div(
            attributes: {
              'style':
                  'background:${KolaColors.dark};border-radius:28px;padding:20px;'
                  'box-shadow:0 24px 60px rgba(28,24,21,0.18)',
            },
            [
              div(
                attributes: {
                  'style':
                      'background:#0B141A;border-radius:20px;overflow:hidden;'
                      'background-image:radial-gradient(circle,rgba(255,255,255,0.035) 1px,transparent 1px);'
                      'background-size:14px 14px',
                },
                [
                  div(
                    attributes: {
                      'style': 'background:#1F2C33;padding:12px 16px;display:flex;align-items:center;gap:10px',
                    },
                    [
                      span(attributes: {'style': 'color:#8696A0;font-size:17px'}, [Component.text('‹')]),
                      div(
                        attributes: {
                          'style':
                              'width:34px;height:34px;border-radius:50%;background:${KolaColors.success};'
                              'display:flex;align-items:center;justify-content:center;color:${KolaColors.darkText};'
                              'font-size:14px;font-weight:600;flex-shrink:0',
                        },
                        [Component.text(tab.initial)],
                      ),
                      div(attributes: {'style': 'flex:1;min-width:0'}, [
                        div(
                          attributes: {'style': 'font-size:14.5px;color:${KolaColors.darkText};font-weight:600'},
                          [Component.text(tab.phoneTitle)],
                        ),
                        div(attributes: {'style': 'font-size:11.5px;color:#8696A0'}, [Component.text('online')]),
                      ]),
                      span(attributes: {'style': 'color:#8696A0;font-size:15px'}, [Component.text('📹')]),
                      span(attributes: {'style': 'color:#8696A0;font-size:15px'}, [Component.text('⋮')]),
                    ],
                  ),
                  div(
                    attributes: {
                      'style': 'padding:16px;display:flex;flex-direction:column;gap:8px;min-height:260px',
                    },
                    [
                      for (final msg in tab.messages)
                        div(
                          attributes: {'style': 'align-self:${msg.mine ? "flex-end" : "flex-start"};max-width:80%'},
                          [
                            div(
                              attributes: {
                                'style':
                                    'background:${msg.mine ? "#005C4B" : "#202C33"};color:#E9EDEF;padding:8px 12px;'
                                    'border-radius:${msg.mine ? "14px 14px 4px 14px" : "14px 14px 14px 4px"};'
                                    'font-size:13.5px;line-height:1.4',
                              },
                              [
                                Component.text(msg.text),
                                div(
                                  attributes: {
                                    'style': 'display:flex;justify-content:flex-end;align-items:center;gap:4px;margin-top:3px',
                                  },
                                  [
                                    span(attributes: {'style': 'font-size:10.5px;color:#8696A0'}, [Component.text(msg.time)]),
                                    if (msg.mine)
                                      span(attributes: {'style': 'font-size:11px;color:#53BDEB'}, [Component.text('✓✓')]),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                  div(
                    attributes: {
                      'style': 'background:#1F2C33;padding:10px 14px;display:flex;align-items:center;gap:10px',
                    },
                    [
                      span(attributes: {'style': 'color:#8696A0;font-size:16px'}, [Component.text('😊')]),
                      div(
                        attributes: {
                          'style': 'flex:1;background:#2A3942;border-radius:100px;padding:9px 14px;font-size:13px;color:#8696A0',
                        },
                        [Component.text('Message')],
                      ),
                      div(
                        attributes: {
                          'style':
                              'width:34px;height:34px;border-radius:50%;background:#00A884;display:flex;'
                              'align-items:center;justify-content:center;color:#0B141A;font-size:14px;flex-shrink:0',
                        },
                        [Component.text('🎤')],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
