// doc_page_kit.dart — small prose helpers shared by every page in
// lib/pages/, so a heading/callout/list looks identical everywhere
// instead of each page file reinventing its own div/style combination.
// Same "extract the repeated card/row markup once" instinct as
// errand_builder_page.dart's _placeholderCard.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

Component docH1(String text) => h1(
  attributes: {
    'style':
        'font-family:${KolaDocsFonts.display};font-size:32px;font-weight:600;'
        'margin:0 0 12px',
  },
  [Component.text(text)],
);

Component docLede(String text) => div(
  attributes: {
    'style': 'font-size:16px;color:${KolaDocsColors.textMuted};margin-bottom:32px;line-height:1.6',
  },
  [Component.text(text)],
);

Component docH2(String text, {String? id}) => h2(
  attributes: {
    'style': 'font-size:21px;font-weight:600;margin:36px 0 12px',
    if (id != null) 'id': id,
  },
  [Component.text(text)],
);

Component docP(String text) => p(
  attributes: {
    'style': 'font-size:14.5px;line-height:1.75;color:${KolaDocsColors.text};margin:0 0 14px',
  },
  [Component.text(text)],
);

Component docList(List<String> items) => ul(
  attributes: {
    'style': 'font-size:14.5px;line-height:1.75;color:${KolaDocsColors.text};margin:0 0 14px;padding-left:22px',
  },
  [for (final item in items) li([Component.text(item)])],
);

/// A cited-fact / limitation callout — NOT a warning, just something
/// worth the reader's attention (e.g. "this method requires
/// requireWorkspaceAccess"). Neutral tone, muted styling.
Component docNote(String text) => div(
  attributes: {
    'style':
        'background:${KolaDocsColors.surface};border:1px solid ${KolaDocsColors.border};'
        'border-radius:8px;padding:12px 14px;font-size:13.5px;color:${KolaDocsColors.textMuted};'
        'margin:16px 0;line-height:1.6',
  },
  [Component.text(text)],
);

/// A "this doesn't exist yet" / "not confirmed" callout — the honest-
/// placeholder pattern this whole codebase uses instead of describing
/// aspirational features as if they were real (see Bot Detail Chat
/// Mode's "Bot Mother" placeholder, Knowledge Base's descoped upload).
/// Amber, more visually distinct than [docNote] on purpose.
Component docWarning(String text) => div(
  attributes: {
    'style':
        'background:${KolaDocsColors.warningBg};border:1px solid ${KolaDocsColors.warningBorder};'
        'border-radius:8px;padding:12px 14px;font-size:13.5px;color:${KolaDocsColors.warningText};'
        'margin:16px 0;line-height:1.6',
  },
  [Component.text('⚠ $text')],
);

/// Stand-in for a real screenshot that doesn't exist yet — see task #88
/// (kola's own repo). Carries [WHATSAPP_MANUAL_SETUP.md]'s exact
/// placeholder markers into the docs site verbatim rather than shipping
/// a fabricated image or skipping the step silently.
Component docScreenshotPlaceholder(String description) => div(
  attributes: {
    'style':
        'border:1px dashed ${KolaDocsColors.border};border-radius:10px;padding:28px 20px;'
        'text-align:center;color:${KolaDocsColors.textFaint};font-size:13px;margin:16px 0;'
        'background:${KolaDocsColors.surface}',
  },
  [
    div(attributes: {'style': 'font-size:22px;margin-bottom:8px'}, [Component.text('🖼')]),
    div([Component.text('Screenshot placeholder — $description')]),
  ],
);
