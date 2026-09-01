// till_page.dart — the sales counter. PART II's gap table: "Sales
// counter PARTIAL. Migration 035 applied. Model, endpoint and Till page
// outstanding." Gate 3b: every completed sale resolves/creates a
// Customer via CustomerIdentityResolver and immediately shows up on
// that customer's page (customers_page.dart).
//
// ── BUILT FROM Kola Till.dc.html, NOT COPIED FROM IT ────────────────────
//
// The export is a design tool's illustration of layout and states —
// not a spec to reproduce verbatim, dummy content included. This page
// keeps the export's real structure (a Sell → Payment → Receipt screen
// flow, category chips, a barcode-scanner modal) and its visual
// language (this codebase's own KolaVar/KolaType/KolaRadius tokens,
// same rule every rebuilt page follows), but treats everything else in
// the export as a hint about what a state should look like, not literal
// content or literal mechanics to carry over:
//
//   - REAL product photos where the catalog has one (ProductMedia, the
//     exact listMediaForProducts/position-0-is-main approach
//     catalog_page.dart already uses), the placeholder icon only when a
//     product genuinely has none — never the export's icon-for-every-
//     product treatment.
//   - REAL responsive layout, driven by the actual viewport (see
//     `_view`, kept in sync with a resize listener) — not the export's
//     manual Phone/Tablet toggle. That toggle is how a design tool lets
//     someone preview both states in one static file; it has no reason
//     to exist in a shipped app, where the till just fits whatever
//     screen it's actually running on. A cashier on a desktop should
//     never see a button offering to pretend the desktop is a phone.
//   - Independent scroll regions with a pinned totals/Charge footer —
//     see _sellRail's and _phoneBody's own comments for the exact bug
//     this fixes (the button drifting down the page as the cart grew).
//
// ── WHERE THIS DELIBERATELY DEVIATES FROM THE EXPORT, AND WHY ─────────
//
// 1. OFFLINE QUEUE — BUILT, Phase 11g (2026-08-31), not the gap this
//    note used to describe. A sale charged while offline (or while a
//    request transport-fails — see ErrorText.isOffline) is written to
//    `OfflineSaleQueue` (local storage, Phase 11g-b) instead of lost,
//    shown as a visibly-marked "queued" receipt (`_CompletedSale
//    .queued`), and drained automatically once reconnected via the same
//    idempotent `clientReference` ringUpSale already accepted before
//    anything here sent one (`_drainQueue`, Phase 11g-d). The four
//    connection states, the "N sales waiting to sync" banner, last-known
//    catalog browsing while offline, and stock-conflict resolution for
//    two tills selling the same last unit are all real too — see
//    docs/DEVELOPMENT_PLAN.md's Phase 11g section for the full build and
//    its named, still-open gap (background sync only runs while this
//    page itself is open — closing the tab pauses draining, doesn't
//    lose anything).
//
// 2. BARCODE SCANNER. The export's own "scan" button does not decode a
//    real camera feed either — its click handler is a hardcoded
//    `simulateScan` that always adds "Red Ankara". Building a live
//    camera+decoder is a real feature (getUserMedia permission flow, a
//    barcode-decoding library this project does not depend on). This
//    page keeps the export's modal frame exactly, but replaces the fake
//    "sample scan" button with a real text field matched against each
//    product's own SKU — which also means a real handheld barcode
//    scanner (these type digits + Enter like a keyboard) works today by
//    just being pointed at this field.
//
// 3. CUSTOMER CAPTURE IS OPTIONAL, NOT ABSENT — updated Phase 14a-3.
//    The export's payment screen has none at all; this page now has an
//    optional name field at charge time (`_customerNameField`) and an
//    optional phone prompt before a WhatsApp send
//    (`_whatsAppPromptModal`), both because the owner asked for them —
//    but a walk-in sale with no phone/name typed in either is still a
//    complete, normal sale (sale.spy.yaml's own header) with no error,
//    no required field, and no personalized receipt line. Customer
//    identity from the till is still Gate 3b's job, not this screen's
//    — these two fields feed it (SaleEndpoint.ringUpSale's own
//    customerPhone/customerName resolve through CustomerIdentity
//    Resolver same as before) rather than replacing it.
//
// ── SAME SHAPE AS OTHER PAGES ON THIS DESIGN SYSTEM ────────────────────
//
// Product search reuses ProductEndpoint.listProducts (already built for
// catalog_page.dart). Checkout is one call to SaleEndpoint.ringUpSale;
// the receipt is rendered from what that call returns plus the cart
// snapshot taken right before it clears, never guessed.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' show max;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../components/shell/mobile_chrome.dart';
import '../components/shell/page_help_button.dart';
import '../services/camera_scanner.dart';
import '../services/error_text.dart';
import '../services/feature_gate.dart';
import '../services/imagekit_url.dart';
import '../services/money_format.dart';
import '../services/offline_catalog_cache.dart';
import '../services/offline_sale_queue.dart';
import '../theme.dart';

class _CartLine {
  _CartLine({required this.product, required this.unitPriceMinor, this.quantity = 1});

  final Product product;

  /// Set once, at the moment the line is added — from the catalog price
  /// when the product has one, or from what the cashier typed for an
  /// "Ask price" item (see `_addToCart`/`_priceEntryModal`). Never
  /// re-read from `product.priceMinor` after that: a variable-priced
  /// service can legitimately sell for a different amount next time,
  /// and this line must keep showing what THIS sale actually charged.
  final int unitPriceMinor;
  int quantity;

  int get lineTotalMinor => unitPriceMinor * quantity;
}

/// A snapshot taken the instant a sale completes — the cart is about to
/// be cleared, and the receipt screen (here and on Documents) must keep
/// showing what was actually sold, not whatever the cart holds later.
class _CompletedSale {
  _CompletedSale({
    required this.sale,
    required this.lines,
    required this.paidLabel,
    this.customerName,
    this.queued = false,
  });

  final Sale sale;
  final List<_CartLine> lines;
  final String paidLabel;

  /// Phase 14a-3. Null/blank when the cashier left the name field empty
  /// at charge time — a walk-in sale with no name is a complete, normal
  /// sale (see `_customerName`'s own field comment), and the receipt
  /// below simply omits its personalized thank-you line rather than
  /// printing "Thank you, , for shopping with us."
  final String? customerName;

  /// Phase 11g-c. True when this sale exists only in the local offline
  /// queue (`OfflineSaleQueue`) and has not reached the server yet —
  /// [sale] is a client-built snapshot (`id` null, `reference` is the
  /// queue's own `clientReference`) rather than the row `ringUpSale`
  /// would have returned. The receipt still renders fully — the brief's
  /// "print or share a receipt" must keep working offline — but visibly
  /// marked, never presented as if it were confirmed.
  final bool queued;
}

class TillPage extends StatefulComponent {
  const TillPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaceName,
    required this.taxRateBps,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final String workspaceName;

  /// Only for the mobile bottom tab bar this page now carries — see
  /// `_mobileTabBar`'s header on why this page needs one of its own
  /// rather than being wrapped in AppShell.
  final FeatureGate gate;

  /// The workspace's real VAT rate (basis points). The export hardcodes
  /// "VAT (7.5%)" as a label; this page computes the actual tax the
  /// server will charge (SaleEndpoint.ringUpSale reads the same field),
  /// which is 0 for the many shops that are not VAT-registered — see
  /// migration 035's own header on why 7.5% is not a safe default.
  final int taxRateBps;

  @override
  State<TillPage> createState() => _TillPageState();
}

enum _Screen { sell, payment, receipt }

/// Phase 11g-c. DESIGN_BRIEF_COMMERCE.md §1's own four named states —
/// see `_TillPageState._connStatus`.
enum _ConnStatus { online, offlineWorking, syncing, syncProblem }

extension on _ConnStatus {
  String get label => switch (this) {
        _ConnStatus.online => 'Online',
        _ConnStatus.offlineWorking => 'Offline, working',
        _ConnStatus.syncing => 'Syncing',
        _ConnStatus.syncProblem => 'Sync problem',
      };

  /// A calm dot colour per state — success/warning/accent/danger, never
  /// red for the expected "offline, working" state. The brief is
  /// explicit: "Not a red alert — offline is expected."
  String get dotColor => switch (this) {
        _ConnStatus.online => KolaVar.success,
        _ConnStatus.offlineWorking => KolaVar.warning,
        _ConnStatus.syncing => KolaVar.accent,
        _ConnStatus.syncProblem => KolaVar.danger,
      };
}

class _TillPageState extends State<TillPage> {
  List<Product> _products = const [];
  Map<int, ProductMedia> _mainImages = const {};
  bool _loading = true;
  String? _loadError;

  /// Phase 11g-f. Non-null exactly when `_products` is currently showing
  /// `OfflineCatalogCache`'s last-known snapshot rather than a live
  /// fetch — see `_catalogStalenessNotice`'s own header for where this
  /// is shown and DESIGN_BRIEF_COMMERCE.md §1 for why it must never be
  /// silent about being stale.
  DateTime? _catalogAsOf;

  /// Driven by the real viewport, not a manual switch — see the file
  /// header. Updated live on resize, same convention app_shell.dart
  /// already uses for its own listeners.
  String _view = 'tablet';
  _Screen _screen = _Screen.sell;

  String _search = '';
  String? _category;

  final List<_CartLine> _cart = [];

  /// Mobile only — see `_phoneCartSheet`'s header for the bug this
  /// fixes. Reset to false whenever the sell screen is left/reset so a
  /// stale open sheet never reappears over a fresh sale.
  bool _mobileCartOpen = false;
  String? _payMethod;
  String _cashReceived = '';

  bool _online = true;
  web.EventListener? _onlineListener;
  web.EventListener? _offlineListener;
  web.EventListener? _resizeListener;

  /// Phase 11g-c/d. `_queuedCount` mirrors `OfflineSaleQueue.pendingCount`
  /// — kept as its own field rather than read fresh on every build so a
  /// change (a sale queued here, or a sync completing elsewhere) can
  /// drive a `setState` the normal way. `_syncing`/`_syncProblem` exist
  /// now so `_connStatus`'s four-state mapping is complete, but nothing
  /// sets them true yet — that's 11g-d's sync engine; until it lands
  /// this page only ever shows Online/Offline-working/queued-count,
  /// which is still strictly more correct than the single online/offline
  /// dot it replaces.
  int _queuedCount = 0;
  bool _syncing = false;
  bool _syncProblem = false;

  /// Guards `_drainQueue` against overlapping runs — the periodic timer
  /// below and the `online` event listener can both fire close together
  /// (a flaky connection can bounce online/offline within seconds), and
  /// two concurrent drains could both read the same queued entry before
  /// either has removed it, syncing it twice. `clientReference`'s
  /// server-side idempotency would still stop that becoming a real
  /// double sale, but there's no reason to depend on that as the ONLY
  /// safeguard when a simple flag avoids the race entirely.
  bool _draining = false;
  Timer? _syncRetryTimer;

  /// After this many failed attempts on the SAME queued sale, stop
  /// quietly retrying every pass and surface `Sync problem` instead —
  /// per the brief, still not frightening, just honest that something
  /// needs a look rather than a transient blip.
  static const _syncProblemThreshold = 3;

  bool _showScanner = false;
  String _scanInput = '';
  String? _scanError;

  // Real camera scanning — see services/camera_scanner.dart's header for
  // why this is a separate service rather than inline JS interop here.
  // `_camera` is null whenever the modal is closed; a fresh instance is
  // created each time it opens, since it holds a live hardware handle.
  CameraScanner? _camera;
  Timer? _scanPollTimer;
  bool _cameraStarting = false;
  bool _cameraActive = false;

  /// This page's own copy of AppShell's "More" sheet state — see
  /// `_mobileTabBar`'s header on why this page carries a bottom tab bar
  /// at all instead of relying on AppShell for it.
  bool _moreOpen = false;

  /// The product a cashier is currently naming a price for. Set only
  /// for "Ask price" items — see `_addToCart`/`_productTile`'s comment
  /// on why those can't just be disabled.
  Product? _pricingProduct;
  String _priceEntryInput = '';
  String? _priceEntryError;

  bool _charging = false;
  String? _chargeError;
  _CompletedSale? _completed;

  /// Phase 14a-2. The till is a front-of-store, walk-in screen — there
  /// is no logged-in customer whose phone this could default to (see
  /// this file's old header, "NO CUSTOMER CAPTURE"), so "Send on
  /// WhatsApp" now prompts for a number before it fires rather than
  /// always falling back to the OS share-picker. See
  /// `_whatsAppPromptModal`/`_openWhatsAppReceipt`'s own comments for
  /// why this stays the existing wa.me deep-link mechanism rather than
  /// Gate 8's `OutboundMessageService` (a real, separate scope decision
  /// — named there).
  bool _whatsAppPromptOpen = false;
  String _whatsAppPhone = '';
  String? _whatsAppPhoneError;

  /// Phase 14a-3. Optional — see `_customerNameField`'s own comment.
  /// Threaded into `ringUpSale`'s existing `customerName` parameter and
  /// printed on the receipt as a personalized thank-you when given;
  /// omitted entirely, gracefully, when blank — a walk-in sale with no
  /// name stays a complete, normal sale (sale_endpoint.dart's own
  /// documented design).
  String _customerName = '';

  /// Phase 11g-e. Open stock conflicts for this workspace — see
  /// `_conflictBanner`'s own header. Loaded alongside products and
  /// refreshed after every successful sync pass (`_drainQueue`), since
  /// that's the only moment a new one can appear.
  List<StockConflict> _conflicts = const [];
  final Set<int> _resolvingConflicts = {};

  @override
  void initState() {
    super.initState();
    _view = web.window.innerWidth >= KolaBreak.tablet ? 'tablet' : 'phone';
    _online = web.window.navigator.onLine;
    _queuedCount = OfflineSaleQueue.pendingCount;
    // Explicit `return;` at the end of each closure, deliberately.
    // Without one, a block-bodied closure with no return statement at
    // all infers as `Null Function(Event)` rather than
    // `void Function(Event)` — and `.toJS` only has an extension for
    // the void shape. app_shell.dart's own listeners avoid this by
    // accident (their early-exit branches happen to contain a bare
    // `return;`); this makes it deliberate instead of coincidental.
    _onlineListener = (web.Event _) {
      if (mounted) {
        setState(() => _online = true);
        // The moment the browser says the connection is back is exactly
        // the moment to try draining — waiting for the next periodic
        // tick would mean up to `_syncRetryInterval` of visible delay
        // for something the brief wants to feel immediate ("6 sales
        // waiting to sync" clearing as soon as it's true).
        unawaited(_drainQueue());
      }
      return;
    }.toJS;
    _offlineListener = (web.Event _) {
      if (mounted) setState(() => _online = false);
      return;
    }.toJS;
    web.window.addEventListener('online', _onlineListener);
    web.window.addEventListener('offline', _offlineListener);

    // Real responsive layout. A cashier does not pick "phone" or
    // "tablet" from a menu — the till just fits the screen it's on, and
    // re-fits itself if that screen rotates or a browser window is
    // resized. No debounce: setState from a resize handler is cheap
    // here (a layout swap, not a re-fetch), and every other listener in
    // this codebase (app_shell.dart's included) is un-debounced too.
    _resizeListener = (web.Event _) {
      final next = web.window.innerWidth >= KolaBreak.tablet ? 'tablet' : 'phone';
      if (mounted && next != _view) setState(() => _view = next);
      return;
    }.toJS;
    web.window.addEventListener('resize', _resizeListener);

    // Phase 11g-d. Two reasons this is a periodic timer and not purely
    // event-driven: (1) navigator.onLine's own `online` event is not
    // fully reliable — the brief's own framing (a market stall on
    // failing mobile data) is exactly the case where the browser never
    // clearly transitions states at all; a timer is the real safety net
    // under the event listener, not a redundant belt-and-braces. (2) a
    // failed sync needs to retry again later even while `_online` never
    // changed — a request can time out on a technically-"online" but
    // too-degraded connection. `_syncRetryInterval` is short enough that
    // "it will retry" (the brief's own promise) is true within a
    // reasonable wait, long enough not to hammer a connection that's
    // already struggling.
    _syncRetryTimer = Timer.periodic(_syncRetryInterval, (_) => unawaited(_drainQueue()));

    // Catches sales left queued from a previous tab/session (the tab
    // was closed, or the app reloaded, before they synced) — the queue
    // is on disk (localStorage), not in memory, so it outlives any one
    // page load. Runs on every load, not only when one exists, but
    // `_drainQueue` itself is a no-op when the queue is empty.
    unawaited(_drainQueue());

    _load();
  }

  static const _syncRetryInterval = Duration(seconds: 20);

  @override
  void dispose() {
    if (_onlineListener != null) {
      web.window.removeEventListener('online', _onlineListener);
    }
    if (_offlineListener != null) {
      web.window.removeEventListener('offline', _offlineListener);
    }
    if (_resizeListener != null) {
      web.window.removeEventListener('resize', _resizeListener);
    }
    _syncRetryTimer?.cancel();
    _scanPollTimer?.cancel();
    _camera?.stop();
    super.dispose();
  }

  /// Phase 11g-d — the sync engine. Drains `OfflineSaleQueue` in order,
  /// one entry at a time, via the same idempotent `ringUpSale` every
  /// synced sale already goes through — a retried entry that actually
  /// reached the server on an earlier, response-lost attempt resolves
  /// to that same Sale rather than creating a second one (see
  /// `sale_repository.dart`'s `findByClientReference`).
  ///
  /// STOPS AT THE FIRST FAILURE IN A PASS, DELIBERATELY. Two reasons:
  /// or­dering (a later sale should never sync ahead of an earlier one
  /// from the same till — continuing past a failed entry to try the
  /// next would let that happen), and cost (if the first failure is a
  /// transport failure, every later entry in this pass would fail
  /// identically; there is nothing to gain from trying them all now
  /// instead of on the next timer tick).
  ///
  /// NAMED SCOPE CUT: this only runs while `till_page.dart` itself is
  /// open. Closing the tab with sales still queued pauses syncing until
  /// it's reopened — the queue is not lost (it's on disk), but nothing
  /// drains it in the background. A true background sync (the Service
  /// Worker Background Sync API, or a periodic sync registered from
  /// sw.js) is real, separate follow-up work, not attempted here — most
  /// realistically a cashier's device stays on the till screen through
  /// an outage since that is the screen they need, but "most
  /// realistically" is a real gap worth naming rather than silently
  /// accepting.
  Future<void> _drainQueue() async {
    if (_draining) return;
    var pending = OfflineSaleQueue.list();
    if (pending.isEmpty) {
      if (mounted && (_syncing || _syncProblem || _queuedCount != 0)) {
        setState(() {
          _syncing = false;
          _syncProblem = false;
          _queuedCount = 0;
        });
      }
      return;
    }

    _draining = true;
    if (mounted) setState(() => _syncing = true);

    var syncedAny = false;
    for (final entry in pending) {
      try {
        await component.client.sale.ringUpSale(
          component.accessToken,
          component.workspaceId,
          linesJson: entry.linesJson,
          paymentMethod: entry.paymentMethod,
          cashReceivedMinor: entry.cashReceivedMinor,
          clientReference: entry.clientReference,
          customerPhone: entry.customerPhone,
          customerName: entry.customerName,
        );
        OfflineSaleQueue.markSynced(entry.clientReference);
        syncedAny = true;
      } catch (e) {
        OfflineSaleQueue.markFailed(entry.clientReference, ErrorText.of(e));
        break;
      }
    }

    pending = OfflineSaleQueue.list();
    _draining = false;
    if (!mounted) return;
    setState(() {
      _queuedCount = pending.length;
      _syncing = false;
      _syncProblem = pending.any((e) => e.attempts >= _syncProblemThreshold);
    });

    // Once anything actually lands, the server's stock counts are ahead
    // of this page's optimistic local decrements (see
    // `_applyOptimisticStockDecrement`) — refresh to pick up whatever
    // the server itself computed. A sync is also the ONLY moment a new
    // stock conflict can appear (see stock_conflict.spy.yaml's header
    // on when SaleEndpoint.ringUpSale creates one) — reload the banner
    // right alongside.
    if (syncedAny) {
      unawaited(_silentRefreshProducts());
      unawaited(_loadConflicts());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final products = await component.client.product.listProducts(
        component.accessToken,
        component.workspaceId,
        // Serverpod's generated client drops default values — a
        // documented landmine in this codebase (bool x = false becomes
        // required bool x on the wire). Must be passed explicitly.
        includeArchived: false,
      );
      if (!mounted) return;
      final visible = [for (final p in products) if (p.status != 'archived') p];
      setState(() {
        _products = visible;
        _catalogAsOf = null; // null means "this is live", not stale
        _loading = false;
      });
      // Phase 11g-f. Every live fetch refreshes the fallback a future
      // offline load will use — deliberately the FULL list (archived
      // items included) rather than `visible`, so a product an owner
      // un-archives while offline (unlikely, but the catalog import
      // path doesn't rule it out) isn't missing from the cache either;
      // the same `p.status != 'archived'` filter applied above is
      // re-applied wherever the cache is read.
      OfflineCatalogCache.save(component.workspaceId, products);
      unawaited(_hydrateMedia());
      unawaited(_loadConflicts());
    } catch (e) {
      if (!mounted) return;
      // Phase 11g-f. A transport failure with something already cached
      // falls back to the last-known catalog instead of a bare error
      // screen — DESIGN_BRIEF_COMMERCE.md §1: "look up any product... See
      // correct price and last-known stock" must work with zero
      // connection, and this is the moment that's tested (a hard
      // reload/first load of the till while offline, not just a sale
      // attempted mid-session). Any other failure (a real rejection) still
      // shows the normal error state — there is nothing "last known" about
      // a workspace access failure.
      if (ErrorText.isOffline(e)) {
        final cached = OfflineCatalogCache.load(component.workspaceId);
        if (cached != null) {
          setState(() {
            _products = [for (final p in cached.products) if (p.status != 'archived') p];
            _catalogAsOf = cached.fetchedAt;
            _loading = false;
            _loadError = null;
          });
          unawaited(_hydrateMedia());
          return;
        }
      }
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  /// Phase 11g-e. Failure here is silent on purpose — same posture as
  /// `_hydrateMedia`: a conflict banner that fails to load is a missed
  /// convenience, not a reason to block the till from ringing up sales.
  Future<void> _loadConflicts() async {
    try {
      final conflicts = await component.client.stockConflict.listOpen(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() => _conflicts = conflicts);
    } catch (_) {
      // Swallowed — see doc comment above.
    }
  }

  /// Same fetch as `_load`, without the loading-spinner state flips —
  /// for refreshing stock numbers in the background after a sale, where
  /// flashing a spinner over a screen the cashier isn't even looking at
  /// (the receipt is) would just be visual noise. A failure here is
  /// silent on purpose: the sale already succeeded and is on screen,
  /// this is only keeping displayed stock current, and the next full
  /// `_load()` (a real page load) catches up regardless.
  Future<void> _silentRefreshProducts() async {
    try {
      final products = await component.client.product.listProducts(
        component.accessToken,
        component.workspaceId,
        includeArchived: false,
      );
      if (!mounted) return;
      setState(() {
        _products = [for (final p in products) if (p.status != 'archived') p];
        _catalogAsOf = null; // a live fetch just landed — no longer stale
      });
      OfflineCatalogCache.save(component.workspaceId, products);
      unawaited(_hydrateMedia());
    } catch (_) {
      // Deliberately swallowed — see doc comment above. Notably this
      // does NOT fall back to the cache the way `_load` does: this is a
      // background refresh with something already on screen (either a
      // live catalog or, itself, an already-shown cached one) —
      // overwriting either with a DIFFERENT stale snapshot on a silent
      // background call would be a regression, not a recovery.
    }
  }

  /// One batched photo call for the whole till catalog — same
  /// `listMediaForProducts`/position-0-is-the-main-image approach
  /// catalog_page.dart already uses, not a placeholder icon standing in
  /// for a photo that exists. Unlike that page, this one is not scoped
  /// to a visible page of results: a till's catalog is what's on
  /// screen right now (no pagination here), so there's nothing to
  /// scope the ask to short of the whole list.
  Future<void> _hydrateMedia() async {
    final ids = [for (final p in _products) if (p.id != null) p.id!];
    if (ids.isEmpty) return;
    try {
      final media = await component.client.product.listMediaForProducts(
        component.accessToken,
        component.workspaceId,
        ids.join(','),
      );
      if (!mounted) return;
      final images = <int, ProductMedia>{};
      for (final m in media) {
        final existing = images[m.productId];
        if (existing == null || m.position < existing.position) {
          images[m.productId] = m;
        }
      }
      setState(() => _mainImages = images);
    } catch (_) {
      // No thumbnails rather than no catalog — a till that can't show
      // photos today must still ring up sales.
    }
  }

  // ── Categories ─────────────────────────────────────────────────────

  /// Real categories, in first-seen order — never the export's static
  // ['fabric','gowns','accessories','services']. product.spy.yaml's own
  // header says category is free text a shop chooses, so this page
  // must read whatever they actually chose, not a guessed taxonomy.
  List<String> get _categories {
    final seen = <String>[];
    for (final p in _products) {
      final c = p.category?.trim();
      if (c != null && c.isNotEmpty && !seen.contains(c)) seen.add(c);
    }
    return seen;
  }

  List<Product> get _filteredProducts {
    final q = _search.trim().toLowerCase();
    return [
      for (final p in _products)
        if ((_category == null || p.category == _category) &&
            (q.isEmpty || p.name.toLowerCase().contains(q)))
          p,
    ];
  }

  // ── Cart ───────────────────────────────────────────────────────────

  /// [unitPriceMinor] is required, never read off `product` here — most
  /// calls pass the catalog price straight through, but "Ask price"
  /// products (`product.priceMinor == null`) route through
  /// `_priceEntryModal` first and pass what the cashier typed instead.
  void _addToCart(Product product, int unitPriceMinor) {
    setState(() {
      final existing = _cart.where((l) => l.product.id == product.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(_CartLine(product: product, unitPriceMinor: unitPriceMinor));
      }
    });
    unawaited(_pushDisplay());
  }

  // ── "Ask price" entry ─────────────────────────────────────────────

  /// A service like "Custom tailoring" or "Fabric sourcing (per trip)"
  /// has no fixed catalog price by design (product.spy.yaml's own
  /// header) — that's real, not missing data, and a till that just
  /// disables the tile for these means a cashier can never ring up a
  /// huge slice of a service business's actual catalog. Instead: tap
  /// opens a one-field prompt for what this sale actually charges, then
  /// adds at that price. Same modal shape as the barcode scanner.
  void _openPriceEntry(Product p) => setState(() {
        _pricingProduct = p;
        _priceEntryInput = '';
        _priceEntryError = null;
      });

  void _closePriceEntry() => setState(() => _pricingProduct = null);

  void _submitPriceEntry() {
    final digits = _priceEntryInput.replaceAll(RegExp(r'[^0-9]'), '');
    final naira = int.tryParse(digits) ?? 0;
    if (naira <= 0) {
      setState(() => _priceEntryError = 'Enter a price above ₦0.');
      return;
    }
    final product = _pricingProduct;
    if (product == null) return;
    _addToCart(product, naira * 100);
    setState(() => _pricingProduct = null);
  }

  void _inc(_CartLine line) {
    setState(() => line.quantity++);
    unawaited(_pushDisplay());
  }

  void _dec(_CartLine line) {
    if (line.quantity <= 1) return;
    setState(() => line.quantity--);
    unawaited(_pushDisplay());
  }

  void _removeLine(_CartLine line) {
    setState(() => _cart.remove(line));
    unawaited(_pushDisplay());
  }

  int _quantityInCart(Product p) {
    final match = _cart.where((l) => l.product.id == p.id).toList();
    return match.isEmpty ? 0 : match.first.quantity;
  }

  int get _subtotalMinor => _cart.fold(0, (sum, l) => sum + l.lineTotalMinor);
  int get _taxMinor => (_subtotalMinor * component.taxRateBps / 10000).round();
  int get _totalMinor => _subtotalMinor + _taxMinor;

  /// Digits typed so far, read as whole Naira then converted to minor
  /// units — same "strip everything but digits" approach the export's
  /// own `parseInt((cashReceived||'0').replace(/[^0-9]/g,''),10)` uses,
  /// so a cashier can type "40000" or "₦40,000" and either works.
  int get _cashReceivedMinor {
    final digits = _cashReceived.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return (int.tryParse(digits) ?? 0) * 100;
  }

  int get _changeMinor => _cashReceivedMinor - _totalMinor;

  bool get _completeDisabled {
    if (_payMethod == null || _charging) return true;
    if (_payMethod == 'Cash' && _changeMinor < 0) return true;
    // Deliberately NOT gated on `_online` — DESIGN_BRIEF_COMMERCE.md §1
    // is explicit that a sale must complete with zero connection.
    // Charging while offline queues instead of calling the server; see
    // `_completeSale`.
    return false;
  }

  /// Phase 11g-c. Four states, not a binary dot — DESIGN_BRIEF_COMMERCE
  /// .md §1's own naming: "Online · Offline, working · Syncing (n) ·
  /// Sync problem." `_syncing`/`_syncProblem` are always false until
  /// 11g-d's sync engine lands (see their own field comments), so today
  /// this only ever resolves to `online` or `offlineWorking` — a
  /// strict superset of the single dot it replaces, not a regression
  /// while the sync engine is still being built.
  _ConnStatus get _connStatus {
    if (_syncProblem) return _ConnStatus.syncProblem;
    if (_syncing) return _ConnStatus.syncing;
    if (!_online) return _ConnStatus.offlineWorking;
    return _ConnStatus.online;
  }

  Future<void> _completeSale() async {
    if (_completeDisabled) return;
    setState(() {
      _charging = true;
      _chargeError = null;
    });

    final method = _payMethod!.toLowerCase();
    final cashReceived = method == 'cash' ? _cashReceivedMinor : null;
    // Sent as a JSON-encoded String, not List<SaleLineInput> and not
    // parallel List<int?>/List<String> arrays either (that was the
    // previous attempt) — Serverpod can't deserialize ANY List<...> as
    // a direct endpoint parameter on this install, only scalars (see
    // sale_endpoint.dart's ringUpSale header for the full story).
    final linesJson = jsonEncode([
      for (final l in _cart)
        {
          'productId': l.product.id,
          'name': l.product.name,
          'unitPriceMinor': l.unitPriceMinor,
          'quantity': l.quantity,
        },
    ]);
    // Generated up front, before either path is attempted — see
    // OfflineSaleQueue.newReference's own header on why the online
    // attempt below must carry the SAME reference the offline fallback
    // would use, not a fresh one.
    final reference = OfflineSaleQueue.newReference();
    // Phase 14a-3. Trimmed once, up front, so both the online path
    // below and `_queueSale`'s offline path send/store exactly the
    // same value — null (not empty string) when the cashier left the
    // field blank, matching `ringUpSale`'s own optional-parameter
    // contract (see sale_endpoint.dart's header).
    final customerName = _customerName.trim().isEmpty ? null : _customerName.trim();

    // Offline-first short-circuit: navigator.onLine already says there
    // is no connection, so don't spend a doomed round-trip finding that
    // out — go straight to the queue. The try/catch below is still the
    // real safety net for the far more common case a flat boolean
    // misses entirely: navigator.onLine reporting true on a connection
    // that is actually too degraded to complete a request (a market
    // stall on failing mobile data, not a clean modem-unplugged
    // outage).
    if (!_online) {
      _queueSale(
        reference: reference,
        linesJson: linesJson,
        method: method,
        cashReceived: cashReceived,
        customerName: customerName,
      );
      return;
    }

    try {
      final sale = await component.client.sale.ringUpSale(
        component.accessToken,
        component.workspaceId,
        linesJson: linesJson,
        paymentMethod: method,
        cashReceivedMinor: cashReceived,
        clientReference: reference,
        customerName: customerName,
      );
      if (!mounted) return;
      setState(() {
        _completed = _CompletedSale(
          sale: sale,
          lines: List.of(_cart),
          paidLabel: _payMethod!,
          customerName: customerName,
        );
        _cart.clear();
        _mobileCartOpen = false;
        _payMethod = null;
        _cashReceived = '';
        _customerName = '';
        _charging = false;
        _screen = _Screen.receipt;
      });
      unawaited(_pushDisplay());
      // Stock sync — ringUpSale now decrements each line's product on the
      // server; this quietly re-fetches so the grid behind this receipt
      // shows the real remaining count the moment the cashier taps "New
      // sale," instead of the stale figure from when this screen loaded.
      // No `_loading` flip here on purpose — the receipt is on screen,
      // a spinner over the (now-cleared) sell screen behind it would be
      // visible for nothing.
      unawaited(_silentRefreshProducts());
    } catch (e) {
      if (!mounted) return;
      // A transport failure (the request never reached the server, or
      // its response never came back) is queued rather than shown as an
      // error — per the brief, this is Tuesday, not a fault. Anything
      // else (a KolaException the server actually returned — the
      // workspace's commerce flag lapsed, a session expired) is a real
      // rejection and must surface, not be queued to fail identically
      // forever.
      if (ErrorText.isOffline(e)) {
        _queueSale(
          reference: reference,
          linesJson: linesJson,
          method: method,
          cashReceived: cashReceived,
          customerName: customerName,
        );
        return;
      }
      setState(() {
        _charging = false;
        _chargeError = ErrorText.of(e);
      });
    }
  }

  /// Writes a sale to the local outbox and shows it as a (visibly
  /// marked) receipt immediately — see `_CompletedSale.queued`'s own
  /// comment on why the receipt still renders in full. Shared by both
  /// `_completeSale` call sites above: the `!_online` short-circuit and
  /// the transport-failure catch branch.
  void _queueSale({
    required String reference,
    required String linesJson,
    required String method,
    int? cashReceived,
    String? customerName,
  }) {
    OfflineSaleQueue.enqueue(
      clientReference: reference,
      linesJson: linesJson,
      paymentMethod: method,
      cashReceivedMinor: cashReceived,
      customerName: customerName,
    );

    // A client-built Sale, not a server response — Sale's own
    // constructor (kola_client/lib/src/protocol/sale.dart) has no
    // required field this page can't already compute itself
    // (subtotal/tax/total from the same workspace tax rate
    // ringUpSale would apply; `id` stays null, `reference` is this
    // queue entry's own clientReference until the real one comes back
    // from a sync). This is what lets the receipt/WhatsApp-share/print
    // paths downstream treat a queued sale exactly like a synced one
    // without a second code path — see `_CompletedSale.queued` for the
    // one place they're told apart.
    final now = DateTime.now().toUtc();
    final localSale = Sale(
      workspaceId: component.workspaceId,
      reference: reference,
      clientReference: reference,
      subtotalMinor: _subtotalMinor,
      taxRateBps: component.taxRateBps,
      taxMinor: _taxMinor,
      totalMinor: _totalMinor,
      currency: 'NGN', // see _pushDisplay's own comment on this gap
      paymentMethod: method,
      cashReceivedMinor: cashReceived,
      changeMinor: method == 'cash' ? _changeMinor : null,
      status: 'completed',
      soldAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final soldLines = List.of(_cart);
    if (!mounted) return;
    setState(() {
      _completed = _CompletedSale(
        sale: localSale,
        lines: soldLines,
        paidLabel: _payMethod!,
        customerName: customerName,
        queued: true,
      );
      _cart.clear();
      _mobileCartOpen = false;
      _payMethod = null;
      _cashReceived = '';
      _customerName = '';
      _charging = false;
      _screen = _Screen.receipt;
      _queuedCount = OfflineSaleQueue.pendingCount;
    });
    unawaited(_pushDisplay());
    // Deliberately NOT _silentRefreshProducts() here, unlike the synced
    // path above — a queued sale has not touched server-side stock yet;
    // re-fetching now would overwrite the optimistic decrement just
    // applied below with the server's still-stale (higher) count.
    _applyOptimisticStockDecrement(soldLines);
  }

  /// So the NEXT sale in the same outage sees reduced stock rather than
  /// the figure from before this one — the brief's "See correct price
  /// and last-known stock" applies between two offline sales, not just
  /// between an online sale and the next page load. Clamped at zero,
  /// matching `ProductRepository.adjustStock`'s own server-side clamp
  /// (see that method's header) so a locally-displayed number never
  /// contradicts what the server will show once this syncs. Detecting
  /// and surfacing a REAL oversell (two tills, one last item) is
  /// 11g-e's job, not this one — this is purely "don't show the
  /// original count after it's already been sold."
  void _applyOptimisticStockDecrement(List<_CartLine> soldLines) {
    final soldByProduct = <int, int>{};
    for (final l in soldLines) {
      final id = l.product.id;
      if (id == null) continue;
      soldByProduct.update(id, (v) => v + l.quantity, ifAbsent: () => l.quantity);
    }
    if (soldByProduct.isEmpty) return;
    final updated = [
      for (final p in _products)
        if (p.id != null && soldByProduct.containsKey(p.id) && p.stock != null)
          p.copyWith(stock: max(0, p.stock! - soldByProduct[p.id]!))
        else
          p,
    ];
    setState(() => _products = updated);
    // Phase 11g-f: keeps a mid-outage HARD RELOAD honest too — without
    // this, `_load`'s offline fallback would read the pre-sale stock
    // count back out of the cache, undoing the very decrement this
    // method exists to apply. `_catalogAsOf` is deliberately left
    // unchanged (still whatever it was, live or already-stale) — this
    // write doesn't make the snapshot any less stale, it just keeps the
    // stale snapshot internally consistent with sales made against it.
    OfflineCatalogCache.save(component.workspaceId, updated);
  }

  void _voidSale() {
    setState(() {
      _screen = _Screen.sell;
      _payMethod = null;
      _cashReceived = '';
      _customerName = '';
      _chargeError = null;
    });
    unawaited(_pushDisplay());
  }

  void _newSale() {
    setState(() {
      _screen = _Screen.sell;
      _cart.clear();
      _payMethod = null;
      _cashReceived = '';
      _customerName = '';
      _completed = null;
    });
    unawaited(_pushDisplay());
  }

  // ── Customer display sync ──────────────────────────────────────────
  //
  // Fire-and-forget push to TillDisplayEndpoint.pushState after every
  // cart mutation and screen transition above — see
  // till_display_page.dart's own header on what's rendering on the
  // other end. Never awaited at any call site and every failure is
  // swallowed here: a customer-facing second screen failing to update
  // must never block, or even visibly slow down, an actual sale. Safe
  // to call unconditionally — pushState itself is deliberately
  // ungated (see that endpoint's own header), so this costs one cheap
  // upsert whether or not the workspace has the display switched on.
  Future<void> _pushDisplay() async {
    // The receipt screen shows what was JUST charged, not the (already
    // cleared) live cart — _completeSale snapshots that into
    // `_completed` before clearing `_cart`, same snapshot the receipt
    // itself renders from.
    final receiptSale = _screen == _Screen.receipt ? _completed : null;
    final lines = receiptSale?.lines ?? _cart;
    final subtotal = receiptSale != null
        ? receiptSale.lines.fold<int>(0, (sum, l) => sum + l.lineTotalMinor)
        : _subtotalMinor;
    final status = switch (_screen) {
      _Screen.payment => 'payment',
      _Screen.receipt => 'receipt',
      _Screen.sell => lines.isEmpty ? 'idle' : 'shopping',
    };
    try {
      await component.client.tillDisplay.pushState(
        component.accessToken,
        component.workspaceId,
        jsonEncode([
          for (final l in lines)
            {
              'name': l.product.name,
              'quantity': l.quantity,
              'unitPriceMinor': l.unitPriceMinor,
              'lineTotalMinor': l.lineTotalMinor,
            },
        ]),
        subtotal,
        // No per-workspace currency field exists yet — see
        // money_format.dart's own hardcoded ₦ symbol, the same gap this
        // mirrors rather than invents.
        'NGN',
        status,
      );
    } catch (_) {
      // Swallowed — see doc comment above.
    }
  }

  // ── Scanner ────────────────────────────────────────────────────────
  //
  // Two independent ways a barcode reaches this screen, both ending at
  // the same `_resolveScan`: a real camera (see services/camera_scanner
  // .dart — Chrome/Edge/Android only, native BarcodeDetector API) when
  // supported, and manual text entry always available underneath it —
  // typing works everywhere, and is also what a genuine HANDHELD
  // scanner drives (it emits keystrokes + a trailing Enter into
  // whatever field is focused, no camera or special wiring needed).

  void _openScanner() {
    setState(() {
      _showScanner = true;
      _scanInput = '';
      _scanError = null;
      _cameraStarting = barcodeDetectorSupported;
      _cameraActive = false;
    });
    if (barcodeDetectorSupported) {
      // The <video> element this needs doesn't exist in the DOM until
      // the setState above has actually rendered the modal — same
      // render-then-query pattern as every other post-render DOM lookup
      // in this codebase (see dom_files.dart's header on why raw DOM
      // access has to go through a real element, not a guess).
      Future.delayed(Duration.zero, _startCamera);
    }
  }

  Future<void> _startCamera() async {
    if (!mounted || !_showScanner) return;
    final found = web.document.getElementById('kola-scanner-video');
    if (found == null) {
      setState(() => _cameraStarting = false);
      return;
    }
    // Reinterpret-cast, same pattern as dom_files.dart's own extension
    // types — `found` and `HTMLVideoElement` wrap the same underlying JS
    // object, this is not a runtime check that can fail on a real
    // `<video>` element.
    final video = found as web.HTMLVideoElement;
    final camera = CameraScanner();
    _camera = camera;
    final started = await camera.start(video);
    if (!mounted || !_showScanner) {
      camera.stop();
      return;
    }
    if (!started) {
      setState(() {
        _cameraStarting = false;
        _cameraActive = false;
      });
      return;
    }
    setState(() {
      _cameraStarting = false;
      _cameraActive = true;
    });
    // Polling, not a continuous loop — BarcodeDetector.detect() is
    // itself async (it can take real work per call), so a fixed-delay
    // Timer.periodic never overlaps calls the way a tight while-loop
    // scheduling the next detect() before the last one resolves could.
    _scanPollTimer = Timer.periodic(const Duration(milliseconds: 350), (_) async {
      if (!mounted || !_showScanner || _camera == null) return;
      final raw = await _camera!.detectOnce(video);
      if (raw == null || raw.trim().isEmpty) return;
      if (!mounted || !_showScanner) return;
      _resolveScan(raw);
    });
  }

  void _closeScanner() {
    _scanPollTimer?.cancel();
    _scanPollTimer = null;
    _camera?.stop();
    _camera = null;
    setState(() {
      _showScanner = false;
      _cameraStarting = false;
      _cameraActive = false;
    });
  }

  void _submitScan() => _resolveScan(_scanInput);

  /// The one place a scanned/typed value turns into a cart action —
  /// shared by the camera path and the manual-entry path so they can
  /// never drift into matching products differently.
  void _resolveScan(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    final matches = _products.where(
      (p) => (p.sku?.trim().toLowerCase() == q) || p.name.toLowerCase().contains(q),
    );
    if (matches.isEmpty) {
      setState(() => _scanError = 'No product matches "$query".');
      return;
    }
    final product = matches.first;
    _scanPollTimer?.cancel();
    _scanPollTimer = null;
    _camera?.stop();
    _camera = null;
    setState(() {
      _showScanner = false;
      _cameraActive = false;
      _cameraStarting = false;
    });
    if (product.priceMinor != null) {
      _addToCart(product, product.priceMinor!);
    } else {
      _openPriceEntry(product);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    // Viewport-locked, per styles.css's own convention (html/body carry
    // `overflow:hidden` everywhere in this app — see its header comment
    // — so a page that wants to scroll must own a bounded height and an
    // internal overflow region, never rely on document-level scroll).
    // Fixed header, then a flex:1 body that the tablet/phone layouts
    // each split further so the product grid and the cart scroll
    // independently of the totals/Charge footer, which is what stops
    // the button that was sliding down the page as the cart grew.
    return div(
      attributes: {
        // height:100vh, then height:100svh right after it — deliberately
        // two declarations of the same property. `vh` on a phone browser
        // measures the viewport with its address bar COLLAPSED, which is
        // taller than what's actually visible while the bar is showing
        // (the normal state on page load). The Charge footer below is a
        // flex sibling pinned to the bottom of THIS box, so when this
        // box is taller than the real visible area, the footer is
        // pushed down past it — which is exactly "the Charge button
        // isn't visible" with nothing structurally wrong in the layout
        // itself.
        //
        // `svh` (small viewport height), not `dvh`. `dvh` was tried
        // first and caused a NEW problem: it recomputes live as the
        // address bar shows/hides, so this whole box resized on every
        // scroll tick — the visible symptom was the page feeling laggy,
        // like the browser chrome flickering in and out during a normal
        // scroll. `svh` is the height with the address bar assumed
        // SHOWN — a fixed number, computed once, matching the worst
        // case the original bug needed fixed, with none of `dvh`'s
        // live-resize jank. A browser that doesn't understand `100svh`
        // drops that whole declaration and keeps the `100vh` line above
        // it, so this stays safe everywhere.
        'style': "font-family:${KolaFonts.sans};background:${KolaVar.bg};"
            'color:${KolaVar.text};height:100vh;height:100svh;box-sizing:border-box;'
            'display:flex;flex-direction:column;overflow:hidden',
      },
      [
        _header(),
        if (_conflicts.isNotEmpty && _screen == _Screen.sell) _conflictBanner(),
        div(
          attributes: {'style': 'flex:1;min-height:0;overflow:hidden'},
          [if (_view == 'tablet') _tabletBody() else _phoneBody()],
        ),
        _mobileTabBar(),
        if (_showScanner) _scannerModal(),
        if (_pricingProduct != null) _priceEntryModal(_pricingProduct!),
        if (_whatsAppPromptOpen) _whatsAppPromptModal(),
        if (_moreOpen)
          MobileMoreSheet(
            gate: component.gate,
            currentRoute: '/counter',
            onClose: () => setState(() => _moreOpen = false),
          ),
      ],
    );
  }

  /// This page's own bottom tab bar, below 1024px — the till is deliberately
  /// NOT wrapped in AppShell (see this file's header and app.dart's own
  /// comment on the /counter route: a full-bleed page, no sidebar), so it
  /// gets none of AppShell's chrome for free. Without this, opening the
  /// Sales counter from the bottom tab bar on the Overview page dropped a
  /// mobile user into a page with no way back except the "Dashboard" link
  /// this page's own header carried — a different, page-specific navigation
  /// model from every other screen in the app the moment you're on it.
  ///
  /// Reuses `MobileTabBar`/`MobileMoreSheet` directly rather than wrapping
  /// this whole page in `shellFor`: shellFor would also add AppShell's own
  /// top bar and, on desktop, the sidebar — this page's desktop layout is
  /// deliberately full-bleed with no sidebar, and adding a second top bar
  /// above this page's own header (which already carries "Sales Counter ·
  /// Online" and the Documents link) would just stack two headers. Only the
  /// bottom bar is missing on mobile; only the bottom bar is added.
  Component _mobileTabBar() => div(
        classes: 'kola-shell-mobile',
        attributes: {'style': 'flex-direction:column'},
        [
          MobileTabBar(
            gate: component.gate,
            currentRoute: '/counter',
            onOpenMore: () => setState(() => _moreOpen = true),
          ),
        ],
      );

  /// Phase 11g-e. DESIGN_BRIEF_COMMERCE.md §1's exact conflict-copy
  /// pattern, one card per open conflict, restricted to the Sell screen
  /// (a cashier mid-payment shouldn't be interrupted by this — it can
  /// wait the few seconds until they're back at the product grid).
  /// "Never a merge-conflict UI": no diff view, no timestamps-of-both-
  /// tills detail, just the plain sentence and two real choices plus a
  /// quiet dismiss.
  Component _conflictBanner() => div(
        attributes: {
          'style': 'flex:none;padding:10px 20px;background:${KolaVar.warningBg};'
              'border-bottom:1px solid ${KolaVar.border};display:flex;'
              'flex-direction:column;gap:8px',
        },
        [for (final c in _conflicts) _conflictCard(c)],
      );

  Component _conflictCard(StockConflict c) {
    final product = _products.firstWhereOrNull((p) => p.id == c.productId);
    final name = product?.name ?? 'a product';
    final busy = c.id != null && _resolvingConflicts.contains(c.id);

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;justify-content:space-between;'
            'gap:12px;flex-wrap:wrap',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                'line-height:1.5;flex:1;min-width:220px',
          },
          [
            // The brief's own example sentence, adapted to whatever this
            // conflict's real numbers are: "Both tills sold the last red
            // ankara at 2:15pm. Stock is now −1. Mark one as a backorder,
            // or adjust the count?"
            Component.text(
              'More $name sold than was in stock — short by ${c.oversoldBy}. '
              'Mark it as a backorder, or adjust the count?',
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:6px;flex:none'},
          [
            _conflictButton('Backorder', busy, () => _resolveConflict(c, 'backordered')),
            _conflictButton('Adjust count', busy, () => _resolveConflict(c, 'adjusted')),
            _conflictButton('Dismiss', busy, () => _resolveConflict(c, 'dismissed'), quiet: true),
          ],
        ),
      ],
    );
  }

  Component _conflictButton(String label, bool busy, void Function() onTap, {bool quiet = false}) =>
      button(
        attributes: {
          'type': 'button',
          if (busy) 'disabled': 'disabled',
          'style': 'padding:7px 12px;border-radius:${KolaRadius.sm};'
              'font-size:${KolaType.tiny};font-weight:600;font-family:inherit;'
              'white-space:nowrap;cursor:${busy ? 'default' : 'pointer'};'
              '${quiet ? 'background:transparent;border:1px solid ${KolaVar.border};color:${KolaVar.muted}' : 'background:${KolaVar.card};border:1px solid ${KolaVar.border};color:${KolaVar.text}'}',
        },
        events: {'click': (_) => busy ? null : onTap()},
        [Component.text(label)],
      );

  Future<void> _resolveConflict(StockConflict c, String resolution) async {
    final id = c.id;
    if (id == null) return;
    setState(() => _resolvingConflicts.add(id));
    try {
      await component.client.stockConflict.resolve(
        component.accessToken,
        component.workspaceId,
        id,
        resolution,
      );
      if (!mounted) return;
      setState(() {
        _conflicts = [for (final x in _conflicts) if (x.id != id) x];
        _resolvingConflicts.remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      // A failed resolve just leaves the card showing — the owner can
      // try again. No separate error UI for this small a surface.
      setState(() => _resolvingConflicts.remove(id));
    }
  }

  Component _header() => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;'
              'align-items:center;padding:14px 20px;flex:none;'
              'border-bottom:1px solid ${KolaVar.border};gap:10px;'
              'flex-wrap:wrap',
        },
        [
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:12px;min-width:0'},
            [
              // Desktop only. Below 1024px this page now carries its own
              // bottom tab bar (see _mobileTabBar) with a Home icon that
              // does the same job — keeping this link too would be two
              // ways to say "go back to the dashboard" stacked in the
              // same header, one of them redundant the moment the other
              // exists.
              div(
                classes: 'kola-shell-desktop',
                attributes: {'style': 'flex:none'},
                [
                  Link(
                    to: '/',
                    attributes: {
                      'style': 'color:${KolaVar.text};font-weight:600;'
                          'text-decoration:none;font-size:${KolaType.body};'
                          'display:inline-flex;align-items:center;gap:3px;flex:none',
                    },
                    children: [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Dashboard')],
                  ),
                ],
              ),
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};font-size:${KolaType.subhead};'
                      'font-weight:600;white-space:nowrap;flex:none',
                },
                [Component.text('Sales Counter')],
              ),
              _connStatusBadge(),
              if (_queuedCount > 0) _queuedCountBadge(),
            ],
          ),
          // Phase 14a-5. The "Documents" button that used to sit here
          // was removed at the owner's own instruction — a walk-in
          // sales screen doesn't need a document-browser button in its
          // own header. "Invoices" now lives in the profile/account
          // dropdown instead (nav_model.dart's profileEntries), and the
          // per-sale print/WhatsApp affordances on the receipt screen
          // below (_printButton/_whatsAppButton) cover what a cashier
          // actually needs mid-sale.
          const PageHelpButton(
            pageKey: 'till',
            body: [
              "Ring up a sale, take payment, and print or WhatsApp the "
                  "receipt — everything a walk-in sale needs, from this "
                  "one screen.",
              "Working offline? Sales queue up and sync automatically "
                  "once the connection badge goes green again.",
            ],
          ),
        ],
      );

  /// Phase 11g-c. Replaces the old plain online/offline dot with
  /// DESIGN_BRIEF_COMMERCE.md §1's four named states — see
  /// `_ConnStatus`/`_connStatus`. Still just a dot + label, deliberately
  /// calm rather than alarm-styled even in the `syncProblem` case (the
  /// brief: "Sync failure that is not frightening").
  Component _connStatusBadge() => div(
        attributes: {'style': 'display:flex;align-items:center;gap:6px'},
        [
          div(
            attributes: {
              'style': 'width:7px;height:7px;border-radius:50%;flex:none;'
                  'background:${_connStatus.dotColor}',
            },
            [],
          ),
          span(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:600;white-space:nowrap;'
                  'color:${_connStatus.dotColor}',
            },
            [
              Component.text(
                _connStatus == _ConnStatus.syncing
                    ? '${_connStatus.label} ($_queuedCount)'
                    : _connStatus.label,
              ),
            ],
          ),
        ],
      );

  /// "6 sales waiting to sync" — per the brief, "the owner must be able
  /// to see the money is not lost. This is the single most
  /// anxiety-reducing element in the entire commerce surface." Shown
  /// whenever anything is queued, independent of whether a sync attempt
  /// is in progress right now (`_connStatus`'s `syncing` state) — a
  /// queue can sit unsynced while still offline, and the count must be
  /// visible then too, not only mid-sync.
  Component _queuedCountBadge() => span(
        attributes: {
          'style': 'font-size:${KolaType.tiny};font-weight:600;white-space:nowrap;'
              'background:${KolaVar.pill};color:${KolaVar.mutedStrong};'
              'padding:3px 9px;border-radius:${KolaRadius.pill}',
        },
        [
          Component.text(
            '$_queuedCount sale${_queuedCount == 1 ? '' : 's'} waiting to sync',
          ),
        ],
      );

  // ── Tablet/desktop: two-pane ─────────────────────────────────────────

  Component _tabletBody() => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:1fr 360px;height:100%',
        },
        [
          div(
            attributes: {'style': 'overflow-y:auto;height:100%;box-sizing:border-box'},
            [_tabletProductPanel()],
          ),
          div(
            attributes: {
              'style': 'border-left:1px solid ${KolaVar.border};display:flex;'
                  'flex-direction:column;box-sizing:border-box;height:100%;overflow:hidden',
            },
            [_rightRail()],
          ),
        ],
      );

  Component _tabletProductPanel() => div(
        attributes: {'style': 'padding:20px 24px;box-sizing:border-box'},
        [
          _searchRow(),
          _categoryChips(),
          _productGrid(columns: 4),
        ],
      );

  Component _rightRail() {
    switch (_screen) {
      case _Screen.sell:
        return _sellRail();
      case _Screen.payment:
        return _paymentRail();
      case _Screen.receipt:
        return _receiptRail();
    }
  }

  // ── Phone: single column ──────────────────────────────────────────

  // Same independent-scroll-region fix as the tablet rail (see
  // _sellRail's comment): the sell screen's totals+Charge footer is a
  // flex sibling OUTSIDE the scrolling content, not a `position:sticky`
  // child of it, so it stays pinned no matter how long the cart gets
  // rather than getting pushed down the page as products are added.
  Component _phoneBody() {
    if (_screen == _Screen.sell) {
      return div(
        attributes: {
          'style': 'max-width:420px;margin:0 auto;height:100%;display:flex;'
              'flex-direction:column;min-height:0',
        },
        [
          div(
            attributes: {'style': 'flex:1;min-height:0;overflow-y:auto'},
            [
              div(
                attributes: {'style': 'padding:14px 16px 0'},
                [_searchRow(), _categoryChips(), _productGrid(columns: 2)],
              ),
              if (_cart.isNotEmpty) _phoneCartList() else _phoneEmptyBasketNote(),
            ],
          ),
          _phoneSellFooter(),
          if (_mobileCartOpen) _phoneCartSheet(),
        ],
      );
    }
    return div(
      attributes: {
        'style': 'max-width:420px;margin:0 auto;height:100%;overflow-y:auto;box-sizing:border-box',
      },
      [_screen == _Screen.payment ? _phonePayment() : _phoneReceipt()],
    );
  }

  // ── Shared: search + categories + grid ────────────────────────────

  Component _searchRow() => div(
        [
          if (_catalogAsOf != null) _catalogStalenessNotice(),
          div(
            attributes: {'style': 'display:flex;gap:8px;margin-bottom:14px'},
            [
              input<String>(
                type: InputType.text,
                value: _search,
                onInput: (v) => setState(() => _search = v),
                attributes: {
                  'placeholder': 'Scan a barcode or search a product…',
                  'style': 'flex:1;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.md};padding:14px 16px;color:${KolaVar.text};'
                      'font-family:inherit;font-size:${KolaType.lead};box-sizing:border-box;'
                      'min-height:48px',
                },
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.md};width:48px;height:48px;flex:none;'
                      'cursor:pointer;color:${KolaVar.text};display:flex;align-items:center;'
                      'justify-content:center',
                },
                events: {'click': (_) => _openScanner()},
                [kolaIcon(Icons.barcode, size: 18, strokeWidth: 1.8)],
              ),
            ],
          ),
        ],
      );

  /// Phase 11g-f. DESIGN_BRIEF_COMMERCE.md §1's exact honesty
  /// requirement: *"Stock is last known, not certain. Say so plainly
  /// without making the number feel useless — '12 in stock, as of 9:40
  /// this morning.'"* Shown once, above the whole grid, rather than
  /// re-stating it on every single product tile — the brief's own
  /// example states the AS-OF time once and lets it apply to every
  /// number below it, which is also the only way this stays readable
  /// with more than a couple of products on screen.
  Component _catalogStalenessNotice() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:6px;'
              'background:${KolaVar.warningBg};color:${KolaVar.warning};'
              'border-radius:${KolaRadius.sm};padding:8px 12px;'
              'font-size:${KolaType.tiny};font-weight:600;margin-bottom:10px',
        },
        [
          Component.text(
            'Showing last-known prices and stock, as of ${_catalogTime(_catalogAsOf!)}.',
          ),
        ],
      );

  static String _catalogTime(DateTime at) {
    final local = at.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$suffix';
  }

  Component _categoryChips() {
    final cats = _categories;
    if (cats.isEmpty) return div([]);
    return div(
      attributes: {'style': 'display:flex;gap:6px;margin-bottom:16px;flex-wrap:wrap'},
      [
        _categoryChip(null, 'All'),
        for (final c in cats) _categoryChip(c, c),
      ],
    );
  }

  Component _categoryChip(String? id, String label) {
    final active = _category == id;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'padding:8px 14px;border-radius:${KolaRadius.pill};font-size:${KolaType.small};'
            'font-family:inherit;cursor:pointer;white-space:nowrap;'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _category = id)},
      [Component.text(label)],
    );
  }

  Component _productGrid({required int columns}) {
    if (_loading) return _gridSkeleton(columns: columns);
    if (_loadError != null) return _errorState();
    final filtered = _filteredProducts;
    if (_products.isEmpty) {
      return _emptyState('No products in your catalog yet. Add one in Catalog and it shows up here.');
    }
    if (filtered.isEmpty) {
      return _emptyState('Nothing matches that search.');
    }
    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:repeat($columns,1fr);gap:12px',
      },
      [for (final p in filtered) _productTile(p)],
    );
  }

  /// The tile's photo — a real one when the catalog has one, the same
  /// placeholder icon only when it genuinely doesn't. Mirrors
  /// catalog_page.dart's `_rowThumb`: original `url`, not the stored
  /// `thumbnailUrl` (see that file's own comment on why the thumbnail
  /// column doesn't resolve on this ImageKit account).
  Component _tileImage(Product p) {
    final media = p.id == null ? null : _mainImages[p.id];
    if (media == null) {
      return div(
        attributes: {
          'style': 'width:100%;aspect-ratio:1.4;background:${KolaVar.bg};'
              'display:flex;align-items:center;justify-content:center;flex:none',
        },
        [kolaIcon(Icons.imagePlaceholder, size: 22, strokeWidth: 1.7, extraStyle: 'color:${KolaVar.muted}')],
      );
    }
    return div(
      attributes: {'style': 'width:100%;aspect-ratio:1.4;background:${KolaVar.bg};flex:none'},
      [
        img(
          src: ImageKitUrl.thumb(media.url),
          alt: '',
          attributes: {
            'loading': 'lazy',
            'style': 'width:100%;height:100%;object-fit:cover;display:block',
          },
        ),
      ],
    );
  }

  Component _productTile(Product p) {
    final priced = p.priceMinor != null;
    final qty = _quantityInCart(p);
    // "Ask price" is a real, common catalog state for a service — not
    // missing data (product.spy.yaml's own header) — so the tile stays
    // pressable either way. A priced product adds straight to the cart;
    // an unpriced one opens a one-field prompt for what THIS sale
    // charges (see _openPriceEntry). Disabling the tile instead, as the
    // first pass did, meant a shop that sells services could never ring
    // up a large share of its own catalog.
    return button(
      attributes: {
        'type': 'button',
        'style': 'position:relative;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:0;text-align:left;cursor:pointer;'
            'font-family:inherit;color:${KolaVar.text};'
            'overflow:hidden;min-height:132px;display:flex;flex-direction:column',
      },
      events: {
        'click': (_) {
          if (priced) {
            _addToCart(p, p.priceMinor!);
          } else {
            _openPriceEntry(p);
          }
        },
      },
      [
        _tileImage(p),
        div(
          attributes: {
            'style': 'padding:10px 12px;flex:1;display:flex;flex-direction:column;'
                'justify-content:space-between',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap;margin-bottom:4px',
              },
              [Component.text(p.name)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'font-family:${KolaFonts.mono}',
              },
              [Component.text(priced ? formatMinor(p.priceMinor!) : 'Ask price')],
            ),
          ],
        ),
        if (qty > 0)
          div(
            attributes: {
              'style': 'position:absolute;top:8px;right:8px;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-size:${KolaType.micro};font-weight:700;'
                  'border-radius:${KolaRadius.pill};min-width:20px;height:20px;padding:0 6px;'
                  'display:flex;align-items:center;justify-content:center',
            },
            [Component.text('$qty')],
          ),
      ],
    );
  }

  // ── Tablet right rail: sell ───────────────────────────────────────

  // The root needs display:flex;flex-direction:column;height:100% of
  // its own — without it, `flex:1` on the item-list child below is
  // meaningless (nothing to grow WITHIN), the whole rail just grows to
  // fit its content, and the Charge button drifts down the page as the
  // cart fills. This is the fix for exactly that bug.
  Component _sellRail() => div(
        attributes: {
          'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
        },
        [
        div(
          attributes: {'style': 'padding:18px 20px;flex:1;min-height:0;overflow-y:auto'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};font-weight:700;color:${KolaVar.mutedStrong};'
                    'margin-bottom:12px;text-transform:uppercase;letter-spacing:0.04em',
              },
              [Component.text('Current sale · ${_cart.fold(0, (n, l) => n + l.quantity)} items')],
            ),
            if (_cart.isEmpty)
              div(
                attributes: {
                  'style': 'text-align:center;padding:44px 16px;color:${KolaVar.muted};'
                      'font-size:${KolaType.body}',
                },
                [Component.text('Tap a product to start a sale')],
              )
            else
              div(
                attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
                [for (final l in _cart) _railCartRow(l)],
              ),
          ],
        ),
        div(
          attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
          [
            _totalsRows(),
            button(
              attributes: {
                'type': 'button',
                if (_cart.isEmpty) 'disabled': 'disabled',
                'style': 'width:100%;background:${_cart.isNotEmpty ? KolaVar.accentFill : KolaVar.pill};'
                    'color:${_cart.isNotEmpty ? KolaVar.accentText : KolaVar.muted};border:none;'
                    'border-radius:${KolaRadius.lg};padding:16px;font-size:${KolaType.lead};'
                    'font-weight:700;font-family:inherit;'
                    'cursor:${_cart.isNotEmpty ? 'pointer' : 'default'};min-height:52px',
              },
              events: {
                'click': (_) {
                  if (_cart.isNotEmpty) {
                    setState(() => _screen = _Screen.payment);
                    unawaited(_pushDisplay());
                  }
                },
              },
              [Component.text('Charge ${formatMinor(_totalMinor)}')],
            ),
          ],
        ),
      ]);

  Component _railCartRow(_CartLine line) => div(
        attributes: {
          'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 14px',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;justify-content:space-between;gap:8px;margin-bottom:8px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                      'text-overflow:ellipsis;white-space:nowrap',
                },
                [Component.text(line.product.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-family:${KolaFonts.mono};flex:none',
                },
                [Component.text(formatMinor(line.lineTotalMinor))],
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:8px'},
            [
              _stepperButton('−', () => _dec(line)),
              span(
                attributes: {'style': 'font-size:${KolaType.body};width:24px;text-align:center'},
                [Component.text('${line.quantity}')],
              ),
              _stepperButton('+', () => _inc(line)),
              span(
                attributes: {
                  'style': 'flex:1;text-align:right;font-size:${KolaType.tiny};'
                      'color:${KolaVar.muted};font-family:${KolaFonts.mono}',
                },
                [Component.text('${formatMinor(line.unitPriceMinor)} ea')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:28px;height:28px;border-radius:${KolaRadius.sm};'
                      'background:${KolaVar.dangerBg};border:none;color:${KolaVar.danger};'
                      'font-size:${KolaType.body};cursor:pointer',
                },
                events: {'click': (_) => _removeLine(line)},
                [Component.text('×')],
              ),
            ],
          ),
        ],
      );

  Component _stepperButton(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'width:28px;height:28px;border-radius:${KolaRadius.sm};background:${KolaVar.pill};'
              'border:none;color:${KolaVar.text};font-size:${KolaType.lead};cursor:pointer',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _totalsRows() => div([
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};'
                'color:${KolaVar.muted};margin-bottom:4px',
          },
          [Component.text('Subtotal'), Component.text(formatMinor(_subtotalMinor))],
        ),
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;font-size:${KolaType.body};'
                'color:${KolaVar.muted};margin-bottom:10px',
          },
          [
            Component.text('VAT (${(component.taxRateBps / 100).toStringAsFixed(1)}%)'),
            Component.text(formatMinor(_taxMinor)),
          ],
        ),
      ]);

  // ── Tablet right rail: payment ────────────────────────────────────

  Component _paymentRail() => div(
        attributes: {
          'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
        },
        [
          div(
            attributes: {'style': 'padding:18px 20px;flex:1;min-height:0;overflow-y:auto'},
            [_paymentBody()],
          ),
          div(
            attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
            [_paymentActions()],
          ),
        ],
      );

  Component _paymentBody() => div([
        button(
          attributes: {
            'type': 'button',
            'style': 'background:transparent;border:none;color:${KolaVar.muted};'
                'font-family:inherit;font-size:${KolaType.body};cursor:pointer;padding:0 0 14px;'
                'display:flex;align-items:center;gap:3px',
          },
          events: {'click': (_) => setState(() => _screen = _Screen.sell)},
          [kolaIcon(Icons.chevronLeft, size: 12, strokeWidth: 2.5), Component.text('Back to sale')],
        ),
        div(
          attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:4px'},
          [Component.text('Total due')],
        ),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.display};font-size:${KolaType.display};'
                'font-weight:700;margin-bottom:18px',
          },
          [Component.text(formatMinor(_totalMinor))],
        ),
        _customerNameField(),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:16px',
          },
          [for (final m in const ['Cash', 'Transfer', 'Card', 'Split']) _paymentMethodButton(m)],
        ),
        if (_payMethod == 'Cash') _cashPanel(),
        if (_chargeError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};line-height:1.5;'
                  'margin-bottom:12px',
            },
            [Component.text(_chargeError!)],
          ),
      ]);

  /// Phase 14a-3. The owner's own instruction: "add a name field" at
  /// the charge step, print a personalized thank-you when given, and
  /// stay a complete normal sale when not — see `_customerName`'s own
  /// field comment and `_receiptBody`'s thank-you line. Deliberately
  /// optional (no red asterisk, no validation) — a walk-in sale with no
  /// name is the common case this whole screen is built for, not an
  /// error state.
  Component _customerNameField() => div(
        attributes: {'style': 'margin-bottom:16px'},
        [
          div(
            attributes: {'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:6px'},
            [Component.text('Customer name (optional)')],
          ),
          input<String>(
            type: InputType.text,
            value: _customerName,
            onInput: (v) => setState(() => _customerName = v),
            attributes: {
              'placeholder': 'e.g. Amaka',
              'style': 'width:100%;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.sm};padding:11px 13px;color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body};box-sizing:border-box',
            },
          ),
        ],
      );

  Component _paymentMethodButton(String method) {
    final active = _payMethod == method;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : KolaVar.card};'
            'color:${active ? KolaVar.text : KolaVar.mutedStrong};border-radius:${KolaRadius.md};'
            'padding:14px;font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
            'cursor:pointer;min-height:52px',
      },
      events: {'click': (_) => setState(() => _payMethod = method)},
      [Component.text(method)],
    );
  }

  Component _cashPanel() {
    final change = _changeMinor;
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:16px;margin-bottom:16px',
      },
      [
        div(
          attributes: {'style': 'font-size:${KolaType.small};color:${KolaVar.muted};margin-bottom:8px'},
          [Component.text('Cash received')],
        ),
        input<String>(
          type: InputType.text,
          value: _cashReceived,
          onInput: (v) => setState(() => _cashReceived = v),
          attributes: {
            'placeholder': '₦0',
            'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.sm};padding:13px 14px;color:${KolaVar.text};'
                'font-family:${KolaFonts.mono};font-size:${KolaType.title};box-sizing:border-box;'
                'margin-bottom:10px',
          },
        ),
        div(
          attributes: {'style': 'display:flex;justify-content:space-between;font-size:${KolaType.ui}'},
          [
            span(attributes: {'style': 'color:${KolaVar.muted}'}, [Component.text('Change due')]),
            span(
              attributes: {
                'style': 'font-weight:700;font-family:${KolaFonts.mono};'
                    'color:${change < 0 ? KolaVar.danger : KolaVar.success}',
              },
              [Component.text(formatMinor(change < 0 ? 0 : change))],
            ),
          ],
        ),
      ],
    );
  }

  Component _paymentActions() => div([
        button(
          attributes: {
            'type': 'button',
            if (_completeDisabled) 'disabled': 'disabled',
            'style': 'width:100%;background:${_completeDisabled ? KolaVar.pill : KolaVar.accentFill};'
                'color:${_completeDisabled ? KolaVar.muted : KolaVar.accentText};border:none;'
                'border-radius:${KolaRadius.lg};padding:16px;font-size:${KolaType.lead};'
                'font-weight:700;font-family:inherit;'
                'cursor:${_completeDisabled ? 'default' : 'pointer'};min-height:52px;margin-bottom:8px',
          },
          events: {
            'click': (_) {
              if (!_completeDisabled) _completeSale();
            },
          },
          [Component.text(_charging ? 'Completing…' : 'Complete sale')],
        ),
        button(
          attributes: {
            'type': 'button',
            'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.dangerBg};'
                'color:${KolaVar.danger};border-radius:${KolaRadius.lg};padding:11px;'
                'font-size:${KolaType.body};font-family:inherit;cursor:pointer;min-height:44px',
          },
          events: {'click': (_) => _voidSale()},
          [Component.text('Cancel sale')],
        ),
      ]);

  // ── Tablet right rail: receipt ────────────────────────────────────

  Component _receiptRail() {
    final completed = _completed;
    if (completed == null) return div([]);
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;height:100%;min-height:0',
      },
      [
      div(
        attributes: {'style': 'padding:22px 20px;flex:1;min-height:0;overflow-y:auto'},
        [_receiptBody(completed)],
      ),
      div(
        attributes: {'style': 'padding:16px 20px;border-top:1px solid ${KolaVar.border}'},
        [_newSaleButton()],
      ),
    ]);
  }

  Component _receiptBody(_CompletedSale completed) => div([
        div(
          attributes: {'style': 'text-align:center;margin-bottom:16px'},
          [
            div(
              attributes: {
                'style': 'width:44px;height:44px;border-radius:50%;'
                    'background:${completed.queued ? KolaVar.warningBg : KolaVar.successBg};'
                    'color:${completed.queued ? KolaVar.warning : KolaVar.successBright};'
                    'display:flex;align-items:center;'
                    'justify-content:center;font-size:${KolaType.h2};margin:0 auto 10px',
              },
              // Phase 11g-c: '↻' rather than '✓' when queued — this sale
              // is real and the payment happened, but it isn't ON the
              // server yet, and a checkmark would say otherwise.
              [Component.text(completed.queued ? '↻' : '✓')],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.lead};font-weight:600'},
              [Component.text('Sale complete')],
            ),
            if (completed.queued)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'margin-top:4px;max-width:260px;margin-left:auto;margin-right:auto',
                },
                // Per DESIGN_BRIEF_COMMERCE.md §1: reassuring, never a
                // stack trace or "failed" wording — the sale is done,
                // only the sync is pending.
                [Component.text('Saved on this device. Will sync automatically once you\'re back online.')],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};padding:14px;font-family:${KolaFonts.mono};'
                'font-size:${KolaType.tiny};line-height:1.7;margin-bottom:14px',
          },
          [
            for (final l in completed.lines)
              div(
                attributes: {'style': 'display:flex;justify-content:space-between'},
                [
                  Component.text('${l.product.name} ×${l.quantity}'),
                  Component.text(formatMinor(l.lineTotalMinor)),
                ],
              ),
            div(
              attributes: {
                'style': 'border-top:1px dashed ${KolaVar.border};margin:6px 0;padding-top:6px;'
                    'display:flex;justify-content:space-between;font-weight:700',
              },
              [Component.text('Total'), Component.text(formatMinor(completed.sale.totalMinor))],
            ),
            div(
              attributes: {'style': 'color:${KolaVar.muted}'},
              [Component.text('Paid by ${completed.paidLabel}')],
            ),
          ],
        ),
        _thankYouNote(completed),
        div(
          attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
          [
            _whatsAppButton(completed),
            // Phase 14a-1. See `_printButton`'s own header: a synced
            // sale navigates to /documents (real print scoping, no
            // network fetch needed beyond what that page already does
            // since this IS its most recent sale); a queued sale still
            // gets the direct client-side print DESIGN_BRIEF_COMMERCE
            // .md §1 requires ("print or share a receipt" with zero
            // connection), since /documents has nothing to show it yet.
            _printButton(completed),
          ],
        ),
      ]);

  /// Phase 14a-3. The owner's own wording, verbatim: "Thank you, {name},
  /// for shopping with us — we appreciate you 💛". Renders nothing at
  /// all when `completed.customerName` is null/blank (see that field's
  /// own comment) — a walk-in sale with no name prints a normal receipt
  /// with no personalized line, not a broken "Thank you, , for..."
  /// sentence.
  Component _thankYouNote(_CompletedSale completed) {
    final name = completed.customerName?.trim();
    if (name == null || name.isEmpty) return div([]);
    return div(
      attributes: {
        'style': 'background:${KolaVar.warningBg};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:12px 14px;margin-bottom:14px;'
            'font-size:${KolaType.small};color:${KolaVar.text};text-align:center;line-height:1.5',
      },
      [Component.text('Thank you, $name, for shopping with us — we appreciate you 💛')],
    );
  }

  Component _whatsAppButton(_CompletedSale completed) => button(
        attributes: {
          'type': 'button',
          'style': 'background:${KolaVar.success};color:${KolaVar.accentText};border:none;'
              'border-radius:${KolaRadius.md};padding:13px;font-size:${KolaType.body};'
              'font-weight:600;font-family:inherit;cursor:pointer;display:flex;align-items:center;'
              'justify-content:center;gap:6px',
        },
        events: {'click': (_) => _openWhatsAppPrompt()},
        [kolaIcon(Icons.whatsapp, size: 14, strokeWidth: 1.8), Component.text('Send on WhatsApp')],
      );

  /// Phase 14a-1. Previously called `web.window.print()` directly on
  /// THIS page — the owner's report: that prints the wrong thing,
  /// because till_page.dart carries none of documents_page.dart's own
  /// `#kola-print-area` CSS trick (see that file's `_printStyles`), so
  /// printing straight from here would grab the whole till chrome
  /// (header, connection badge, whatever's behind the receipt), not a
  /// clean document. Fixed the way the owner asked: do what the
  /// (now-removed, see `_header`) "Documents" button always did — send
  /// the cashier to the real document surface, which already scopes
  /// printing correctly.
  ///
  /// NOT a `Link` to `/invoices` for a specific invoice id, even though
  /// invoices_page.dart (Phase 14a-4) now exists: an Invoice requires a
  /// bill-to name (InvoiceEndpoint.createInvoice's own validation), and
  /// a walk-in sale may genuinely have none (see this file's header,
  /// "NO CUSTOMER CAPTURE" — now "optional customer capture" per
  /// `_customerNameField`, but still optional). Auto-creating an invoice
  /// on every tap of Print would either invent a bill-to name or throw
  /// for the common walk-in case. `/documents` needs no name at all and
  /// shows exactly this sale — right after `ringUpSale`, it IS the most
  /// recent — with the same real print scoping.
  ///
  /// A queued (offline) sale is the one case this can't serve — see
  /// `_CompletedSale.queued`'s header: it hasn't reached the server, so
  /// `/documents` (which reads real Sale rows) has nothing to show for
  /// it. That case keeps the direct client-side `window.print()` this
  /// page already had — a plain, non-overloaded DOM method, same
  /// reasoning `dom_files.dart`'s header applies to `download`/`click`
  /// — printing the receipt screen itself rather than nothing at all.
  Component _printButton(_CompletedSale completed) {
    if (completed.queued) {
      return button(
        attributes: {
          'type': 'button',
          'style': 'text-align:center;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'color:${KolaVar.text};border-radius:${KolaRadius.md};padding:13px;'
              'font-size:${KolaType.body};font-family:inherit;cursor:pointer;display:block;width:100%',
        },
        events: {'click': (_) => web.window.print()},
        [Component.text('Print')],
      );
    }
    // Declarative navigation, per this codebase's own rule (see
    // create_bot_page.dart's header: "no Router.of(context).push
    // anywhere in lib/, every transition is a jaspr_router Link").
    return Link(
      to: '/documents',
      attributes: {
        'style': 'text-align:center;background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'color:${KolaVar.text};border-radius:${KolaRadius.md};padding:13px;'
            'font-size:${KolaType.body};font-family:inherit;cursor:pointer;display:block;width:100%;'
            'text-decoration:none;box-sizing:border-box',
      },
      children: [Component.text('Print')],
    );
  }

  Component _newSaleButton() => button(
        attributes: {
          'type': 'button',
          'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
              'border:none;border-radius:${KolaRadius.lg};padding:15px;font-size:${KolaType.uiLg};'
              'font-weight:700;font-family:inherit;cursor:pointer;min-height:50px',
        },
        events: {'click': (_) => _newSale()},
        [Component.text('New sale')],
      );

  // ── "Send on WhatsApp" phone prompt (Phase 14a-2) ───────────────────
  //
  // The till is a front-of-store, walk-in screen — there is no
  // logged-in customer whose phone this could default to (see the file
  // header's old "NO CUSTOMER CAPTURE" note). Before this, tapping
  // "Send on WhatsApp" always opened the bare share picker with no
  // recipient — real, but not what "send on WhatsApp" implies. This
  // prompts for a number first, same modal shape `_priceEntryModal`
  // already uses on this page.
  //
  // STAYS ON THE EXISTING wa.me DEEP-LINK MECHANISM, DELIBERATELY NOT
  // Gate 8's OutboundMessageService (kola_server/lib/src/services/
  // messaging/outbound_message_service.dart) — named here rather than
  // silently decided, per this project's own DESIGN_DELTA.md rule.
  // Gate 8 sends server-side through the workspace's OWN connected
  // WhatsApp Business channel and is exposed only as an API-key-gated
  // REST route (`POST /v1/messages`) for external callers, not a
  // session-authenticated Serverpod endpoint this dashboard's Client
  // can call — reaching it from here would mean hand-adding a brand
  // new endpoint method AND a new generated-client method with no Dart
  // toolchain in this environment to verify either compiles (see this
  // repo's own standing constraint on generated code). The wa.me link
  // is the same mechanism this file already shipped and already proved
  // out (`_digitalTab`'s WhatsApp preview on documents_page.dart uses
  // the identical approach) — now just targeted at a real number
  // instead of the bare picker.
  void _openWhatsAppPrompt() => setState(() {
        _whatsAppPromptOpen = true;
        _whatsAppPhone = '';
        _whatsAppPhoneError = null;
      });

  void _closeWhatsAppPrompt() => setState(() => _whatsAppPromptOpen = false);

  /// Nigerian format only, per the owner's own scope ("no need for
  /// exotic international validation") — a local 11-digit number
  /// starting with 0 is rewritten to the 234 country code wa.me needs
  /// to open a specific chat; anything already carrying a country code
  /// (or a number from elsewhere) is passed through digit-stripped and
  /// unmodified.
  String _normalizeNgPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '234${digits.substring(1)}';
    }
    return digits;
  }

  void _submitWhatsAppPrompt() {
    final digits = _normalizeNgPhone(_whatsAppPhone);
    if (digits.length < 10) {
      setState(() => _whatsAppPhoneError = 'Enter a valid phone number.');
      return;
    }
    final completed = _completed;
    if (completed == null) return;
    setState(() => _whatsAppPromptOpen = false);
    _openWhatsAppReceipt(completed, digits);
  }

  Component _whatsAppPromptModal() => div(
        attributes: {
          'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:100;'
              'display:flex;align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => _closeWhatsAppPrompt()},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:26px;width:100%;max-width:340px;'
                  'box-sizing:border-box',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {'style': 'font-size:${KolaType.bodyLg};font-weight:600;margin-bottom:4px'},
                [Component.text('Send receipt on WhatsApp')],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:14px',
                },
                [Component.text("Enter the customer's WhatsApp number.")],
              ),
              input<String>(
                type: InputType.text,
                value: _whatsAppPhone,
                onInput: (v) => setState(() => _whatsAppPhone = v),
                attributes: {
                  'placeholder': '0803 123 4567',
                  'autofocus': 'autofocus',
                  'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.sm};padding:13px 14px;color:${KolaVar.text};'
                      'font-family:${KolaFonts.mono};font-size:${KolaType.title};box-sizing:border-box;'
                      'margin-bottom:10px',
                },
                events: {
                  'keydown': (e) {
                    final ev = e as web.KeyboardEvent;
                    if (ev.key == 'Enter') _submitWhatsAppPrompt();
                  },
                },
              ),
              if (_whatsAppPhoneError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px',
                  },
                  [Component.text(_whatsAppPhoneError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:${KolaVar.success};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:pointer;min-height:44px;margin-bottom:8px;display:flex;'
                      'align-items:center;justify-content:center;gap:6px',
                },
                events: {'click': (_) => _submitWhatsAppPrompt()},
                [kolaIcon(Icons.whatsapp, size: 14, strokeWidth: 1.8), Component.text('Send')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.muted};border-radius:${KolaRadius.pill};padding:11px;'
                      'font-size:${KolaType.body};font-family:inherit;cursor:pointer',
                },
                events: {'click': (_) => _closeWhatsAppPrompt()},
                [Component.text('Cancel')],
              ),
            ],
          ),
        ],
      );

  /// Real, but scope-cut to what a shop can use without the WhatsApp
  /// Business API's template-approval flow: a wa.me deep link opens the
  /// owner's own WhatsApp with the receipt text pre-filled, addressed to
  /// [phoneDigits] (see `_normalizeNgPhone`) — Phase 14a-2, previously
  /// always opened the bare picker with no recipient (see this method's
  /// call sites' own header for why this stays wa.me rather than moving
  /// to Gate 8's server-side send).
  void _openWhatsAppReceipt(_CompletedSale completed, String phoneDigits) {
    final buffer = StringBuffer()
      ..writeln('${component.workspaceName} — receipt ${completed.sale.reference}')
      ..writeln();
    for (final l in completed.lines) {
      buffer.writeln('${l.product.name} ×${l.quantity}  ${formatMinor(l.lineTotalMinor)}');
    }
    buffer
      ..writeln()
      ..writeln('Total: ${formatMinor(completed.sale.totalMinor)}')
      ..writeln('Paid by ${completed.paidLabel}');
    final url = 'https://wa.me/$phoneDigits?text=${Uri.encodeComponent(buffer.toString())}';
    web.window.open(url, '_blank');
  }

  // ── Phone screens ──────────────────────────────────────────────────

  Component _phoneCartList() => div(
        attributes: {'style': 'padding:0 16px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:700;color:${KolaVar.mutedStrong};'
                  'margin-bottom:8px;text-transform:uppercase;letter-spacing:0.04em',
            },
            [Component.text('Current sale')],
          ),
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:8px;margin-bottom:14px'},
            [for (final l in _cart) _phoneCartRow(l)],
          ),
        ],
      );

  Component _phoneCartRow(_CartLine line) => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:12px 14px;display:flex;'
              'align-items:center;gap:10px',
        },
        [
          div(
            attributes: {'style': 'flex:1;min-width:0'},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;overflow:hidden;'
                      'text-overflow:ellipsis;white-space:nowrap',
                },
                [Component.text(line.product.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                      'font-family:${KolaFonts.mono}',
                },
                [
                  Component.text(
                    '${formatMinor(line.unitPriceMinor)} × ${line.quantity} = '
                    '${formatMinor(line.lineTotalMinor)}',
                  ),
                ],
              ),
            ],
          ),
          _phoneStepperButton('−', () => _dec(line)),
          _phoneStepperButton('+', () => _inc(line)),
          button(
            attributes: {
              'type': 'button',
              'style': 'width:34px;height:34px;border-radius:${KolaRadius.sm};'
                  'background:${KolaVar.dangerBg};border:none;color:${KolaVar.danger};'
                  'font-size:${KolaType.ui};cursor:pointer;flex:none',
            },
            events: {'click': (_) => _removeLine(line)},
            [Component.text('×')],
          ),
        ],
      );

  Component _phoneStepperButton(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'width:34px;height:34px;border-radius:${KolaRadius.sm};background:${KolaVar.pill};'
              'border:none;color:${KolaVar.text};font-size:${KolaType.subhead};cursor:pointer;flex:none',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _phoneEmptyBasketNote() => div(
        attributes: {
          'style': 'text-align:center;padding:30px 20px;color:${KolaVar.muted};'
              'font-size:${KolaType.body}',
        },
        [Component.text('Basket is empty — tap a product or scan a barcode')],
      );

  /// Tappable row shown in the pinned footer whenever the cart is
  /// non-empty. This is the actual entry point for the scroll-bug fix —
  /// see _phoneSellFooter's comment above its call site. Reachable
  /// without scrolling because the footer itself never scrolls.
  Component _phoneCartSummaryBar() {
    final itemCount = _cart.fold<int>(0, (sum, l) => sum + l.quantity);
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;justify-content:space-between;'
            'background:${KolaVar.pill};border-radius:${KolaRadius.md};'
            'padding:10px 14px;margin-bottom:10px;cursor:pointer',
        'role': 'button',
      },
      events: {'click': (_) => setState(() => _mobileCartOpen = true)},
      [
        div(
          attributes: {'style': 'font-size:${KolaType.body};font-weight:600'},
          [
            Component.text(
              'Current sale · $itemCount item${itemCount == 1 ? '' : 's'} · tap to edit',
            ),
          ],
        ),
        div(
          attributes: {'style': 'font-size:${KolaType.body};color:${KolaVar.muted}'},
          [Component.text('▲')],
        ),
      ],
    );
  }

  /// Bottom sheet giving mobile access to _phoneCartRow's −/+/× controls
  /// from anywhere in the product grid, with zero scrolling — see
  /// _phoneSellFooter's comment for the bug this fixes. Mirrors
  /// MobileMoreSheet's established scrim/panel pattern
  /// (mobile_chrome.dart) rather than inventing a new one.
  Component _phoneCartSheet() => div(
        attributes: {
          'style': 'position:fixed;inset:0;z-index:200;'
              'background:rgba(0,0,0,0.55);display:flex;align-items:flex-end',
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': 'Current sale',
        },
        events: {'click': (_) => setState(() => _mobileCartOpen = false)},
        [
          div(
            attributes: {
              'style': 'width:100%;background:${KolaVar.card};'
                  'border-top-left-radius:${KolaRadius.xl};'
                  'border-top-right-radius:${KolaRadius.xl};'
                  'border-top:1px solid ${KolaVar.border};'
                  'padding:10px 16px calc(20px + env(safe-area-inset-bottom, 0px));'
                  'max-height:75vh;overflow-y:auto;overscroll-behavior:contain',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'width:36px;height:4px;background:${KolaVar.border};'
                      'border-radius:${KolaRadius.pill};margin:2px auto 14px',
                },
                [],
              ),
              div(
                attributes: {
                  'style': 'display:flex;align-items:center;justify-content:space-between;'
                      'margin-bottom:12px',
                },
                [
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.subhead};font-weight:700',
                    },
                    [Component.text('Current sale')],
                  ),
                  button(
                    attributes: {
                      'type': 'button',
                      'style': 'background:${KolaVar.pill};border:none;'
                          'border-radius:${KolaRadius.pill};padding:8px 16px;'
                          'font-size:${KolaType.body};font-weight:600;'
                          'color:${KolaVar.text};cursor:pointer',
                    },
                    events: {'click': (_) => setState(() => _mobileCartOpen = false)},
                    [Component.text('Done')],
                  ),
                ],
              ),
              if (_cart.isEmpty)
                _phoneEmptyBasketNote()
              else
                div(
                  attributes: {
                    'style': 'display:flex;flex-direction:column;gap:8px',
                  },
                  [for (final l in _cart) _phoneCartRow(l)],
                ),
            ],
          ),
        ],
      );

  // A flex sibling of the scrolling content above it (see _phoneBody),
  // not `position:sticky` — sticky only pins within its OWN scroll
  // ancestor, which was the entire page here, so as the cart grew this
  // footer scrolled along with it instead of staying put. flex:none
  // (the default for a non-flex parent's child) plus a bounded-height
  // ancestor is what actually keeps it in place.
  Component _phoneSellFooter() => div(
        attributes: {
          'style': 'flex:none;background:${KolaVar.bg};'
              'border-top:1px solid ${KolaVar.border};padding:14px 16px 18px;box-sizing:border-box',
        },
        [
          // THE FIX for a real reported bug: "when I start adding a
          // product for sales, I have to scroll down to increase or
          // decrease the products before selling or even deleting.
          // imagine I have 100 products, I have to scroll to the 100th
          // before doing anything." Tapping a product tile only ever
          // INCREMENTS it (see _productTile) — decreasing a quantity or
          // removing a line needed _phoneCartRow's −/+/× buttons, and
          // those lived in _phoneCartList, BELOW THE ENTIRE PRODUCT
          // GRID in scroll order (see _phoneBody). With a long catalog,
          // reaching them meant scrolling past every product first.
          // This bar is always visible (it's part of the pinned
          // footer, outside the grid's scroll region — see _phoneBody's
          // own comment on why the footer is a flex sibling, not
          // sticky) and opens a bottom sheet with the same
          // −/+/× controls, reachable from anywhere in the grid with
          // zero scrolling.
          if (_cart.isNotEmpty) _phoneCartSummaryBar(),
          _totalsRows(),
          button(
            attributes: {
              'type': 'button',
              if (_cart.isEmpty) 'disabled': 'disabled',
              'style': 'width:100%;background:${_cart.isNotEmpty ? KolaVar.accentFill : KolaVar.pill};'
                  'color:${_cart.isNotEmpty ? KolaVar.accentText : KolaVar.muted};border:none;'
                  'border-radius:${KolaRadius.lg};padding:17px;font-size:${KolaType.subhead};'
                  'font-weight:700;font-family:inherit;'
                  'cursor:${_cart.isNotEmpty ? 'pointer' : 'default'};min-height:56px',
            },
            events: {
              'click': (_) {
                if (_cart.isNotEmpty) {
                  setState(() => _screen = _Screen.payment);
                  unawaited(_pushDisplay());
                }
              },
            },
            [Component.text('Charge ${formatMinor(_totalMinor)}')],
          ),
        ],
      );

  Component _phonePayment() => div(
        attributes: {'style': 'padding:8px 16px 24px'},
        [_paymentBody(), _paymentActions()],
      );

  Component _phoneReceipt() {
    final completed = _completed;
    if (completed == null) return div([]);
    return div(
      attributes: {'style': 'padding:20px 16px'},
      [
        div(
          attributes: {'style': 'text-align:center;margin-bottom:18px'},
          [
            div(
              attributes: {
                'style': 'width:52px;height:52px;border-radius:50%;'
                    'background:${completed.queued ? KolaVar.warningBg : KolaVar.successBg};'
                    'color:${completed.queued ? KolaVar.warning : KolaVar.successBright};'
                    'display:flex;align-items:center;'
                    'justify-content:center;font-size:${KolaType.h3};margin:0 auto 12px',
              },
              [Component.text(completed.queued ? '↻' : '✓')],
            ),
            div(
              attributes: {'style': 'font-size:${KolaType.title};font-weight:600'},
              [Component.text('Sale complete')],
            ),
            if (completed.queued)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-top:4px',
                },
                [Component.text('Saved on this device. Will sync automatically once you\'re back online.')],
              ),
          ],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:18px;font-family:${KolaFonts.mono};'
                'font-size:${KolaType.small};line-height:1.8;margin-bottom:16px',
          },
          [
            div(
              attributes: {
                'style': 'font-weight:700;font-family:${KolaFonts.sans};font-size:${KolaType.ui};'
                    'margin-bottom:8px',
              },
              [Component.text(component.workspaceName)],
            ),
            for (final l in completed.lines)
              div(
                attributes: {'style': 'display:flex;justify-content:space-between'},
                [
                  Component.text('${l.product.name} ×${l.quantity}'),
                  Component.text(formatMinor(l.lineTotalMinor)),
                ],
              ),
            div(
              attributes: {
                'style': 'border-top:1px dashed ${KolaVar.border};margin:8px 0;padding-top:8px;'
                    'display:flex;justify-content:space-between;font-weight:700',
              },
              [Component.text('Total'), Component.text(formatMinor(completed.sale.totalMinor))],
            ),
            div(
              attributes: {'style': 'color:${KolaVar.muted}'},
              [Component.text('Paid by ${completed.paidLabel}')],
            ),
          ],
        ),
        _thankYouNote(completed),
        div(
          attributes: {
            'style': 'display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px',
          },
          [_whatsAppButton(completed), _printButton(completed)],
        ),
        _newSaleButton(),
      ],
    );
  }

  // ── Barcode scanner modal ──────────────────────────────────────────

  Component _scannerModal() => div(
        attributes: {
          'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:100;'
              'display:flex;align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => _closeScanner()},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:26px;width:100%;max-width:340px;'
                  'box-sizing:border-box;text-align:center',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'width:100%;aspect-ratio:1;background:#000;'
                      'border-radius:${KolaRadius.lg};position:relative;overflow:hidden;'
                      'margin-bottom:16px;display:flex;align-items:center;justify-content:center',
                },
                [
                  // Always in the tree so `_startCamera` has a real
                  // element to attach the stream to by the time it
                  // queries for it — hidden via opacity, not `if`-removed,
                  // so it never needs to be found on a later rebuild.
                  Component.element(
                    tag: 'video',
                    attributes: {
                      'id': 'kola-scanner-video',
                      'style': 'width:100%;height:100%;object-fit:cover;'
                          'opacity:${_cameraActive ? '1' : '0'}',
                    },
                    children: const [],
                  ),
                  if (!_cameraActive)
                    div(
                      attributes: {'style': 'position:absolute;inset:0;display:flex;align-items:center;'
                          'justify-content:center'},
                      [kolaIcon(Icons.barcode, size: 40, strokeWidth: 1.6, extraStyle: 'color:${KolaVar.muted}')],
                    ),
                  if (_cameraActive)
                    div(
                      attributes: {
                        'style': 'position:absolute;inset:24px;border:2px solid ${KolaVar.accent};'
                            'border-radius:${KolaRadius.sm};pointer-events:none',
                      },
                      [],
                    ),
                ],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};color:${KolaVar.mutedStrong};margin-bottom:6px',
                },
                [
                  Component.text(
                    _cameraActive
                        ? 'Point the camera at a barcode'
                        : _cameraStarting
                            ? 'Starting camera…'
                            : 'No camera scanner on this browser',
                  ),
                ],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:14px',
                },
                [Component.text('Or type or scan a product\'s SKU with a handheld scanner')],
              ),
              input<String>(
                type: InputType.text,
                value: _scanInput,
                onInput: (v) => setState(() => _scanInput = v),
                attributes: {
                  'placeholder': 'SKU or product name',
                  'autofocus': 'autofocus',
                  'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.sm};padding:11px 13px;color:${KolaVar.text};'
                      'font-family:${KolaFonts.mono};font-size:${KolaType.body};box-sizing:border-box;'
                      'margin-bottom:10px',
                },
                events: {
                  'keydown': (e) {
                    // Hardware barcode scanners emit a trailing Enter —
                    // this is what makes them work here with no extra
                    // wiring beyond focusing this field. Same cast
                    // app_shell.dart's ⌘K listener and ask_kola.dart's
                    // Enter-to-send already use.
                    final ev = e as web.KeyboardEvent;
                    if (ev.key == 'Enter') _submitScan();
                  },
                },
              ),
              if (_scanError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px',
                  },
                  [Component.text(_scanError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:pointer;min-height:44px;margin-bottom:8px',
                },
                events: {'click': (_) => _submitScan()},
                [Component.text('Add to sale')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.muted};border-radius:${KolaRadius.pill};padding:11px;'
                      'font-size:${KolaType.body};font-family:inherit;cursor:pointer',
                },
                events: {'click': (_) => _closeScanner()},
                [Component.text('Cancel')],
              ),
            ],
          ),
        ],
      );

  // ── "Ask price" entry modal ───────────────────────────────────────

  Component _priceEntryModal(Product p) => div(
        attributes: {
          'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:100;'
              'display:flex;align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => _closePriceEntry()},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:26px;width:100%;max-width:340px;'
                  'box-sizing:border-box',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;margin-bottom:4px',
                },
                [Component.text(p.name)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};margin-bottom:14px',
                },
                [Component.text('This is an "Ask price" item — enter what to charge for this sale.')],
              ),
              input<String>(
                type: InputType.text,
                value: _priceEntryInput,
                onInput: (v) => setState(() => _priceEntryInput = v),
                attributes: {
                  'placeholder': '₦0',
                  'autofocus': 'autofocus',
                  'style': 'width:100%;background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.sm};padding:13px 14px;color:${KolaVar.text};'
                      'font-family:${KolaFonts.mono};font-size:${KolaType.title};box-sizing:border-box;'
                      'margin-bottom:10px',
                },
                events: {
                  'keydown': (e) {
                    final ev = e as web.KeyboardEvent;
                    if (ev.key == 'Enter') _submitPriceEntry();
                  },
                },
              ),
              if (_priceEntryError != null)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};margin-bottom:10px',
                  },
                  [Component.text(_priceEntryError!)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                      'border:none;border-radius:${KolaRadius.pill};padding:12px;'
                      'font-size:${KolaType.bodyLg};font-weight:600;font-family:inherit;'
                      'cursor:pointer;min-height:44px;margin-bottom:8px',
                },
                events: {'click': (_) => _submitPriceEntry()},
                [Component.text('Add to sale')],
              ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'width:100%;background:transparent;border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.muted};border-radius:${KolaRadius.pill};padding:11px;'
                      'font-size:${KolaType.body};font-family:inherit;cursor:pointer',
                },
                events: {'click': (_) => _closePriceEntry()},
                [Component.text('Cancel')],
              ),
            ],
          ),
        ],
      );

  // ── Shared states ──────────────────────────────────────────────────

  Component _emptyState(String message) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};border-radius:${KolaRadius.md};'
              'padding:${KolaSpace.lg};text-align:center;font-size:${KolaType.small};'
              'color:${KolaVar.muted}',
        },
        [Component.text(message)],
      );

  Component _gridSkeleton({required int columns}) => div(
        attributes: {
          'style': 'display:grid;grid-template-columns:repeat($columns,1fr);gap:12px',
        },
        [
          for (var i = 0; i < columns * 2; i++)
            div(
              attributes: {
                'style': 'height:132px;border-radius:${KolaRadius.lg};'
                    'border:1px solid ${KolaVar.border};background:${KolaVar.card}',
              },
              const [],
            ),
        ],
      );

  Component _errorState() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};border-radius:${KolaRadius.lg};'
              'background:${KolaVar.card};padding:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load your catalog')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};line-height:1.55;'
                  'margin-bottom:12px',
            },
            [Component.text('This is a connection problem. Nothing here has changed.')],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:9px 15px;border-radius:${KolaRadius.sm};border:none;'
                  'background:${KolaVar.accentFill};color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );
}

/// Phase 11g-e. Same small helper `customers_page.dart` already defines
/// privately for the identical need — not worth a shared import for one
/// three-line extension used in exactly two files.
extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
