// feature_keys.dart
//
// THE FEATURE REGISTRY. Every gateable capability, declared once.
//
// WHY THIS IS A DART CONSTANT LIST AND NOT "just rows in a table":
//   Feature keys are referenced in code — `requireFeature(FeatureKeys
//   .observations)` inside an endpoint. If the only definition lived in
//   the database, a typo would compile fine and then silently resolve to
//   "unknown feature", which fail-closed logic turns into "disabled",
//   which presents as a working build where a whole feature is quietly
//   invisible. That is the worst failure mode this system can produce.
//
//   So: this file is the source of truth for WHICH features exist. The
//   database is the source of truth for WHAT STATE each one is in.
//   [allKeys] is what the seed and the admin app's reconciliation check
//   against — a key here with no database row is a deployment error the
//   admin dashboard surfaces loudly, not something that silently does
//   nothing.
//
// HOW GATING WORKS: a capability ships to production in `locked` state —
// built, deployed, and not visible — and its state is changed later from
// the admin application. Nothing is deployed at that point; it is a
// database state change. See feature_flag_service.dart for the
// resolution order.
//
// NAMING: `area.capability`, lowercase, dot-separated, never renamed
// once shipped. A key is a permanent identifier; the display name (in
// the database) is what changes when something is renamed. Renaming a
// key orphans every override row pointing at it.
//
// NOTE FOR ANYONE READING THIS IN THE PUBLIC REPOSITORY: the presence of
// a key here says a capability is *defined*, not that it is built,
// scheduled, or coming. Most are placeholders reserving a name.

abstract class FeatureKeys {
  // ── GROUP 1 ─────────────────────────────────────────────────────────────
  // Generally available. Still declared and still gateable so that any
  // one of them can be disabled platform-wide if it starts misbehaving —
  // the kill switch is the reason a live capability keeps a flag.
  static const bots = 'bots.core';
  static const channelWhatsapp = 'channels.whatsapp';
  static const channelTelegram = 'channels.telegram';
  static const conversations = 'conversations.inbox';
  static const escalation = 'conversations.escalation';
  static const memoryDocuments = 'memory.documents';
  static const memoryRetrieval = 'memory.retrieval';
  static const memoryInspector = 'memory.inspector';
  static const errandsBuiltin = 'errands.builtin';
  static const billing = 'billing.core';
  static const ownerNotifications = 'notifications.owner';

  // ── COMMERCE — available, off by default per workspace ──────────────────
  // A business without a catalog must not see a sales counter.
  //
  // NOTE THE TWO-LAYER MODEL, because it is easy to confuse:
  //   • These flags control whether commerce is AVAILABLE on the platform.
  //   • Whether a given business has TURNED IT ON is a workspace setting,
  //     not a flag. A released feature the business hasn't enabled is not
  //     the same as a locked one, and the dashboard must render them
  //     differently — "you could turn this on" vs. not existing at all.
  //
  static const commerceCore = 'commerce.core';
  static const commerceCatalog = 'commerce.catalog';
  static const commercePos = 'commerce.pos';
  static const commerceOffline = 'commerce.offline';
  static const commerceStock = 'commerce.stock';
  static const commerceReceipts = 'commerce.receipts';
  static const commerceCatalogImport = 'commerce.catalog_import';
  static const commerceBarcodeLookup = 'commerce.barcode_lookup';

  // ── GROUP 2 ─────────────────────────────────────────────────────────────
  static const timeline = 'timeline.core';
  static const customers = 'customers.core';
  static const operations = 'operations.core';
  static const supportTickets = 'operations.support_tickets';
  static const payments = 'payments.collect';
  static const eventBus = 'platform.event_bus';
  static const commerceInvoices = 'commerce.invoices';
  static const commerceReports = 'commerce.reports';
  static const commerceCustomerDisplay = 'commerce.customer_display';
  static const commercePublicCatalog = 'commerce.public_catalog';
  static const commercePhotoCapture = 'commerce.photo_capture';
  static const commerceVoiceCapture = 'commerce.voice_capture';

  // ── GROUP 3 ─────────────────────────────────────────────────────────────
  static const observations = 'intelligence.observations';
  static const recommendations = 'intelligence.recommendations';
  static const businessIntelligence = 'intelligence.dashboards';
  static const analytics = 'intelligence.analytics';
  static const forecasting = 'intelligence.forecasting';

  // ── GROUP 4 ─────────────────────────────────────────────────────────────
  static const agents = 'agents.core';
  static const agentSales = 'agents.sales';
  static const agentSupport = 'agents.support';
  static const agentFinance = 'agents.finance';
  static const agentInventory = 'agents.inventory';
  // Added alongside AgentArchetypes.marketing (Phase A of the agent
  // architecture correction) — the four keys above it already reserved
  // this exact naming pattern before that registry existed. Declared
  // here, referenced there for documentation — see that file's header
  // on why it is not yet wired into live enforcement.
  static const agentMarketing = 'agents.marketing';
  static const automations = 'automations.workflows';
  static const automationApprovals = 'automations.approvals';
  static const tasks = 'tasks.core';

  // ── GROUP 5 ─────────────────────────────────────────────────────────────
  static const channelMessenger = 'channels.messenger';
  static const channelInstagram = 'channels.instagram';
  static const channelEmail = 'channels.email';
  static const broadcast = 'messaging.broadcast';
  // Gate 8 — POST /v1/messages, the public single-send outbound API.
  // Deliberately its own key, separate from [broadcast]: a business can
  // be allowed to send one message on demand long before bulk/broadcast
  // sending is something Kola trusts them (or itself) with.
  static const messagingSend = 'messaging.send';
  static const connectorsCommerce = 'connectors.commerce';
  static const connectorsStorage = 'connectors.storage';
  static const connectorsAccounting = 'connectors.accounting';
  static const connectorsCalendar = 'connectors.calendar';
  static const connectorsCrm = 'connectors.crm';

  // ── GROUP 6 ─────────────────────────────────────────────────────────────
  static const publicApi = 'platform.public_api';
  static const webhooksOutbound = 'platform.webhooks_outbound';
  static const developerPortal = 'platform.developer_portal';
  static const errandsWebhook = 'errands.webhook';
  static const errandsDbCredential = 'errands.db_credential';

  // ── GROUP 7 ─────────────────────────────────────────────────────────────
  // Several of these depend on external artefacts (certification, legal
  // agreements) rather than on code, and carry externallyGated = true.
  static const sso = 'enterprise.sso';
  static const auditLog = 'enterprise.audit_log';
  static const dataResidency = 'enterprise.data_residency';
  static const advancedRoles = 'enterprise.advanced_roles';
  static const agencyMultiWorkspace = 'enterprise.agency_workspaces';

  /// EVERY key above. The admin dashboard reconciles this against the
  /// `feature_flags` table on load and reports both directions of drift:
  /// a key here with no row (never seeded — the feature is invisible and
  /// nobody knows), and a row with no key here (orphaned by a rename or
  /// a deleted feature — its overrides are dead weight).
  ///
  /// Keep this list in sync when adding a constant above. It is
  /// deliberately hand-maintained rather than reflected over: Dart has no
  /// runtime reflection over static fields in a way that survives
  /// dart2js tree-shaking, and a silently-incomplete list here would
  /// reintroduce exactly the invisible-feature bug this file exists to
  /// prevent.
  static const List<String> allKeys = [
    // Group 1
    bots, channelWhatsapp, channelTelegram, conversations, escalation,
    memoryDocuments, memoryRetrieval, memoryInspector, errandsBuiltin,
    billing, ownerNotifications,
    commerceCore, commerceCatalog, commercePos, commerceOffline,
    commerceStock, commerceReceipts, commerceCatalogImport,
    commerceBarcodeLookup,
    // Group 2
    timeline, customers, operations, supportTickets, payments, eventBus,
    commerceInvoices, commerceReports, commerceCustomerDisplay,
    commercePublicCatalog, commercePhotoCapture, commerceVoiceCapture,
    // Group 3
    observations, recommendations, businessIntelligence, analytics,
    forecasting,
    // Group 4
    agents, agentSales, agentSupport, agentFinance, agentInventory,
    agentMarketing,
    automations, automationApprovals, tasks,
    // Group 5
    channelMessenger, channelInstagram, channelEmail, broadcast, messagingSend,
    connectorsCommerce, connectorsStorage, connectorsAccounting,
    connectorsCalendar, connectorsCrm,
    // Group 6
    publicApi, webhooksOutbound, developerPortal, errandsWebhook,
    errandsDbCredential,
    // Group 7
    sso, auditLog, dataResidency, advancedRoles, agencyMultiWorkspace,
  ];
}

/// The rollout state of one feature, platform-wide.
///
/// Deliberately an ordered progression rather than a boolean: the whole
/// point of this system is that "built" and "released" are different
/// events, with observable steps in between.
enum FeatureState {
  /// Built, deployed, and invisible to everyone including internal
  /// workspaces. The default for anything new. Also the kill-switch
  /// destination — flipping a released feature back to `locked` disables
  /// it platform-wide with no deployment.
  locked,

  /// Visible only to workspaces flagged internal. For dogfooding a
  /// feature against real data before any customer sees it.
  internal,

  /// Visible only to workspaces with an explicit `enabled` override.
  /// This is the design-partner stage — deliberately opt-in per
  /// workspace rather than a percentage rollout, because with a customer
  /// base this size a percentage is meaningless and knowing exactly who
  /// has what matters more.
  beta,

  /// Visible to everyone, subject to the feature's minimum plan.
  released,
}

/// Parses the string stored in the database. Unknown values resolve to
/// [FeatureState.locked] rather than throwing — a corrupt or
/// forward-dated state must fail closed (feature hidden), never open.
FeatureState featureStateFromString(String value) {
  return switch (value) {
    'internal' => FeatureState.internal,
    'beta' => FeatureState.beta,
    'released' => FeatureState.released,
    _ => FeatureState.locked,
  };
}

String featureStateToString(FeatureState state) => state.name;
