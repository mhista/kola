// code_block.dart — tabbed code sample component.
//
// ONLY TWO TABS, NOT THREE: DESIGN_PROMPT.md §12 asks for "Dart/cURL/JS
// tabs," but there is no JS SDK — kola_client (the generated Serverpod
// client) only targets Dart, and nothing in this codebase exposes a
// JavaScript client. Shipping a fake JS tab with made-up syntax would be
// exactly the "promises a backend/SDK that doesn't exist" mistake this
// project has repeatedly caught itself on elsewhere (Bot Detail Chat
// Mode's "Bot Mother" pane, Knowledge Base's document upload). [dart] is
// always required; [curl] is optional for cases where a raw HTTP example
// doesn't add anything beyond the Dart call (rare, but see the
// Authentication page's token-fetch example, which is cURL-only since
// that call happens before any Dart client exists in the picture).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class CodeBlock extends StatefulComponent {
  const CodeBlock({this.dart, this.curl, this.title});

  final String? dart;
  final String? curl;

  /// Optional small label above the tabs, e.g. "Create a bot".
  final String? title;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  late String _active = component.dart != null ? 'dart' : 'curl';

  @override
  Component build(BuildContext context) {
    final tabs = <String, String>{
      if (component.dart != null) 'dart': component.dart!,
      if (component.curl != null) 'curl': component.curl!,
    };

    return div(
      attributes: {
        'style':
            'background:${KolaDocsColors.codeBg};border:1px solid ${KolaDocsColors.border};'
            'border-radius:10px;overflow:hidden;margin:16px 0',
      },
      [
        if (component.title != null)
          div(
            attributes: {
              'style':
                  'padding:9px 14px;font-size:12.5px;color:${KolaDocsColors.textMuted};'
                  'border-bottom:1px solid ${KolaDocsColors.border}',
            },
            [Component.text(component.title!)],
          ),
        if (tabs.length > 1)
          div(
            attributes: {'style': 'display:flex;border-bottom:1px solid ${KolaDocsColors.border}'},
            [
              for (final key in tabs.keys)
                button(
                  [Component.text(key == 'dart' ? 'Dart' : 'cURL')],
                  type: ButtonType.button,
                  onClick: () => setState(() => _active = key),
                  attributes: {
                    'style':
                        'background:transparent;border:none;padding:8px 16px;font-size:12.5px;'
                        'font-family:${KolaDocsFonts.mono};cursor:pointer;'
                        'color:${_active == key ? KolaDocsColors.codeAccent : KolaDocsColors.textFaint};'
                        'border-bottom:2px solid ${_active == key ? KolaDocsColors.codeAccent : "transparent"}',
                  },
                ),
            ],
          ),
        pre(
          attributes: {
            'style':
                'margin:0;padding:14px 16px;overflow-x:auto;font-family:${KolaDocsFonts.mono};'
                'font-size:13px;line-height:1.6;color:${KolaDocsColors.codeText}',
          },
          [code([Component.text(tabs[_active] ?? '')])],
        ),
      ],
    );
  }
}
