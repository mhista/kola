// dev_logs_tab.dart — Structured Mode's Logs tab: a monospace event
// feed, matching Kola Bot Detail Dev.dc.html. Mock entries here; real
// data is kola_server's ErrandExecutionLog (Phase 3b/3c) once
// kola_client wiring exists.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/log_entry.dart';

class DevLogsTab extends StatelessComponent {
  const DevLogsTab({required this.logs});

  final List<LogEntry> logs;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'max-width:900px;font-family:${KolaDashboardFonts.mono};font-size:12.5px;'
            'color:${KolaDashboardColors.mutedStrong};background:#0D0D0E;'
            'border:1px solid ${KolaDashboardColors.border};border-radius:12px;padding:18px;line-height:2',
      },
      [
        for (final l in logs)
          div(
            [
              span(attributes: {'style': 'color:${KolaDashboardColors.muted}'}, [Component.text(l.time)]),
              Component.text(' ${l.text}'),
            ],
          ),
      ],
    );
  }
}
