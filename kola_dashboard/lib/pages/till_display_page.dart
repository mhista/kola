// till_display_page.dart — Phase 11's in-store customer display,
// /display/:workspaceId. The second unauthenticated page in this
// dashboard (see public_catalog_page.dart's own header for the first) —
// same app.dart._redirect bypass, added alongside this file.
//
// A projection of the till's state, not a separate app — see
// DESIGN_BRIEF_COMMERCE.md's own words on this surface: "a second
// screen facing the customer showing items as they are scanned, the
// running total, and then the receipt... same data, customer-appropriate
// framing, no staff controls, no cost or margin data ever visible."
//
// Polls TillDisplayEndpoint.getState — no accessToken, same shape as
// PublicCatalogPage's read of getPublicCatalog. NEVER shows cost or
// margin: TillDisplayItem carries only name/quantity/unitPriceMinor/
// lineTotalMinor, enforced server-side the same structural way
// PublicCatalogItem enforces it for the catalog page — see that
// model's own header.
//
// Meant to be left open on a second screen well before the first sale
// of the day — getState's own doc comment on why "no row yet" reads as
// an honest idle state, not an error. This page mirrors that: an idle
// screen is the expected resting state, not a failure to render.

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';

class TillDisplayPage extends StatefulComponent {
  const TillDisplayPage({required this.client, required this.workspaceId});

  final Client client;
  final int workspaceId;

  @override
  State<TillDisplayPage> createState() => _TillDisplayPageState();
}

class _TillDisplayPageState extends State<TillDisplayPage> {
  TillDisplayState? _state;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Polling, not a socket — the till side already polls nothing (it
    // pushes on mutation), and this screen has no session to hold a
    // subscription open with. Two seconds is fast enough that a scan
    // feels live without hammering the endpoint from a screen that may
    // sit open all day.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await component.client.tillDisplay.getState(
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Deliberately generic — see TillDisplayEndpoint.getState's own
        // header on why a probe against a random workspaceId cannot
        // learn which check failed.
        _error = 'This display is not available.';
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'font-family:${KolaFonts.sans};background:${KolaVar.bg};'
            'color:${KolaVar.text};min-height:100vh;width:100%;'
            'box-sizing:border-box;padding:${KolaSpace.xl};'
            'display:flex;flex-direction:column',
      },
      [
        if (_loading && _state == null) _center('Loading…'),
        if (_error != null && _state == null) _center(_error!),
        if (_state != null) _body(_state!),
      ],
    );
  }

  Component _center(String text) => div(
        attributes: {
          'style': 'width:100%;min-height:100vh;display:flex;'
              'align-items:center;justify-content:center;'
              'color:${KolaVar.muted};font-size:${KolaType.h2}',
        },
        [Component.text(text)],
      );

  Component _body(TillDisplayState state) {
    if (state.status == 'receipt') return _receiptView(state);
    if (state.items.isEmpty) return _idleView(state);
    return _shoppingView(state);
  }

  /// Nothing rung up yet — this is the expected resting state for a
  /// screen left on all day, not an error. See this file's own header.
  Component _idleView(TillDisplayState state) => div(
        attributes: {
          'style': 'flex:1;display:flex;flex-direction:column;'
              'align-items:center;justify-content:center;gap:${KolaSpace.sm}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.h1};font-weight:700',
            },
            [Component.text(state.businessName)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted}',
            },
            [Component.text('Welcome — ring us up when you\'re ready.')],
          ),
        ],
      );

  Component _shoppingView(TillDisplayState state) => div(
        attributes: {'style': 'flex:1;display:flex;flex-direction:column;max-width:720px;margin:0 auto;width:100%'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.h3};font-weight:700;'
                  'margin-bottom:${KolaSpace.lg}',
            },
            [Component.text(state.businessName)],
          ),
          div(
            attributes: {
              'style': 'flex:1;overflow-y:auto;display:flex;'
                  'flex-direction:column;gap:${KolaSpace.sm}',
            },
            [for (final item in state.items) _lineRow(item)],
          ),
          div(
            attributes: {
              'style': 'border-top:2px solid ${KolaVar.border};'
                  'margin-top:${KolaSpace.md};padding-top:${KolaSpace.md};'
                  'display:flex;align-items:baseline;justify-content:space-between',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};color:${KolaVar.muted}',
                },
                [Component.text(state.status == 'payment' ? 'Total due' : 'Total')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.h1};font-weight:700',
                },
                [Component.text(_money(state.subtotalMinor, state.currency))],
              ),
            ],
          ),
        ],
      );

  Component _lineRow(TillDisplayItem item) => div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'gap:${KolaSpace.md};font-size:${KolaType.body};'
              'padding:${KolaSpace.xs} 0',
        },
        [
          div(
            attributes: {'style': 'display:flex;gap:${KolaSpace.sm};flex:1;min-width:0'},
            [
              div(
                attributes: {'style': 'color:${KolaVar.muted};flex-shrink:0'},
                [Component.text('${item.quantity}×')],
              ),
              div(
                attributes: {
                  'style': 'overflow:hidden;text-overflow:ellipsis;'
                      'white-space:nowrap',
                },
                [Component.text(item.name)],
              ),
            ],
          ),
          div(
            attributes: {'style': 'flex-shrink:0;font-weight:600'},
            [Component.text(_money(item.lineTotalMinor, 'NGN'))],
          ),
        ],
      );

  /// The final screen of a completed sale — the till moved to this
  /// status right after checkout. Deliberately similar to the shopping
  /// view (same line items, same total) rather than a generic "thank
  /// you" card, so the customer can see exactly what they were charged
  /// for one last time before the display resets to idle for the next
  /// customer (the till's own reset, not this page — see till_page.dart's
  /// push call sites).
  Component _receiptView(TillDisplayState state) => div(
        attributes: {'style': 'flex:1;display:flex;flex-direction:column;max-width:720px;margin:0 auto;width:100%'},
        [
          div(
            attributes: {
              'style': 'text-align:center;margin-bottom:${KolaSpace.lg}',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.success}',
                },
                [Component.text('Thank you!')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [Component.text(state.businessName)],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;gap:${KolaSpace.sm}',
            },
            [for (final item in state.items) _lineRow(item)],
          ),
          div(
            attributes: {
              'style': 'border-top:2px solid ${KolaVar.border};'
                  'margin-top:${KolaSpace.md};padding-top:${KolaSpace.md};'
                  'display:flex;align-items:baseline;justify-content:space-between',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};color:${KolaVar.muted}',
                },
                [Component.text('Total paid')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.h1};font-weight:700',
                },
                [Component.text(_money(state.subtotalMinor, state.currency))],
              ),
            ],
          ),
        ],
      );

  /// Same minor-unit-divided-by-100 approach as PublicCatalogPage's own
  /// _priceLabel, and the same named gap: zero-decimal currencies are
  /// not handled specially here either.
  String _money(int minor, String currency) {
    final major = minor / 100;
    return '$currency ${major.toStringAsFixed(2)}';
  }
}
