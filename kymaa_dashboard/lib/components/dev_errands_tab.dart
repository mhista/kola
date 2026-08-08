// dev_errands_tab.dart — Structured Mode's Errands tab: the table +
// detail side panel, matching Kola Bot Detail Dev.dc.html exactly.
// [selectedIndex]/[onRowClick]/[onClose] are owned by BotDetailDevPage
// (real client-side selection state) — this component is purely
// presentational, same split as DevTabBar.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/errand_row.dart';
// Needed directly for the ErrandStatusColors extension's .bg/.color
// getters used below — importing errand_row.dart (which itself imports
// this) is NOT enough, Dart requires an extension's declaring library
// to be imported into whichever file calls it.
import '../models/errand_status.dart';

class DevErrandsTab extends StatelessComponent {
  const DevErrandsTab({
    required this.rows,
    required this.selectedIndex,
    required this.onRowClick,
    required this.onClose,
  });

  final List<ErrandRow> rows;
  final int? selectedIndex;
  final void Function(int index) onRowClick;
  final void Function() onClose;

  @override
  Component build(BuildContext context) {
    final selected = selectedIndex != null ? rows[selectedIndex!] : null;

    return div(
      attributes: {'style': 'display:flex;gap:24px'},
      [
        div(attributes: {'style': 'flex:1;min-width:0'}, [_table()]),
        if (selected != null) _detailPanel(selected),
      ],
    );
  }

  Component _table() {
    return table(
      attributes: {'style': 'width:100%;border-collapse:collapse;font-size:13.5px'},
      [
        thead([
          tr(
            attributes: {
              'style':
                  'text-align:left;color:${KolaDashboardColors.muted};font-size:12px;'
                  'text-transform:uppercase;letter-spacing:0.04em',
            },
            [
              for (final label in ['Name', 'Trigger', 'Source', 'Status', 'Last called'])
                th(attributes: {'style': 'padding:0 0 12px;font-weight:500'}, [Component.text(label)]),
            ],
          ),
        ]),
        tbody([for (var i = 0; i < rows.length; i++) _row(i, rows[i])]),
      ],
    );
  }

  Component _row(int index, ErrandRow row) {
    return tr(
      attributes: {'style': 'border-top:1px solid #1F1D1B;cursor:pointer'},
      events: {'click': (_) => onRowClick(index)},
      [
        td(attributes: {'style': 'padding:14px 0;font-weight:600'}, [Component.text(row.name)]),
        td(
          attributes: {'style': 'padding:14px 0;color:${KolaDashboardColors.mutedStrong}'},
          [Component.text(row.trigger)],
        ),
        td(
          attributes: {
            'style': 'padding:14px 0;font-family:${KolaDashboardFonts.mono};font-size:12.5px;'
                'color:${KolaDashboardColors.mutedSecondary}',
          },
          [Component.text(row.source)],
        ),
        td(
          attributes: {'style': 'padding:14px 0'},
          [
            span(
              attributes: {
                'style':
                    'font-size:11.5px;font-weight:600;padding:3px 10px;border-radius:100px;'
                    'background:${row.status.bg};color:${row.status.color}',
              },
              [Component.text(row.statusLabel)],
            ),
          ],
        ),
        td(
          attributes: {'style': 'padding:14px 0;color:${KolaDashboardColors.muted}'},
          [Component.text(row.lastCalled)],
        ),
      ],
    );
  }

  Component _detailPanel(ErrandRow row) {
    return div(
      attributes: {
        'style':
            'width:380px;flex-shrink:0;background:${KolaDashboardColors.card};'
            'border:1px solid ${KolaDashboardColors.border};border-radius:16px;padding:22px;'
            'box-sizing:border-box;height:fit-content',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;align-items:center;margin-bottom:18px',
          },
          [
            div(attributes: {'style': 'font-size:16px;font-weight:600'}, [Component.text(row.name)]),
            span(
              attributes: {'style': 'cursor:pointer;color:${KolaDashboardColors.muted};font-size:18px'},
              events: {'click': (_) => onClose()},
              [Component.text('×')],
            ),
          ],
        ),
        _label('Input schema'),
        pre(
          attributes: {
            'style':
                'background:#000;border-radius:10px;padding:14px;font-family:${KolaDashboardFonts.mono};'
                'font-size:12px;color:#9BE6C7;overflow-x:auto;margin:0 0 18px;line-height:1.6',
          },
          [Component.text(row.schema)],
        ),
        _label('Fulfillment'),
        div(
          attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.navInactiveText};margin-bottom:18px'},
          [Component.text(row.fulfillment)],
        ),
        _label('Permission scope'),
        div(
          attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.navInactiveText}'},
          [Component.text(row.scope)],
        ),
      ],
    );
  }

  Component _label(String text) => div(
    attributes: {
      'style':
          'font-size:12px;color:${KolaDashboardColors.muted};text-transform:uppercase;'
          'letter-spacing:0.04em;margin-bottom:8px',
    },
    [Component.text(text)],
  );
}
