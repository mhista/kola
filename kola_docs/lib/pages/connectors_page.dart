// connectors_page.dart — '/connectors'.
//
// Documents ConnectorEndpoint — the data-source/tool marketplace,
// distinct from Channels (messaging platforms) and from payment
// gateways (documented on Invoices & Payments). Previously undocumented
// entirely. Confirmed directly against connector_endpoint.dart, which
// deliberately routes rather than duplicates: a channel or payment
// gateway connects through its own endpoint, never through here.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class ConnectorsPage extends StatelessComponent {
  const ConnectorsPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Connectors'),
      docLede(
        "kolaa's data-source marketplace: Google Sheets, Google Calendar, Google Drive, "
        'OneDrive/Excel, Dropbox, HubSpot, Instagram Shop, and Facebook Catalog, alongside '
        "generic form-based connectors. A messaging channel (WhatsApp, Telegram) connects "
        'through Channels, and a payment gateway connects through Invoices & Payments — this '
        'endpoint deliberately does not duplicate either.',
      ),

      docH2('Listing and connecting'),
      docP(
        'listConnectors returns every connector in the catalog with this workspace\'s state '
        'resolved onto it, including ones not yet released to this workspace (shown as '
        '"coming soon" rather than omitted) — the one deliberate exception in this codebase to '
        "hiding an unreleased capability's existence entirely.",
      ),
      const CodeBlock(
        title: 'ConnectorEndpoint.listConnectors',
        dart: "final connectors = await client.connector.listConnectors(accessToken, workspaceId);",
      ),
      docP(
        'A connector whose auth type is a plain form (fields) connects directly — values are '
        'keyed by the field names the catalog defines for that connector; anything else '
        'submitted is dropped, not stored.',
      ),
      const CodeBlock(
        title: 'ConnectorEndpoint.connectConnector — form-based',
        dart:
            "await client.connector.connectConnector(\n"
            "  accessToken, workspaceId, \"bumpa\",\n"
            '  {"secretKey": "...", "publicKey": "..."},\n'
            ");",
      ),

      docH2('OAuth connectors'),
      docP(
        'Google, Microsoft, Dropbox, HubSpot, and Meta connectors use a real browser OAuth '
        'redirect, not a form. Each has its own start method (startGoogleOAuth, '
        'startMicrosoftOAuth, startDropboxOAuth, startHubSpotOAuth, startMetaOAuth) returning '
        "the URL to send the owner's browser to; a signed, time-boxed state parameter is what "
        'ties the callback back to the right workspace and connector.',
      ),
      const CodeBlock(
        title: 'ConnectorEndpoint.startGoogleOAuth',
        dart:
            "final authUrl = await client.connector.startGoogleOAuth(\n"
            "  accessToken, workspaceId, \"google_sheets\",\n"
            ");\n"
            "// redirect the owner's browser to authUrl — the callback route completes the connect",
      ),
      docList([
        'google_sheets and google_calendar and google_drive share the Google OAuth flow, '
            'different scopes per connector.',
        'onedrive_excel uses the Microsoft flow.',
        'dropbox uses its own flow with no per-connector scope (Dropbox scopes are configured '
            'once on the app, not requested per call).',
        'hubspot uses its own flow.',
        'instagram_shop and facebook_catalog share one Meta OAuth app with different scopes '
            'per connector.',
      ]),

      docH2('Picking a target after connecting'),
      docP(
        'Google Sheets and OneDrive Excel both need a specific file chosen after the OAuth '
        'handshake — connecting the account is not the same as picking what to sync.',
      ),
      const CodeBlock(
        title: 'Google Sheets: list and choose spreadsheets',
        dart:
            "final sheets = await client.connector.listGoogleSheets(accessToken, workspaceId, \"google_sheets\");\n"
            "await client.connector.setGoogleSheetTargets(\n"
            "  accessToken, workspaceId, \"google_sheets\",\n"
            "  [for (final s in sheets) if (wantedIds.contains(s.id)) s.id],\n"
            ");",
      ),
      docNote(
        'setGoogleSheetTargets replaces the full set in one call; an empty list is valid and '
        'means "sync nothing." setGoogleSheetTarget (singular) is the older single-URL-paste '
        'fallback — it adds to the existing selection rather than replacing it.',
      ),
      const CodeBlock(
        title: 'OneDrive/Excel: set the file by sharing link',
        dart:
            "await client.connector.setExcelFileTarget(\n"
            "  accessToken, workspaceId, \"onedrive_excel\",\n"
            '  "https://onedrive.live.com/...", // a real Microsoft sharing URL\n'
            ");",
      ),

      docH2('Calendar booking mode'),
      docP(
        "Google Calendar is kolaa's first write-capable connector, so it carries its own "
        'guardrail: whether a bot-proposed booking is created immediately, or held for an '
        'owner to approve first. An unset workspace defaults to draft, never immediate by '
        'omission.',
      ),
      const CodeBlock(
        title: 'Calendar booking mode + approval queue',
        dart:
            "await client.connector.setCalendarBookingMode(accessToken, workspaceId, \"draft\");\n"
            "final pending = await client.connector.listPendingBookings(accessToken, workspaceId);\n"
            "await client.connector.approveBooking(accessToken, workspaceId, booking.id!);\n"
            "// or: await client.connector.rejectBooking(accessToken, workspaceId, booking.id!);",
      ),
      docNote(
        'If approving a booking fails on the Google side (a revoked token, for instance), the '
        'booking is left visibly stuck at approved rather than silently reverted — same '
        '"loud failure over a clean-looking screen" discipline as the rest of this codebase.',
      ),

      docH2('Disconnecting'),
      const CodeBlock(
        title: 'ConnectorEndpoint.disconnectConnector',
        dart: "await client.connector.disconnectConnector(accessToken, workspaceId, \"bumpa\");",
      ),
      docNote(
        "Disconnecting clears the stored credential but keeps the row — 'disconnected' and "
        '"never connected" are recorded as different states.',
      ),
    ]);
  }
}
