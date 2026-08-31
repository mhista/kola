// integrations_page.dart — the connector marketplace.
//
// REBUILT against Kola Integrations.dc.html. The previous version of this
// file grouped channels by bot, which is a different screen from the one
// the design specifies — see DESIGN_DELTA.md, "Integrations — WRONG".
//
// ── PHASE C, THEN REVERSED — CHANNELS ARE BACK IN THE GRID ────────────
//
// Phase C pulled WhatsApp/Telegram out of the "Sell" category grid into
// their own section above the search bar, on the reasoning that
// connecting a channel isn't a sell-tool decision — it's a
// communication surface any agent can use. The owner asked for that
// reversed: WhatsApp/Telegram back in the same searchable/filterable
// grid as everything else, not pinned above it in a section of their
// own. `ConnectorStatus.isChannel` and `ConnectorStore.channel` (in
// connector_catalog.dart) still exist and are still accurate — a
// channel's credentials still live in a different table than a generic
// connector's — that distinction was never wrong. What changed is
// purely presentational: [_visible] and [_countFor] no longer exclude
// channels, and the dedicated `_channelsSection`/`_channels` rendering
// path was removed rather than kept as unused dead code.
//
// ── WHAT THE DESIGN SPECIFIES ────────────────────────────────────────
//
//   16 connectors, 4 categories        ← served, not hardcoded (was 15 at
//                                        the design spec's own count;
//                                        'instagram' joined 2026-08-31)
//   search                             ← name + description
//   category filter with counts        ← "All (15)", "Sell (5)" …
//   per-connector modal                ← 5 auth types
//   4 states                           ← connected / available / soon / error
//
// ── THE LIST COMES FROM THE SERVER ───────────────────────────────────
//
// ConnectorEndpoint.listConnectors returns all 15 with this workspace's
// state already resolved. This page holds NO connector list of its own.
// The previous one did, which meant the server and the UI could disagree
// about what exists — and the UI always won, because it was the one
// drawing the screen.
//
// So: no catalog here, no hardcoded names, no client-side decision about
// what is coming soon. `soon` arrives from the server, computed from the
// capability flag.
//
// ── WHY `soon` TILES APPEAR AT ALL ───────────────────────────────────
//
// FeatureGate deliberately hides the unreleased roadmap — the server
// returns only enabled keys. This screen is a narrow, deliberate
// exception: the design shows coming-soon tiles, and a connector NAME is
// a much smaller disclosure than a feature key and its state. Nothing
// here reveals which flag governs what.
//
// ── FIVE AUTH TYPES, NOT FOUR ────────────────────────────────────────
//
//   fields      paste credentials into a form        → connectConnector
//   whatsapp    Meta's setup, its own copy           → same endpoint
//   manage      configured elsewhere; link there     → manageRoute
//   oauth       redirect to the provider             → NOT BUILT
//   keydisplay  we show a key to paste into THEM     → NOT BUILT
//
// `whatsapp` is its own type in the export, branching in two places.
// Reading that file with a field-order regex reports four types and
// silently loses it.
//
// oauth and keydisplay render an honest explanation rather than a button
// that does nothing. A connect button that fails silently is worse than
// one that says why it cannot work yet.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class IntegrationsPage extends StatefulComponent {
  const IntegrationsPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final FeatureGate gate;

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  List<ConnectorStatus> _connectors = const [];
  bool _loading = true;
  String? _loadError;

  // ── Channel-connect fix (2026-08-31) ─────────────────────────────────
  //
  // Channel.botId is the real foreign key — connecting WhatsApp/Telegram/
  // Instagram means picking WHICH bot the channel belongs to, something
  // this page never had to ask before because [_submit] never actually
  // reached ChannelEndpoint (see _submitChannel's own header). Fetched
  // alongside connectors so the modal can decide, on open, whether a
  // picker is even needed: one bot (the common case, and the only
  // option on the free tier's cappedFreeBotCap = 1) auto-selects with no
  // extra UI; zero bots blocks with a "create a bot first" message
  // instead of a dropdown with nothing in it.
  List<Bot> _bots = const [];
  int? _selectedBotId;

  String _search = '';
  String _category = 'all';

  /// Key of the connector whose modal is open. Null means none.
  String? _openKey;

  final Map<String, String> _formValues = {};
  bool _submitting = false;
  String? _submitError;

  /// Gate 4 — the target-URL field for authType 'oauth' connectors that
  /// need something picked AFTER signing in: which sheet (google_sheets)
  /// or which file (onedrive_excel) — see ConnectorEndpoint
  /// .setGoogleSheetTarget/.setExcelFileTarget's own headers on why this
  /// is a second step rather than part of the OAuth redirect itself.
  /// One field shared by both rather than two near-identical ones,
  /// because only one connector's modal is ever open at a time.
  /// Separate from [_formValues] because that map is keyed by
  /// ConnectorField.key for authType 'fields' connectors, which oauth
  /// connectors have none of.
  String _sheetUrl = '';

  // ── Connect Gate, subphase 4d — Google Sheets picker ─────────────────
  //
  // Replaces the paste-a-link step for google_sheets specifically (NOT
  // onedrive_excel — see ConnectorEndpoint.setExcelFileTarget's header
  // on why a OneDrive/SharePoint sharing link still has to be pasted,
  // it carries no stable id the way a Drive file does). The account
  // already grants read access to every sheet it can see
  // (spreadsheets.readonly is account-wide, not per-file) — this list
  // is purely a DISCOVERY aid, fetched via ConnectorEndpoint
  // .listGoogleSheets, which itself calls Drive under
  // drive.metadata.readonly. See google_drive_service.dart's header.
  List<GoogleDriveSpreadsheet> _driveSheets = const [];
  bool _loadingDriveSheets = false;
  String? _driveSheetsError;
  final Set<String> _selectedSheetIds = {};

  // ── google_calendar's booking-mode + pending-approval body ───────────
  //
  // Gate 4 built ConnectorEndpoint.setCalendarBookingMode/
  // listPendingBookings/approveBooking/rejectBooking, but nothing in this
  // file ever called them — the connector's modal fell through to the
  // generic oauth body, which shows nothing but "Connected." and a
  // Disconnect button for a connector with no [_oauthTargetConfig]
  // entry. An owner had no way to see or change bookingMode, and no way
  // to approve a pending booking, without a direct API call. This is
  // that missing screen.
  List<CalendarBooking> _pendingBookings = const [];
  bool _loadingPendingBookings = false;
  String? _pendingBookingsError;
  bool _bookingActionInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Fetched together — a channel connector's modal needs both to
      // render correctly on first open, and there is no reason to make
      // two round trips sequential when neither depends on the other.
      final results = await Future.wait([
        component.client.connector.listConnectors(
          component.accessToken,
          component.workspaceId,
        ),
        component.client.bot.listBotsForWorkspace(
          component.accessToken,
          component.workspaceId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _connectors = results[0] as List<ConnectorStatus>;
        _bots = results[1] as List<Bot>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Named, not swallowed. An empty marketplace and a failed fetch
      // look identical otherwise, and "my integrations disappeared" then
      // has no answer — the mistake app.dart's workspace loader made and
      // had to be corrected for.
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  // ── Derived ────────────────────────────────────────────────────────

  /// Every connector, channels included — see this file's header on why
  /// the Phase C exclusion was reversed. WhatsApp/Telegram now flow
  /// through the same search/category filtering as everything else,
  /// landing in the 'sell' category (their catalog entry never changed).
  List<ConnectorStatus> get _visible {
    final q = _search.trim().toLowerCase();
    return [
      for (final c in _connectors)
        if (_category == 'all' || c.category == _category)
          if (q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
            c,
    ];
  }

  ConnectorStatus? get _open {
    final key = _openKey;
    if (key == null) return null;
    for (final c in _connectors) {
      if (c.key == key) return c;
    }
    return null;
  }

  /// Counted over EVERYTHING, not the filtered list — a chip reading
  /// "Sell (6)" must keep saying 6 while a search narrows the grid, or
  /// it is reporting the search rather than the category. Channels are
  /// included here the same way they're included in [_visible] now.
  int _countFor(String id) {
    return id == 'all' ? _connectors.length : _connectors.where((c) => c.category == id).length;
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _openModal(ConnectorStatus c) {
    setState(() {
      _openKey = c.key;
      _submitError = null;
      _sheetUrl = '';
      _driveSheets = const [];
      _driveSheetsError = null;
      _selectedSheetIds.clear();
      _formValues
        ..clear()
        ..addEntries(c.fields.map((f) => MapEntry(f.key, '')));
      // Auto-pick the only real option; leave null for "no bot yet" (the
      // form blocks) or "more than one" (the form shows a picker).
      _selectedBotId = c.isChannel && _bots.length == 1 ? _bots.first.id : null;
    });
    if (c.key == 'google_sheets' && c.status == 'connected') {
      _loadDriveSheets(c);
    }
    if (c.key == 'google_calendar' && c.status == 'connected') {
      _pendingBookings = const [];
      _pendingBookingsError = null;
      _loadPendingBookings(c);
    }
  }

  void _closeModal() {
    setState(() {
      _openKey = null;
      _submitError = null;
      _submitting = false;
      _sheetUrl = '';
      _driveSheets = const [];
      _driveSheetsError = null;
      _selectedSheetIds.clear();
      _formValues.clear();
      _pendingBookings = const [];
      _pendingBookingsError = null;
      _selectedBotId = null;
    });
  }

  /// Which mode [c]'s connection is in right now. Read from
  /// [ConnectorStatus.displayDetail] rather than a dedicated field —
  /// ConnectorEndpoint.setCalendarBookingMode writes exactly
  /// 'Connected — $bookingMode bookings' there (see that method's own
  /// body), and adding a whole new wire field for one string felt like
  /// more surface than this needed. Unset/unrecognized displayDetail
  /// defaults to 'draft' — the same safe-by-default the SERVER already
  /// enforces in builtin_errand_executor.dart's _bookCalendarEvent.
  String _bookingMode(ConnectorStatus c) {
    final detail = c.displayDetail;
    if (detail != null && detail.contains('immediate')) return 'immediate';
    return 'draft';
  }

  Future<void> _loadPendingBookings(ConnectorStatus c) async {
    setState(() {
      _loadingPendingBookings = true;
      _pendingBookingsError = null;
    });
    try {
      final bookings = await component.client.connector.listPendingBookings(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _pendingBookings = bookings;
        _loadingPendingBookings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPendingBookings = false;
        _pendingBookingsError = ErrorText.of(e);
      });
    }
  }

  Future<void> _setBookingMode(ConnectorStatus c, String mode) async {
    if (_bookingMode(c) == mode) return; // already there, no call needed
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.setCalendarBookingMode(
        component.accessToken,
        component.workspaceId,
        mode,
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Approves [booking] — the server creates the real Google Calendar
  /// event and marks it 'booked'. Refreshes the pending list afterward
  /// rather than optimistically removing the row locally, since a
  /// same-workspace owner approving from two tabs (or the Google write
  /// itself failing) both need the SERVER's answer, not an assumed one.
  Future<void> _approveBooking(CalendarBooking booking) async {
    setState(() {
      _bookingActionInFlight = true;
      _pendingBookingsError = null;
    });
    try {
      await component.client.connector.approveBooking(
        component.accessToken,
        component.workspaceId,
        booking.id!,
      );
      if (!mounted) return;
      final refreshed = await component.client.connector.listPendingBookings(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _pendingBookings = refreshed;
        _bookingActionInFlight = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingActionInFlight = false;
        _pendingBookingsError = ErrorText.of(e);
      });
    }
  }

  Future<void> _rejectBooking(CalendarBooking booking) async {
    setState(() {
      _bookingActionInFlight = true;
      _pendingBookingsError = null;
    });
    try {
      await component.client.connector.rejectBooking(
        component.accessToken,
        component.workspaceId,
        booking.id!,
      );
      if (!mounted) return;
      setState(() {
        _pendingBookings = [
          for (final b in _pendingBookings) if (b.id != booking.id) b,
        ];
        _bookingActionInFlight = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingActionInFlight = false;
        _pendingBookingsError = ErrorText.of(e);
      });
    }
  }

  /// Connect Gate, subphase 4d — fetches the account's spreadsheets for
  /// the picker. A workspace connected before drive.metadata.readonly
  /// existed will get [ConnectorEndpoint.listGoogleSheets]'s "reconnect"
  /// KolaException here — surfaced as [_driveSheetsError] with a
  /// reconnect button, not silently as an empty list, since an empty
  /// list is also the honest state for an account with zero spreadsheets.
  Future<void> _loadDriveSheets(ConnectorStatus c) async {
    setState(() {
      _loadingDriveSheets = true;
      _driveSheetsError = null;
    });
    try {
      final sheets = await component.client.connector.listGoogleSheets(
        component.accessToken,
        component.workspaceId,
        c.key,
      );
      if (!mounted) return;
      setState(() {
        _driveSheets = sheets;
        _selectedSheetIds
          ..clear()
          ..addAll([for (final s in sheets) if (s.alreadyConnected) s.id]);
        _loadingDriveSheets = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDriveSheets = false;
        _driveSheetsError = ErrorText.of(e);
      });
    }
  }

  void _toggleSheetSelected(String id) {
    setState(() {
      if (_selectedSheetIds.contains(id)) {
        _selectedSheetIds.remove(id);
      } else {
        _selectedSheetIds.add(id);
      }
    });
  }

  /// Connect Gate, subphase 4d — saves the FULL current selection in one
  /// call (ConnectorEndpoint.setGoogleSheetTargets replaces, not appends
  /// — see that method's own doc comment), so unchecking a previously-
  /// connected sheet here actually stops it from syncing, not just skips
  /// adding new ones.
  Future<void> _saveSheetSelection(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.setGoogleSheetTargets(
        component.accessToken,
        component.workspaceId,
        c.key,
        _selectedSheetIds.toList(),
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  void _replace(ConnectorStatus updated) {
    _connectors = [
      for (final existing in _connectors)
        if (existing.key == updated.key) updated else existing,
    ];
  }

  Future<void> _submit(ConnectorStatus c) async {
    if (c.isPaymentGateway) return _submitGateway(c);
    if (c.isChannel) return _submitChannel(c);

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.connectConnector(
        component.accessToken,
        component.workspaceId,
        c.key,
        Map<String, String>.from(_formValues),
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
        _formValues.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Gate 4 — Paystack/Flutterwave submit through PaymentEndpoint
  /// .connectGateway, not ConnectorEndpoint.connectConnector, which
  /// explicitly rejects any store but generic (see that endpoint's
  /// header). Same form UI as [_submit], different call underneath —
  /// see connector_status.spy.yaml's [isPaymentGateway] doc comment.
  Future<void> _submitGateway(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final secretKey = _formValues['secretKey'] ?? '';
      final webhookSecret = _formValues['webhookSecret'];
      // Gate 11 — Monnify only; every other gateway's form (Paystack,
      // Flutterwave, Stripe, Fincra) has no 'apiKey' field (see
      // connector_catalog.dart), so this is null and ignored
      // server-side for them.
      final apiKey = _formValues['apiKey'];
      await component.client.payment.connectGateway(
        component.accessToken,
        component.workspaceId,
        c.key,
        secretKey,
        webhookSecret: (webhookSecret == null || webhookSecret.isEmpty)
            ? null
            : webhookSecret,
        apiKey: (apiKey == null || apiKey.isEmpty) ? null : apiKey,
      );
      if (!mounted) return;
      // PaymentEndpoint returns the raw credential, not a ConnectorStatus
      // — re-read through the same merge listConnectors uses so this
      // card's connected state/masked-secret stays consistent with a
      // fresh page load, same reasoning as ConnectorEndpoint's own
      // _one() helper server-side.
      final list = await component.client.connector.listConnectors(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _connectors = list;
        _openKey = null;
        _submitting = false;
        _formValues.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Dispatches a channel-store connector's form to ChannelEndpoint
  /// instead of ConnectorEndpoint.connectConnector, which explicitly
  /// rejects any store but generic (see that endpoint's own header).
  ///
  /// BEFORE THIS METHOD EXISTED: clicking "Connect" on the WhatsApp or
  /// Telegram tile always called connectConnector anyway (the only path
  /// [_submit] had), which always threw "connected through its own
  /// flow, not here" — a real, live bug. A business could fill in every
  /// field correctly and still never connect a channel from this page.
  /// GATE_INSTAGRAM_STATUS.md named this exact gap explicitly when
  /// Instagram's server side shipped without a matching UI; this is the
  /// fix, covering all three channel connectors at once rather than
  /// inventing three near-duplicate submit paths.
  ///
  /// [c.key] selects which ChannelEndpoint method to call and how to
  /// read [_formValues] — the field keys are chosen in
  /// connector_catalog.dart specifically to match each method's
  /// parameter names, so no field-name translation table is needed here.
  Future<void> _submitChannel(ConnectorStatus c) async {
    final botId = _selectedBotId;
    if (botId == null) {
      setState(() {
        _submitError = _bots.isEmpty
            ? 'Create a bot first — a channel has to belong to one.'
            : 'Choose which bot this channel belongs to.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      switch (c.key) {
        case 'whatsapp':
          await component.client.channel.connectWhatsAppChannelManual(
            component.accessToken,
            component.workspaceId,
            botId,
            _formValues['accessToken'] ?? '',
            _formValues['phoneNumberId'] ?? '',
            _formValues['wabaId'] ?? '',
            _formValues['appId'] ?? '',
            _formValues['appSecret'] ?? '',
          );
          break;
        case 'telegram':
          await component.client.channel.connectTelegramChannel(
            component.accessToken,
            component.workspaceId,
            botId,
            _formValues['botToken'] ?? '',
          );
          break;
        case 'instagram':
          await component.client.channel.connectInstagramChannelManual(
            component.accessToken,
            component.workspaceId,
            botId,
            _formValues['accessToken'] ?? '',
            _formValues['igUserId'] ?? '',
            _formValues['appSecret'] ?? '',
          );
          break;
        case 'messenger':
          await component.client.channel.connectMessengerChannelManual(
            component.accessToken,
            component.workspaceId,
            botId,
            _formValues['accessToken'] ?? '',
            _formValues['pageId'] ?? '',
            _formValues['appSecret'] ?? '',
          );
          break;
        default:
          throw KolaException(message: 'No channel connect flow wired for "${c.key}" yet.');
      }
      if (!mounted) return;
      // ChannelEndpoint returns a Channel, not a ConnectorStatus — re-read
      // through listConnectors the same way _submitGateway does, so this
      // card's merged status (isChannel's own server-side resolution)
      // stays the single source of truth rather than this file guessing
      // at what a fresh ConnectorStatus row would look like.
      final list = await component.client.connector.listConnectors(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _connectors = list;
        _openKey = null;
        _submitting = false;
        _formValues.clear();
        _selectedBotId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  Future<void> _disconnect(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      if (c.isChannel) {
        // See connector_status.spy.yaml's channelId doc comment — this
        // is the real Channel row id, resolved server-side, not
        // something this page has to look up itself.
        final channelId = c.channelId;
        if (channelId == null) {
          throw KolaException(message: 'No connected channel to disconnect.');
        }
        await component.client.channel.disconnectChannel(
          component.accessToken,
          component.workspaceId,
          channelId,
        );
        // ChannelEndpoint returns a Channel, not a ConnectorStatus — same
        // re-read-through-listConnectors reasoning as _submitChannel.
        final list = await component.client.connector.listConnectors(
          component.accessToken,
          component.workspaceId,
        );
        if (!mounted) return;
        setState(() {
          _connectors = list;
          _openKey = null;
          _submitting = false;
        });
        return;
      }

      final updated = await component.client.connector.disconnectConnector(
        component.accessToken,
        component.workspaceId,
        c.key,
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Gate 4 — starts an authType 'oauth' connector by asking the server
  /// for a consent URL, then sending the WHOLE BROWSER there via a real
  /// navigation (not fetched, not opened in a popup — every OAuth
  /// provider's consent screen must be the top-level document for its
  /// own anti-clickjacking checks to pass).
  ///
  /// FIX-PROPERLY PASS: this used to be a bare two-way ternary —
  /// `onedrive_excel` got startMicrosoftOAuth, and EVERY OTHER
  /// oauth-typed key (including the five that had no server-side flow
  /// at all) fell into startGoogleOAuth unconditionally. That's the bug
  /// reported against Instagram Shop/Facebook Catalog's Connect
  /// buttons — clicking them called Google's OAuth start method with a
  /// key Google's own scope lookup didn't recognise, which failed with
  /// a raw KolaException. [_wiredOAuthProviders] below stops that
  /// button from rendering for anything not in this switch; this switch
  /// is now the single place that has to agree with that set.
  Future<void> _startOAuth(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final url = await switch (c.key) {
        'onedrive_excel' => component.client.connector.startMicrosoftOAuth(
            component.accessToken,
            component.workspaceId,
            c.key,
          ),
        'google_sheets' ||
        'google_drive' ||
        'google_calendar' =>
          component.client.connector.startGoogleOAuth(
            component.accessToken,
            component.workspaceId,
            c.key,
          ),
        'dropbox' => component.client.connector.startDropboxOAuth(
            component.accessToken,
            component.workspaceId,
            c.key,
          ),
        'hubspot' => component.client.connector.startHubSpotOAuth(
            component.accessToken,
            component.workspaceId,
            c.key,
          ),
        'instagram_shop' ||
        'facebook_catalog' =>
          component.client.connector.startMetaOAuth(
            component.accessToken,
            component.workspaceId,
            c.key,
          ),
        _ => throw StateError(
            '${c.key} is oauth-typed but not wired into _startOAuth — '
            'should have been caught by _wiredOAuthProviders first.',
          ),
      };
      if (!mounted) return;
      // Deliberately no setState(_submitting = false) on the success
      // path — the browser is about to navigate away from this page
      // entirely, so there is no "after" for this component to render.
      web.window.location.assign(url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Gate 4 — the second step of google_sheets' oauth flow: which sheet,
  /// now that the account itself is connected. See
  /// ConnectorEndpoint.setGoogleSheetTarget's header on why this is not
  /// folded into the OAuth redirect.
  Future<void> _submitSheetTarget(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.setGoogleSheetTarget(
        component.accessToken,
        component.workspaceId,
        c.key,
        _sheetUrl.trim(),
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
        _sheetUrl = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  /// Gate 4 — the onedrive_excel twin of [_submitSheetTarget]. Same
  /// [_sheetUrl] field is reused for the input value (see that field's
  /// own doc comment — it is deliberately generic, not
  /// google-sheets-specific) but this posts to
  /// ConnectorEndpoint.setExcelFileTarget instead, which — unlike
  /// setGoogleSheetTarget — makes a real Graph call server-side to
  /// resolve the pasted link, so this can fail with a real "that link
  /// didn't resolve" error rather than only a malformed-URL one.
  Future<void> _submitFileTarget(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.setExcelFileTarget(
        component.accessToken,
        component.workspaceId,
        c.key,
        _sheetUrl.trim(),
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
        _sheetUrl = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'padding:${KolaSpace.lg};max-width:1080px;margin:0 auto;width:100%;box-sizing:border-box'},
      [
        _header(),
        if (_loading)
          _skeleton()
        else if (_loadError != null)
          _errorState()
        else ...[
          _controls(),
          if (_visible.isEmpty) _emptyState() else _grid(),
        ],
        if (_open != null) _modal(_open!),
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};color:${KolaVar.text};'
                  'font-weight:700;margin-bottom:6px',
            },
            [Component.text('Integrations')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:60ch',
            },
            [
              Component.text(
                'Connect the tools you already use. kolaa reads from them so '
                'you do not have to enter the same thing twice.',
              ),
            ],
          ),
        ],
      );

  Component _controls() => div(
        attributes: {
          'style': 'display:flex;flex-wrap:wrap;gap:${KolaSpace.smd};'
              'align-items:center;margin-bottom:${KolaSpace.md}',
        },
        [
          input<String>(
            type: InputType.search,
            attributes: {
              'aria-label': 'Search integrations',
              'placeholder': 'Search integrations',
              'name': 'integrations-filter',
              // Chrome/Firefox's address/contact autofill will happily
              // drop the signed-in owner's saved email into any plain
              // text/search input that doesn't explicitly opt out —
              // observed here specifically after clicking a card's
              // Connect button, which blurs/refocuses the DOM and gives
              // the browser's autofill heuristics a fresh chance to
              // "helpfully" fill the nearest text input on the page.
              // 'off' is the correct value per the HTML spec (some
              // browsers ignore literal 'off' for login-shaped fields,
              // but this is a plain search box, not a credential field,
              // so it isn't fighting that heuristic) — same fix already
              // applied to the oauth target-URL input further down this
              // file.
              'autocomplete': 'off',
              'style': 'flex:1 1 220px;min-width:180px;padding:9px 12px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.card};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body}',
            },
            value: _search,
            onInput: (v) => setState(() => _search = v),
          ),
          div(
            attributes: {'style': 'display:flex;flex-wrap:wrap;gap:6px'},
            [
              _chip('all', 'All'),
              _chip('sell', 'Sell'),
              _chip('pay', 'Get paid'),
              _chip('know', 'Know'),
              _chip('operate', 'Operate'),
            ],
          ),
        ],
      );

  Component _chip(String id, String label) {
    final active = _category == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:7px 13px;border-radius:${KolaRadius.pill};'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _category = id)},
      [Component.text('$label (${_countFor(id)})')],
    );
  }

  Component _grid() => div(
        attributes: {
          'style': 'display:grid;gap:${KolaSpace.smd};'
              'grid-template-columns:repeat(auto-fill,minmax(280px,1fr))',
        },
        [for (final c in _visible) _card(c)],
      );

  Component _card(ConnectorStatus c) {
    final soon = c.status == 'soon';
    return div(
      attributes: {
        // Coming-soon tiles are dimmed AND labelled. Opacity alone is not
        // a state anyone can perceive reliably, and it disappears
        // entirely in a printed report.
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
            'padding:${KolaSpace.md};display:flex;flex-direction:column;'
            'gap:10px;opacity:${soon ? '0.62' : '1'}',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            div(
              attributes: {
                'style': 'width:34px;height:34px;flex:none;'
                    'border-radius:${KolaRadius.md};'
                    'background:${KolaVar.tintSurface(_tintFor(c.category))};'
                    'color:${KolaVar.tintIcon(_tintFor(c.category))};'
                    'display:flex;align-items:center;justify-content:center',
              },
              [kolaIcon(_iconFor(c.category), size: 17)],
            ),
            div(
              attributes: {
                'style': 'flex:1;min-width:0;font-size:${KolaType.ui};'
                    'font-weight:700;color:${KolaVar.text}',
              },
              [Component.text(c.name)],
            ),
            _badge(c),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.5',
          },
          [Component.text(c.description)],
        ),
        if (c.displayDetail != null)
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.mutedStrong};'
                  'word-break:break-all',
            },
            [Component.text(c.displayDetail!)],
          ),
        if (c.lastError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                  'line-height:1.45',
            },
            [Component.text(c.lastError!)],
          ),
        div(
          attributes: {'style': 'margin-top:auto;padding-top:4px'},
          [_cardAction(c)],
        ),
      ],
    );
  }

  Component _cardAction(ConnectorStatus c) {
    if (c.status == 'soon') {
      return div(
        attributes: {
          'style': 'font-size:${KolaType.micro};font-weight:600;'
              'color:${KolaVar.muted}',
        },
        [Component.text('Coming soon')],
      );
    }
    final connected = c.status == 'connected';
    final label = switch (c.status) {
      'connected' => 'Manage',
      'error' => 'Reconnect',
      _ => 'Connect',
    };
    return button(
      attributes: {
        'type': 'button',
        'style': 'padding:8px 14px;border-radius:${KolaRadius.md};'
            'border:1px solid ${connected ? KolaVar.border : 'transparent'};'
            'background:${connected ? 'transparent' : KolaVar.accentFill};'
            'color:${connected ? KolaVar.text : KolaVar.accentText};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => _openModal(c)},
      [Component.text(label)],
    );
  }

  Component _badge(ConnectorStatus c) {
    final (tone, label) = switch (c.status) {
      'connected' => (KolaTone.positive, 'Connected'),
      'error' => (KolaTone.negative, 'Needs attention'),
      'available' => (KolaTone.neutral, 'Not connected'),
      _ => (KolaTone.neutral, 'Soon'),
    };
    return span(
      attributes: {'style': '${tone.badgeCss};flex:none;white-space:nowrap'},
      [Component.text(label)],
    );
  }

  // ── Modal ──────────────────────────────────────────────────────────

  Component _modal(ConnectorStatus c) => div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': '${c.name} setup',
          'style': 'position:fixed;inset:0;z-index:60;display:flex;'
              'align-items:center;justify-content:center;'
              'padding:${KolaSpace.md};background:rgba(0,0,0,0.55)',
        },
        events: {'click': (_) => _closeModal()},
        [
          div(
            // Stops a click inside the form from dismissing the thing
            // being typed into.
            events: {'click': (e) => e.stopPropagation()},
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:${KolaSpace.lg};'
                  'width:min(520px,100%);max-height:86vh;overflow-y:auto',
            },
            [
              div(
                attributes: {
                  'style': 'display:flex;align-items:flex-start;gap:10px;'
                      'margin-bottom:${KolaSpace.sm}',
                },
                [
                  div(attributes: {'style': 'flex:1'}, [
                    div(
                      attributes: {
                        'style': 'font-family:${KolaFonts.display};'
                            'font-size:${KolaType.title};font-weight:700;'
                            'color:${KolaVar.text};margin-bottom:4px',
                      },
                      [Component.text(c.name)],
                    ),
                    div(
                      attributes: {
                        'style': 'font-size:${KolaType.small};'
                            'color:${KolaVar.muted};line-height:1.5',
                      },
                      [Component.text(c.description)],
                    ),
                  ]),
                  button(
                    attributes: {
                      'type': 'button',
                      'aria-label': 'Close',
                      'style': 'background:transparent;border:none;'
                          'color:${KolaVar.muted};cursor:pointer;'
                          'display:flex;padding:4px;line-height:1',
                    },
                    events: {'click': (_) => _closeModal()},
                    [kolaIcon(Icons.close, size: 17)],
                  ),
                ],
              ),
              ..._modalBody(c),
            ],
          ),
        ],
      );

  List<Component> _modalBody(ConnectorStatus c) => switch (c.authType) {
        'fields' || 'whatsapp' => _formBody(c),
        'manage' => _manageBody(c),
        'oauth' => _oauthBody(c),
        'keydisplay' => _notYet(
            'This works by giving you a kolaa API key to paste into '
            '${c.name}. The public API that key would open does not exist '
            'yet, so kolaa will not hand out one that cannot work.',
          ),
        _ => _notYet('This connector cannot be set up here yet.'),
      };

  List<Component> _formBody(ConnectorStatus c) => [
        if (c.authType == 'whatsapp')
          _note('WhatsApp needs five values from your Meta app — all five '
              'are credentials Meta issues you, copied exactly as shown in '
              'your App Dashboard.'),
        if (c.helpText.isNotEmpty) _note(c.helpText),
        if (c.isChannel) ..._botPicker(),
        for (final f in c.fields) _field(f),
        if (_submitError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5;margin-top:10px',
            },
            [Component.text(_submitError!)],
          ),
        div(
          attributes: {
            'style': 'display:flex;gap:8px;margin-top:${KolaSpace.md}',
          },
          [
            button(
              attributes: {
                'type': 'button',
                if (_submitting) 'disabled': 'disabled',
                'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;'
                    'cursor:${_submitting ? 'default' : 'pointer'};'
                    'opacity:${_submitting ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (!_submitting) _submit(c);
                },
              },
              [Component.text(_submitting ? 'Connecting…' : 'Connect')],
            ),
            // Gate 4 — payment gateway credentials have no disconnect
            // flow (only create-or-replace/rotate — see
            // payment_gateway_credential_repository.dart's own upsert
            // doc comment). ConnectorEndpoint.disconnectConnector would
            // reject this store outright; hiding the button here is
            // honest about what actually exists rather than showing an
            // action that always fails.
            //
            // Channels DO have a real disconnect path now (2026-08-31) —
            // ChannelEndpoint.disconnectChannel, dispatched from
            // [_disconnect] via c.isChannel/c.channelId. Only payment
            // gateways stay excluded, per the comment above.
            if (!c.isPaymentGateway &&
                (c.status == 'connected' || c.status == 'error'))
              button(
                attributes: {
                  'type': 'button',
                  if (_submitting) 'disabled': 'disabled',
                  'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                      'border:1px solid ${KolaVar.border};'
                      'background:transparent;color:${KolaVar.danger};'
                      'font-family:inherit;font-size:${KolaType.body};'
                      'font-weight:600;cursor:pointer',
                },
                events: {
                  'click': (_) {
                    if (!_submitting) _disconnect(c);
                  },
                },
                [Component.text('Disconnect')],
              ),
          ],
        ),
      ];

  List<Component> _manageBody(ConnectorStatus c) => [
        _note('${c.name} is set up in your billing settings, so kolaa keeps '
            'one copy of those details rather than two that can disagree.'),
        if (c.displayDetail != null)
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                  'margin-bottom:${KolaSpace.sm};word-break:break-all',
            },
            [Component.text(c.displayDetail!)],
          ),
        Link(
          to: c.manageRoute ?? '/billing',
          attributes: {
            'style': 'display:inline-block;padding:10px 16px;'
                'border-radius:${KolaRadius.md};'
                'background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-size:${KolaType.body};'
                'font-weight:600;text-decoration:none',
          },
          children: [Component.text('Open settings')],
        ),
      ];

  /// Per-connector labels for [_oauthBody]'s target-picking step. Only
  /// two entries today (google_sheets, onedrive_excel) — an oauth
  /// connector NOT in this map has no second step at all (Drive,
  /// Calendar, Slack, HubSpot as each is built), and [_oauthBody]'s
  /// else-branch already renders correctly for that case without
  /// consulting this map.
  ///
  /// google_sheets' sentinel/label/placeholder are now UNUSED —
  /// _oauthBody branches to [_googleSheetsPickerBody] for that key
  /// before ever consulting them (Connect Gate, subphase 4d) — kept
  /// only because `connectLabel` still drives the not-yet-connected
  /// button's text, and splitting one field out into its own map felt
  /// like more churn than it was worth for three dead fields.
  /// The oauth-typed connectors with a real provider flow wired
  /// server-side — see ConnectorEndpoint's `_googleScopesFor`/
  /// `_microsoftScopesFor`/`_metaScopesFor` switches (Dropbox and
  /// HubSpot need no per-connector scope lookup — one fixed scope/app
  /// each) and [_startOAuth]'s own switch, which must agree with this
  /// set exactly.
  ///
  /// FIX-PROPERLY PASS STATUS: originally FIVE connectors were marked
  /// `ConnectorAuth.oauth` with no server-side flow at all (instagram_
  /// shop, facebook_catalog, dropbox, hubspot, slack) — clicking their
  /// Connect button called startGoogleOAuth unconditionally and failed
  /// with a raw KolaException, which this file's own header already
  /// said the design shouldn't allow: "A connect button that fails
  /// silently is worse than one that says why it cannot work yet."
  /// Slack turned out not to need an entry here at all — it was never
  /// really OAuth; see connector_catalog.dart's slack entry (now
  /// `ConnectorAuth.manage`, pointing at the Settings page's existing,
  /// already-working Incoming Webhook form instead of a second, BYO
  /// -webhook Slack App that this codebase never had). The remaining
  /// four now have real flows below. [_oauthBody] checks this set
  /// before ever rendering the Connect button — see its own body.
  static const _wiredOAuthProviders = {
    'google_sheets',
    'google_drive',
    'google_calendar',
    'onedrive_excel',
    'dropbox',
    'hubspot',
    'instagram_shop',
    'facebook_catalog',
  };

  static const _oauthTargetConfig = <String, ({
    String sentinel,
    String label,
    String placeholder,
    String connectLabel,
  })>{
    'google_sheets': (
      sentinel: 'Signed in — choose a sheet',
      label: 'Sheet URL',
      placeholder: 'https://docs.google.com/spreadsheets/d/…',
      connectLabel: 'Connect with Google',
    ),
    'onedrive_excel': (
      sentinel: 'Signed in — choose a file',
      label: 'Excel file link',
      placeholder: 'https://onedrive.live.com/… or a SharePoint link',
      connectLabel: 'Connect with Microsoft',
    ),
  };

  /// Gate 4 — authType 'oauth'. Three states, not two:
  ///   not connected             → "Connect with Google/Microsoft" button
  ///   connected, no target yet  → paste-a-link field (displayDetail ==
  ///                               the exact sentinel the matching
  ///                               callback route writes — see
  ///                               GoogleOAuthCallbackRoute/
  ///                               MicrosoftOAuthCallbackRoute's own
  ///                               comments on why no target is chosen
  ///                               during the redirect itself)
  ///   connected, target chosen  → current target + a field to change it
  ///
  /// [_oauthTargetConfig] is what makes this ONE method for both
  /// providers rather than a second near-identical copy — everything
  /// provider-specific is a label lookup, everything else (states,
  /// submit-error rendering, disconnect) is shared.
  List<Component> _oauthBody(ConnectorStatus c) {
    final target = _oauthTargetConfig[c.key];

    if (c.status != 'connected') {
      if (!_wiredOAuthProviders.contains(c.key)) {
        // See _wiredOAuthProviders' own doc comment. Honest, not broken:
        // no button that would just redirect into a server error.
        return [
          _note(
            "${c.name}'s connect flow isn't wired up in kolaa yet — this "
            "tile is here so you know it's coming, not so you can connect "
            'it today.',
          ),
        ];
      }
      return [
        if (c.helpText.isNotEmpty) _note(c.helpText),
        if (_submitError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5;margin-bottom:${KolaSpace.sm}',
            },
            [Component.text(_submitError!)],
          ),
        button(
          attributes: {
            'type': 'button',
            if (_submitting) 'disabled': 'disabled',
            'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                'border:none;background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-family:inherit;'
                'font-size:${KolaType.body};font-weight:600;'
                'cursor:${_submitting ? 'default' : 'pointer'};'
                'opacity:${_submitting ? '0.65' : '1'}',
          },
          events: {
            'click': (_) {
              if (!_submitting) _startOAuth(c);
            },
          },
          [Component.text(_submitting ? 'Redirecting…' : (target?.connectLabel ?? 'Connect'))],
        ),
      ];
    }

    // Connect Gate, subphase 4d — google_sheets gets a picker instead of
    // the generic paste-a-link body below. onedrive_excel (and any
    // future oauth connector without Drive-style listing) falls through
    // to the unchanged generic body.
    if (c.key == 'google_sheets') {
      return _googleSheetsPickerBody(c);
    }

    if (c.key == 'google_calendar') {
      return _calendarBookingModeBody(c);
    }

    final needsTarget = target != null && c.displayDetail == target.sentinel;

    return [
      _note(needsTarget
          ? 'Signed in. Paste the link to the ${target.label.toLowerCase()} '
              '${c.name} should read — open it in your browser and copy '
              'the address bar.'
          : target != null
              ? 'Connected. Paste a different link below to point '
                  '${c.name} somewhere else.'
              : 'Connected.'),
      if (c.displayDetail != null && !needsTarget)
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.mono};'
                'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                'margin-bottom:${KolaSpace.sm};word-break:break-all',
          },
          [Component.text(c.displayDetail!)],
        ),
      if (target != null)
        label(
          attributes: {'style': 'display:block;margin-bottom:10px'},
          [
            span(
              attributes: {
                'style': 'display:block;font-size:${KolaType.small};'
                    'font-weight:600;color:${KolaVar.mutedStrong};'
                    'margin-bottom:4px',
              },
              [Component.text(target.label)],
            ),
            input<String>(
              type: InputType.text,
              attributes: {
                'placeholder': target.placeholder,
                'autocomplete': 'off',
                'style': 'width:100%;box-sizing:border-box;padding:9px 12px;'
                    'border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.bg};color:${KolaVar.text};'
                    'font-size:${KolaType.body}',
              },
              value: _sheetUrl,
              onInput: (v) => _sheetUrl = v,
            ),
          ],
        ),
      if (_submitError != null)
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                'line-height:1.5;margin-top:10px',
          },
          [Component.text(_submitError!)],
        ),
      div(
        attributes: {
          'style': 'display:flex;gap:8px;margin-top:${KolaSpace.md}',
        },
        [
          if (target != null)
            button(
              attributes: {
                'type': 'button',
                if (_submitting || _sheetUrl.trim().isEmpty) 'disabled': 'disabled',
                'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;'
                    'cursor:${_submitting ? 'default' : 'pointer'};'
                    'opacity:${(_submitting || _sheetUrl.trim().isEmpty) ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (_submitting || _sheetUrl.trim().isEmpty) return;
                  // Only onedrive_excel reaches this generic paste-link
                  // body now — google_sheets branches to
                  // _googleSheetsPickerBody before this point. Kept as
                  // an explicit key check rather than an unconditional
                  // call so a future third paste-link oauth connector
                  // fails loud here instead of silently misrouting.
                  if (c.key == 'onedrive_excel') {
                    _submitFileTarget(c);
                  } else {
                    _submitSheetTarget(c);
                  }
                },
              },
              [Component.text(_submitting ? 'Saving…' : 'Save')],
            ),
          button(
            attributes: {
              'type': 'button',
              if (_submitting) 'disabled': 'disabled',
              'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:transparent;color:${KolaVar.danger};'
                  'font-family:inherit;font-size:${KolaType.body};'
                  'font-weight:600;cursor:pointer',
            },
            events: {
              'click': (_) {
                if (!_submitting) _disconnect(c);
              },
            },
            [Component.text('Disconnect')],
          ),
        ],
      ),
    ];
  }

  /// Connect Gate, subphase 4d — google_sheets' connected-state body.
  /// Replaces the old "paste a link" step: the account already grants
  /// read access to every sheet it can see (spreadsheets.readonly is
  /// account-wide), so this just needs to show what's THERE and let the
  /// owner pick as many as they want, instead of asking them to go find
  /// and copy a URL. See _loadDriveSheets/_saveSheetSelection above.
  List<Component> _googleSheetsPickerBody(ConnectorStatus c) {
    if (_loadingDriveSheets) {
      return [_note('Loading your spreadsheets…')];
    }

    if (_driveSheetsError != null) {
      return [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                'line-height:1.5;margin-bottom:${KolaSpace.sm}',
          },
          [Component.text(_driveSheetsError!)],
        ),
        div(
          attributes: {'style': 'display:flex;gap:8px'},
          [
            button(
              attributes: {
                'type': 'button',
                'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;cursor:pointer',
              },
              events: {'click': (_) => _startOAuth(c)},
              [Component.text('Reconnect with Google')],
            ),
            button(
              attributes: {
                'type': 'button',
                'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:transparent;color:${KolaVar.danger};'
                    'font-family:inherit;font-size:${KolaType.body};'
                    'font-weight:600;cursor:pointer',
              },
              events: {'click': (_) => _disconnect(c)},
              [Component.text('Disconnect')],
            ),
          ],
        ),
      ];
    }

    return [
      _note(_driveSheets.isEmpty
          ? "Signed in, but kolaa didn't find any spreadsheets in this "
              'Google account. Create one, then reopen this to pick it.'
          : 'Signed in. Pick which of your spreadsheets ${c.name} should '
              'read — you can select more than one.'),
      if (_driveSheets.isNotEmpty)
        div(
          attributes: {
            'style': 'max-height:260px;overflow-y:auto;'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};margin-bottom:${KolaSpace.sm}',
          },
          [
            for (final sheet in _driveSheets) _sheetRow(sheet),
          ],
        ),
      if (_submitError != null)
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                'line-height:1.5;margin-top:10px',
          },
          [Component.text(_submitError!)],
        ),
      div(
        attributes: {
          'style': 'display:flex;gap:8px;margin-top:${KolaSpace.md}',
        },
        [
          button(
            attributes: {
              'type': 'button',
              if (_submitting) 'disabled': 'disabled',
              'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;'
                  'cursor:${_submitting ? 'default' : 'pointer'};'
                  'opacity:${_submitting ? '0.65' : '1'}',
            },
            events: {
              'click': (_) {
                if (!_submitting) _saveSheetSelection(c);
              },
            },
            [
              Component.text(_submitting
                  ? 'Saving…'
                  : _selectedSheetIds.isEmpty
                      ? 'Save (sync nothing)'
                      : 'Save (${_selectedSheetIds.length} selected)'),
            ],
          ),
          button(
            attributes: {
              'type': 'button',
              if (_submitting) 'disabled': 'disabled',
              'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:transparent;color:${KolaVar.danger};'
                  'font-family:inherit;font-size:${KolaType.body};'
                  'font-weight:600;cursor:pointer',
            },
            events: {
              'click': (_) {
                if (!_submitting) _disconnect(c);
              },
            },
            [Component.text('Disconnect')],
          ),
        ],
      ),
    ];
  }

  /// google_calendar's connected-state body: a Draft/Immediate mode
  /// toggle plus the list of bookings still waiting on an owner's yes/no
  /// (draft mode only — immediate mode never accumulates any). See this
  /// file's header note above [_pendingBookings] for why this exists.
  List<Component> _calendarBookingModeBody(ConnectorStatus c) {
    final mode = _bookingMode(c);
    return [
      _note('Choose how kola handles a booking it proposes. Immediate '
          'writes straight to your Google Calendar; draft holds it here '
          'first so you can approve or reject it.'),
      div(
        attributes: {'style': 'display:flex;gap:8px;margin-bottom:${KolaSpace.md}'},
        [
          _modeButton(c, mode, 'draft', 'Draft — needs approval'),
          _modeButton(c, mode, 'immediate', 'Immediate — books instantly'),
        ],
      ),
      if (_submitError != null)
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                'line-height:1.5;margin-bottom:${KolaSpace.sm}',
          },
          [Component.text(_submitError!)],
        ),
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};font-weight:600;'
              'color:${KolaVar.mutedStrong};margin-bottom:8px',
        },
        [Component.text('Pending approval')],
      ),
      if (_loadingPendingBookings)
        _note('Loading pending bookings…')
      else if (_pendingBookingsError != null)
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                'line-height:1.5;margin-bottom:${KolaSpace.sm}',
          },
          [Component.text(_pendingBookingsError!)],
        )
      else if (_pendingBookings.isEmpty)
        _note('Nothing waiting on you right now.')
      else
        div(
          attributes: {
            'style': 'max-height:260px;overflow-y:auto;'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};margin-bottom:${KolaSpace.sm}',
          },
          [for (final b in _pendingBookings) _pendingBookingRow(b)],
        ),
      div(
        attributes: {'style': 'display:flex;gap:8px;margin-top:${KolaSpace.md}'},
        [
          button(
            attributes: {
              'type': 'button',
              if (_submitting) 'disabled': 'disabled',
              'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:transparent;color:${KolaVar.danger};'
                  'font-family:inherit;font-size:${KolaType.body};'
                  'font-weight:600;cursor:pointer',
            },
            events: {
              'click': (_) {
                if (!_submitting) _disconnect(c);
              },
            },
            [Component.text('Disconnect')],
          ),
        ],
      ),
    ];
  }

  Component _modeButton(ConnectorStatus c, String currentMode, String mode, String label) {
    final active = currentMode == mode;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        if (_submitting) 'disabled': 'disabled',
        'style': 'flex:1;padding:10px 14px;border-radius:${KolaRadius.md};'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:${_submitting ? 'default' : 'pointer'};'
            'opacity:${_submitting ? '0.65' : '1'}',
      },
      events: {
        'click': (_) {
          if (!_submitting) _setBookingMode(c, mode);
        },
      },
      [Component.text(label)],
    );
  }

  /// One row in the pending-bookings list — title, when, and who it's
  /// for, plus Approve/Reject. No checkbox/select-state to manage (unlike
  /// [_sheetRow]) since each row acts immediately on its own booking.
  Component _pendingBookingRow(CalendarBooking b) {
    final when = '${_fmtDate(b.startsAt)} – ${_fmtDate(b.endsAt)}';
    final who = [
      if (b.attendeeName != null && b.attendeeName!.isNotEmpty) b.attendeeName,
      if (b.attendeeEmail != null && b.attendeeEmail!.isNotEmpty) b.attendeeEmail,
    ].whereType<String>().join(' · ');
    return div(
      attributes: {
        'style': 'padding:10px 12px;border-bottom:1px solid ${KolaVar.border};'
            'display:flex;flex-direction:column;gap:4px',
      },
      [
        span(
          attributes: {
            'style': 'font-size:${KolaType.body};font-weight:600;'
                'color:${KolaVar.text}',
          },
          [Component.text(b.title)],
        ),
        span(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.mutedStrong}',
          },
          [Component.text(who.isEmpty ? when : '$when · $who')],
        ),
        div(
          attributes: {'style': 'display:flex;gap:8px;margin-top:4px'},
          [
            button(
              attributes: {
                'type': 'button',
                if (_bookingActionInFlight) 'disabled': 'disabled',
                'style': 'padding:6px 12px;border-radius:${KolaRadius.sm};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.small};font-weight:600;'
                    'cursor:${_bookingActionInFlight ? 'default' : 'pointer'};'
                    'opacity:${_bookingActionInFlight ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (!_bookingActionInFlight) _approveBooking(b);
                },
              },
              [Component.text('Approve')],
            ),
            button(
              attributes: {
                'type': 'button',
                if (_bookingActionInFlight) 'disabled': 'disabled',
                'style': 'padding:6px 12px;border-radius:${KolaRadius.sm};'
                    'border:1px solid ${KolaVar.border};'
                    'background:transparent;color:${KolaVar.danger};'
                    'font-family:inherit;font-size:${KolaType.small};'
                    'font-weight:600;cursor:${_bookingActionInFlight ? 'default' : 'pointer'}',
              },
              events: {
                'click': (_) {
                  if (!_bookingActionInFlight) _rejectBooking(b);
                },
              },
              [Component.text('Reject')],
            ),
          ],
        ),
      ],
    );
  }

  /// Plain, timezone-naive local formatting — this modal is a quick
  /// glance at "what's waiting on me," not a full scheduling UI. Good
  /// enough to recognize which booking is which; a real calendar view is
  /// a bigger, separate piece of work if this ever needs one.
  String _fmtDate(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $h:$min $period';
  }

  /// One row in [_googleSheetsPickerBody]'s list — a button-based toggle,
  /// not `<input type="checkbox">`. See _eventCheckbox in
  /// api_webhooks_page.dart for why: InputType.checkbox is a documented
  /// landmine in this codebase (media_upload.dart's header — "analysed
  /// clean and failed" at runtime once already). Same shape reused here:
  /// a full-row button, aria-pressed, a small square that fills in when
  /// selected.
  Component _sheetRow(GoogleDriveSpreadsheet sheet) {
    final checked = _selectedSheetIds.contains(sheet.id);
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:8px;'
            'border-bottom:1px solid ${KolaVar.border}',
      },
      [
        button(
          attributes: {
            'type': 'button',
            'aria-pressed': checked ? 'true' : 'false',
            'style': 'flex:1;display:flex;align-items:center;gap:10px;'
                'background:transparent;border:none;padding:10px 12px;'
                'font-family:inherit;font-size:${KolaType.body};'
                'color:${KolaVar.text};cursor:pointer;text-align:left;'
                'min-width:0',
          },
          events: {
            'click': (_) => _toggleSheetSelected(sheet.id),
          },
          [
            div(
              attributes: {
                'style': 'width:16px;height:16px;flex:none;'
                    'border-radius:4px;'
                    'border:1px solid ${checked ? KolaVar.accent : KolaVar.border};'
                    'background:${checked ? KolaVar.accentFill : 'transparent'};'
                    'color:${KolaVar.accentText};'
                    'display:flex;align-items:center;justify-content:center',
              },
              [if (checked) kolaIcon(Icons.check, size: 11, strokeWidth: 3)],
            ),
            span(
              attributes: {
                'style': 'flex:1;overflow:hidden;text-overflow:ellipsis;'
                    'white-space:nowrap;min-width:0',
              },
              [Component.text(sheet.name)],
            ),
          ],
        ),
        if (sheet.webViewLink != null)
          a(
            href: sheet.webViewLink!,
            attributes: {
              'target': '_blank',
              'rel': 'noopener noreferrer',
              'style': 'flex:none;padding:0 12px;font-size:${KolaType.small};'
                  'color:${KolaVar.mutedStrong};text-decoration:none',
            },
            [Component.text('Open ↗')],
          ),
      ],
    );
  }

  List<Component> _notYet(String explanation) => [
        _note(explanation),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55',
          },
          [
            Component.text('Nothing is broken — this part simply is not '
                'finished. It will appear here when it is.'),
          ],
        ),
      ];

  Component _note(String message) => div(
        attributes: {
          'style': 'background:${KolaVar.pill};'
              'border-radius:${KolaRadius.md};padding:10px 12px;'
              'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
              'line-height:1.55;margin-bottom:${KolaSpace.sm}',
        },
        [Component.text(message)],
      );

  Component _field(ConnectorFieldSpec f) => label(
        attributes: {'style': 'display:block;margin-bottom:10px'},
        [
          span(
            attributes: {
              'style': 'display:block;font-size:${KolaType.small};'
                  'font-weight:600;color:${KolaVar.mutedStrong};'
                  'margin-bottom:4px',
            },
            [Component.text(f.label)],
          ),
          input<String>(
            type: f.secret ? InputType.password : InputType.text,
            attributes: {
              'placeholder': f.placeholder,
              'autocomplete': 'off',
              'style': 'width:100%;box-sizing:border-box;padding:9px 12px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:${f.secret ? KolaFonts.mono : 'inherit'};'
                  'font-size:${KolaType.body}',
            },
            value: _formValues[f.key] ?? '',
            // Deliberately NOT setState: rebuilding on every keystroke
            // would reset the caret in every other field on the form.
            // The map is read on submit.
            onInput: (v) => _formValues[f.key] = v,
          ),
        ],
      );

  /// Which bot a channel connector's credentials attach to — Channel
  /// .botId is a real foreign key, not optional, so this has to be asked
  /// somewhere. Renders nothing when there is exactly one bot ([_openModal]
  /// already auto-selected it); otherwise a picker (2+ bots) or a
  /// blocking "create a bot first" message (0 bots) — see
  /// [_submitChannel]'s header for why this can't just default to
  /// nothing and let the server 404.
  List<Component> _botPicker() {
    if (_bots.isEmpty) {
      return [
        _note('You need a bot before you can connect a channel to it. '
            'Create one from the Home page, then come back here.'),
      ];
    }
    if (_bots.length == 1) return const [];

    return [
      label(
        attributes: {'style': 'display:block;margin-bottom:10px'},
        [
          span(
            attributes: {
              'style': 'display:block;font-size:${KolaType.small};'
                  'font-weight:600;color:${KolaVar.mutedStrong};'
                  'margin-bottom:4px',
            },
            [Component.text('Which bot?')],
          ),
          select(
            [
              option(
                [Component.text('Choose a bot…')],
                value: '',
                selected: _selectedBotId == null,
              ),
              for (final b in _bots)
                option(
                  [Component.text(b.name)],
                  value: b.id.toString(),
                  selected: b.id == _selectedBotId,
                ),
            ],
            value: _selectedBotId?.toString(),
            onChange: (values) {
              final picked = values.isEmpty ? null : int.tryParse(values.first);
              setState(() => _selectedBotId = picked);
            },
            attributes: {
              'style': 'width:100%;box-sizing:border-box;padding:9px 12px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body}',
            },
          ),
        ],
      ),
    ];
  }

  // ── States ─────────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {
          'style': 'display:grid;gap:${KolaSpace.smd};'
              'grid-template-columns:repeat(auto-fill,minmax(280px,1fr))',
        },
        [
          for (var i = 0; i < 6; i++)
            div(
              attributes: {
                'style': 'height:150px;border-radius:${KolaRadius.lg};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.card}',
              },
              const [],
            ),
        ],
      );

  Component _errorState() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load your integrations')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:12px',
            },
            [
              Component.text('This is a connection problem, not a sign that '
                  'anything was disconnected. Your existing integrations are '
                  'untouched.'),
            ],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'margin-bottom:12px;word-break:break-word',
            },
            [Component.text(_loadError ?? '')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:9px 15px;border-radius:${KolaRadius.md};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  Component _emptyState() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:${KolaSpace.lg};'
              'text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Nothing matches that')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [
              Component.text('Try a different word, or clear the category '
                  'filter.'),
            ],
          ),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────

  /// Fixed category → tint mapping rather than index-modulo, so a
  /// category keeps its colour when another is added.
  int _tintFor(String category) => switch (category) {
        'pay' => 0,
        'sell' => 1,
        'know' => 2,
        _ => 3,
      };

  String _iconFor(String category) => switch (category) {
        'sell' => Icons.catalog,
        'pay' => Icons.billing,
        'know' => Icons.book,
        _ => Icons.workflow,
      };
}
