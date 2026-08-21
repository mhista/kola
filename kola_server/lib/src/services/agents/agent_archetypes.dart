// agent_archetypes.dart
//
// THE AGENT ROLE REGISTRY — Phase A of the architecture correction the
// owner asked for after Gate 2: connecting WhatsApp or Telegram does not
// make something an agent. A channel is a communication surface an agent
// can use; a connector (Paystack, etc.) is a capability it can settle
// through; an Errand is a task it can run. What actually defines an
// agent is its ROLE — a payment agent, a ticketing agent, a marketing
// agent — and this file is the single source of truth for which roles
// exist.
//
// ── WHY `Bot.archetype` AND NOT A NEW TABLE ──────────────────────────
//
// The owner's "Everything" scope covers the data model, but the actual
// gap turned out narrower than a full schema rebuild once the existing
// relationships were checked: Channel is already 1 Bot : N Channels (a
// single agent can already hold WhatsApp AND Telegram at once — see
// channel.spy.yaml), and both WorkspaceConnector and Errand are already
// workspace-scoped rather than bot-scoped (see their own headers) — a
// workspace's Paystack connection and its Errands are already shareable
// across every agent in it, by design, already in the schema. The one
// thing that was never built out is WHAT KIND of agent a Bot row is:
// `archetype` had exactly three values (customerCare, catalog, custom),
// none of which name a role like payment collection or ticket routing.
// This file grows that field into a real registry. `Bot`/`bots` stays
// the internal identifier — see agent_lifecycle_events.dart's header on
// why — this is the specialization living inside it, not a new object.
//
// ── SOURCE OF TRUTH, MIRRORED IN TWO OTHER PLACES ────────────────────
//
// This is the ONE place the role list is declared. Two call sites
// currently duplicate a bare set of valid keys rather than importing
// this file's `allKeys` — check both are still reading from here, not
// re-declaring their own list, if this file ever moves:
//   - bot_endpoint.dart (createBot / createBotFromDescription / updateBot
//     validation)
//   - bot_mother_service.dart (its `_systemPrompt`'s "Archetype guide"
//     text is a natural-language description of the same list — the AI
//     needs the prose form, not just the keys, so it stays hand-written
//     there but MUST list the same roles this file declares)
// The database also enforces this list independently via a CHECK
// constraint (docs/migrations/038_agent_archetypes.sql) — see that
// migration's header for why a fourth, SQL-level copy is unavoidable
// (Serverpod Mini has no ORM-level enum sync to Postgres) and why it
// must be updated in lockstep with this file.
//
// ── `requiredFeature` IS DOCUMENTATION ONLY, NOT YET ENFORCED ────────
//
// Every new role below maps to the closest existing (or newly declared)
// FeatureKeys.agent* / FeatureKeys.payments entry — the platform's
// release-control system already reserved most of these names (see
// feature_keys.dart's Group 4) before this file existed, which is a
// strong signal this mapping is the intended one, not a guess.
//
// Deliberately NOT wired into bot_endpoint.dart's validation yet.
// FeatureFlagService.isEnabled fails LOUD (severe log + hard false) on
// any key with no seeded `feature_flags` row (see that file's header,
// step 0) — wiring live enforcement here without first seeding rows for
// agentMarketing (brand new) and confirming agentSales/agentSupport/
// agentFinance/agentInventory/payments are already seeded would risk
// silently locking every new archetype out for every workspace, which
// is a worse failure than no gating at all. Gating archetype creation
// on release state is real, wanted follow-up work — just not bundled
// into this pass blind.
class AgentArchetypeInfo {
  const AgentArchetypeInfo({
    required this.key,
    required this.label,
    required this.description,
    this.requiredFeature,
  });

  /// Stored verbatim in `bots.archetype`. Never renamed once shipped —
  /// same permanence rule as FeatureKeys' own keys, for the same reason:
  /// existing rows already hold this exact string.
  final String key;

  /// Owner-facing name, e.g. "Payment agent".
  final String label;

  /// One sentence: what this agent's job is, independent of which
  /// channel or connector it happens to be given. Shown on the create-
  /// agent flow and the agent detail page once Phase C rebuilds them.
  final String description;

  /// The FeatureKeys constant that will eventually gate creating an
  /// agent with this archetype, once enforcement is wired — see this
  /// file's header. Null for the three archetypes that predate the
  /// role registry and have always been ungated.
  final String? requiredFeature;

  @override
  String toString() => key;
}

abstract class AgentArchetypes {
  // ── Pre-existing, ungated — unchanged from before this file existed ──
  static const customerCare = AgentArchetypeInfo(
    key: 'customerCare',
    label: 'Customer care agent',
    description: 'General Q&A, support, and escalation to a human when stuck.',
  );

  static const catalog = AgentArchetypeInfo(
    key: 'catalog',
    label: 'Catalog agent',
    description: 'Browsing and negotiation over a product catalog — prices, stock, variants.',
  );

  static const custom = AgentArchetypeInfo(
    key: 'custom',
    label: 'Custom agent',
    description: 'Anything that clearly does not fit one of the other roles.',
  );

  // ── New roles — the actual gap this file closes ──────────────────────
  //
  // `requiredFeature` values below name the FeatureKeys constant, not
  // its string literal, so a rename there is caught here at compile
  // time rather than silently drifting.

  static const payment = AgentArchetypeInfo(
    key: 'payment',
    label: 'Payment agent',
    description:
        'Collects and confirms payments on whatever channels it is given, '
        'and settles through connected providers like Paystack.',
    requiredFeature: 'payments.collect', // FeatureKeys.payments
  );

  static const support = AgentArchetypeInfo(
    key: 'support',
    label: 'Support agent',
    description:
        'Resolves tickets and routes issues to the right person or department.',
    requiredFeature: 'agents.support', // FeatureKeys.agentSupport
  );

  static const finance = AgentArchetypeInfo(
    key: 'finance',
    label: 'Finance agent',
    description: 'Chases overdue invoices, confirms payments, answers finance questions.',
    requiredFeature: 'agents.finance', // FeatureKeys.agentFinance
  );

  static const inventory = AgentArchetypeInfo(
    key: 'inventory',
    label: 'Inventory agent',
    description: 'Watches stock levels and flags what needs restocking.',
    requiredFeature: 'agents.inventory', // FeatureKeys.agentInventory
  );

  static const marketing = AgentArchetypeInfo(
    key: 'marketing',
    label: 'Marketing agent',
    description: 'Sends promotions, announcements, and follow-ups.',
    requiredFeature: 'agents.marketing', // FeatureKeys.agentMarketing
  );

  static const sales = AgentArchetypeInfo(
    key: 'sales',
    label: 'Sales agent',
    description: 'Answers product questions and takes orders.',
    requiredFeature: 'agents.sales', // FeatureKeys.agentSales
  );

  /// Every archetype, in the order shown on the create-agent flow —
  /// ungated roles first (always available), then the specialized roles
  /// in the same order feature_keys.dart's Group 4 declares them.
  static const all = <AgentArchetypeInfo>[
    customerCare,
    catalog,
    payment,
    support,
    finance,
    inventory,
    marketing,
    sales,
    custom,
  ];

  /// What `bot_endpoint.dart` and `bot_mother_service.dart` validate
  /// against — see this file's header on keeping both in sync with this
  /// set rather than re-declaring it.
  static final Set<String> allKeys = {for (final a in all) a.key};

  static AgentArchetypeInfo? byKey(String key) {
    for (final a in all) {
      if (a.key == key) return a;
    }
    return null;
  }
}
