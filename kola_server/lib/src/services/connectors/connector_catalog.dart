// connector_catalog.dart — Layer 3. Which connectors exist, what they
// are called, and what each one needs to connect.
//
// ── THIS IS PRODUCT DEFINITION, NOT DATA ─────────────────────────────
//
// The catalog lives in code, not in a table. Adding a connector is a
// deploy, not an INSERT, and a workspace can never hold a row for a
// connector the server does not understand. workspace_connectors stores
// only per-workspace STATE (connected / error, credentials, last sync).
//
// It is also served to the dashboard rather than duplicated there. The
// previous integrations page hardcoded its own list, which meant the
// server and the UI could disagree about what exists — and the UI
// always won, because it was the one drawing the screen.
//
// ── STATUS IS COMPUTED, NOT STORED HERE ──────────────────────────────
//
// A catalog entry names its [featureKey]. Whether that capability is
// released to a given workspace is answered by FeatureFlagService;
// whether the workspace has actually connected it is answered by one of
// three storage locations. ConnectorService merges all three. The
// design's four visible states come out of that merge:
//
//   soon        featureKey not enabled for this workspace
//   available   enabled, nothing stored for this workspace
//   connected   enabled, stored, healthy
//   error       enabled, stored, last attempt failed
//
// `error` is the one worth naming. An expired OAuth token looks exactly
// like "connected" until something is actually attempted, so a
// connector that silently stopped syncing a price list must be able to
// say so.
//
// ── WHY THE FLAG DRIVES THIS AND NOT A FIELD IN THIS FILE ────────────
//
// An earlier version carried `ConnectorRelease { shipped, comingSoon }`
// here. That made this file a SECOND source of truth about release
// state, competing with feature_flags — and the two could disagree
// silently. Flipping `connectors.storage` to released in kola_admin
// would have changed nothing until somebody also edited Dart and
// deployed, which is precisely the property the locked-release model
// exists to avoid (RELEASE_PHASES.md §0: "Unlocking is a database
// change, not a deployment").
//
// So: the flag decides visibility, this file describes the connector.
//
// It also corrects a scoping mistake worth recording. The design export
// marks 8 of these 15 `soon`, and that was read as a decision not to
// build them. It is not — by the same reading, Google Sheets is marked
// `error`, and nobody intends to ship Sheets permanently broken. Those
// are per-tile rendering samples. `soon` is how a BUILT BUT LOCKED
// connector looks. Everything here is meant to be built; the flag
// decides who sees it.

import 'package:kola_server/src/services/features/feature_keys.dart';

/// Where a connector's credentials actually live.
///
/// Three real storage backends, not one, because two of them predate
/// this layer and have genuine domain behaviour attached — see
/// migration 025's header.
enum ConnectorStore {
  /// `channels` — WhatsApp and Telegram. Message routing, webhooks.
  channel,

  /// `payment_gateway_credentials` — charge-time behaviour.
  paymentGateway,

  /// `workspace_connectors` — everything else.
  generic,
}

/// How an owner connects it.
enum ConnectorAuth {
  /// Paste credentials into a form.
  fields,

  /// Redirect to the provider and come back with a token.
  oauth,

  /// Already configured elsewhere in the product; this screen links to
  /// where it is managed rather than duplicating the form.
  manage,

  /// We display a key for the owner to paste into the OTHER product.
  /// The reverse direction of `fields`.
  keyDisplay,

  /// WhatsApp's own connect flow. A DISTINCT type in the design, not a
  /// synonym for [fields] — the export branches on
  /// `authType === 'whatsapp'` in two places, because Meta's setup needs
  /// its own explanation and its own field ordering rather than a
  /// generic form with five boxes.
  ///
  /// An earlier version of this catalog mapped WhatsApp to [fields] and
  /// lost that branch. Caught by parsing the export with a brace-depth
  /// parser — a field-order regex over the same file reports four auth
  /// types and never mentions this one.
  whatsapp,
}

// NOTE: `ConnectorRelease` used to live here. Removed deliberately —
// see this file's header. Release state is feature_flags' job.

class ConnectorField {
  const ConnectorField({
    required this.key,
    required this.label,
    this.placeholder = '',
    this.secret = false,
  });

  final String key;
  final String label;
  final String placeholder;

  /// Whether the value must be masked on input and NEVER returned by
  /// any read endpoint. Access tokens and secret keys are secret; a
  /// store URL or an app id is not, and masking those makes the form
  /// harder to check without making anything safer.
  final bool secret;
}

class ConnectorDefinition {
  const ConnectorDefinition({
    required this.key,
    required this.name,
    required this.category,
    required this.description,
    required this.auth,
    required this.store,
    required this.featureKey,
    this.helpText = '',
    this.fields = const [],
    this.manageRoute,
  });

  /// Stable identifier. Stored in workspace_connectors.connector_key,
  /// so it must never change once shipped — renaming it orphans every
  /// existing connection silently.
  final String key;

  final String name;
  final String category;
  final String description;
  final ConnectorAuth auth;
  final ConnectorStore store;

  /// The capability flag that decides whether this connector is visible
  /// as connectable or as `soon`. A constant from [FeatureKeys].
  ///
  /// Several connectors deliberately share one key: Drive, Sheets and
  /// Dropbox are all `connectors.storage`, because "can this business
  /// connect a file store" is one product decision, not three. Unlocking
  /// storage unlocks the family.
  final String featureKey;

  /// Where to find the credentials, in the provider's own terms.
  final String helpText;

  final List<ConnectorField> fields;

  /// For [ConnectorAuth.manage] — where the real settings live.
  final String? manageRoute;
}

class ConnectorCategory {
  const ConnectorCategory({
    required this.id,
    required this.label,
    required this.subtitle,
  });

  final String id;
  final String label;

  /// The plain-language gloss under the category name. Carried from the
  /// design because "Know" alone means nothing — "storage, catalogs,
  /// CRM" is what makes the grouping legible.
  final String subtitle;
}

abstract class ConnectorCatalog {
  static const categories = <ConnectorCategory>[
    // 'channels, storefronts' -> 'storefronts' — Phase C of the agent
    // architecture correction: WhatsApp/Telegram no longer group under
    // this category in IntegrationsPage (see ConnectorStatus.isChannel
    // and that page's own header). This subtitle is server-side catalog
    // data, not currently rendered by the dashboard, but kept accurate
    // rather than left describing a grouping that no longer exists.
    ConnectorCategory(id: 'sell', label: 'Sell', subtitle: 'storefronts'),
    ConnectorCategory(id: 'pay', label: 'Get paid', subtitle: 'gateways, accounting'),
    ConnectorCategory(id: 'know', label: 'Know', subtitle: 'storage, catalogs, CRM'),
    ConnectorCategory(
        id: 'operate', label: 'Operate', subtitle: 'calendar, staff comms'),
  ];

  static const all = <ConnectorDefinition>[
    // ── Sell ──────────────────────────────────────────────────────────
    ConnectorDefinition(
      key: 'whatsapp',
      name: 'WhatsApp',
      category: 'sell',
      description: 'Automate customer conversations on your business number.',
      auth: ConnectorAuth.whatsapp,
      store: ConnectorStore.channel,
      featureKey: FeatureKeys.channelWhatsapp,
      helpText: 'From your Meta App dashboard, under WhatsApp → API Setup.',
      // FIELD 5 IS THE VERIFY TOKEN, NOT THE APP SECRET.
      //
      // An earlier version of this file listed 'App secret' here. The
      // export says 'Webhook verify token', placeholder "Any string you
      // choose" — a value the OWNER invents and then pastes into Meta's
      // Callback URL form, not a credential Meta issues.
      //
      // The design is also more correct than the server here. Today the
      // verify token is a single server-wide env var
      // (WHATSAPP_WEBHOOK_VERIFY_TOKEN), which cannot be right for a
      // multi-tenant product: every workspace would have to be told the
      // same secret string to paste into their own Meta dashboard.
      // Per-workspace is what the design specifies and what the product
      // needs. Server work item, not a reason to change the form.
      fields: [
        ConnectorField(
            key: 'appId', label: 'Meta App ID', placeholder: '1029384756102938'),
        ConnectorField(
            key: 'wabaId',
            label: 'WhatsApp Business Account ID (WABA ID)',
            placeholder: '2847193857201938'),
        ConnectorField(
            key: 'phoneNumberId',
            label: 'Phone Number ID',
            placeholder: '1928374650192837'),
        ConnectorField(
            key: 'accessToken',
            label: 'Permanent access token',
            placeholder: 'EAAG...',
            secret: true),
        ConnectorField(
            key: 'verifyToken',
            label: 'Webhook verify token',
            placeholder: 'Any string you choose'),
      ],
    ),
    ConnectorDefinition(
      key: 'telegram',
      name: 'Telegram',
      category: 'sell',
      description: 'No phone number required, live in minutes.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.channel,
      featureKey: FeatureKeys.channelTelegram,
      helpText: 'Create a bot with @BotFather, then paste its token.',
      fields: [
        ConnectorField(
          key: 'botToken',
          label: 'Bot token',
          placeholder: '123456789:AAExample-Token',
          secret: true,
        ),
      ],
    ),
    ConnectorDefinition(
      key: 'instagram_shop',
      name: 'Instagram Shop',
      category: 'sell',
      description: 'Sync your product tags for shoppable DMs.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
    ),
    ConnectorDefinition(
      key: 'facebook_catalog',
      name: 'Facebook Catalog',
      category: 'sell',
      description: 'Sync your product catalog for richer WhatsApp replies.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
    ),
    ConnectorDefinition(
      key: 'shopify',
      name: 'Shopify',
      category: 'sell',
      description: 'Pull products and orders from your Shopify storefront.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
      helpText: 'Shopify admin → Apps → Develop apps → API credentials.',
      fields: [
        ConnectorField(
            key: 'storeUrl',
            label: 'Store URL',
            placeholder: 'your-shop.myshopify.com'),
        ConnectorField(
            key: 'adminToken', label: 'Admin API access token', secret: true),
      ],
    ),

    // ── Get paid ──────────────────────────────────────────────────────
    ConnectorDefinition(
      key: 'paystack',
      name: 'Paystack',
      category: 'pay',
      description: 'Payments and order confirmation directly inside chats.',
      auth: ConnectorAuth.manage,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      manageRoute: '/billing',
    ),
    ConnectorDefinition(
      key: 'flutterwave',
      name: 'Flutterwave',
      category: 'pay',
      description: 'Payments and order confirmation directly inside chats.',
      auth: ConnectorAuth.manage,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      manageRoute: '/billing',
    ),
    ConnectorDefinition(
      key: 'stripe',
      name: 'Stripe',
      category: 'pay',
      description: 'For businesses billing customers outside Africa.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      helpText: 'Stripe dashboard → Developers → API keys.',
      fields: [
        ConnectorField(key: 'secretKey', label: 'Secret key', secret: true),
      ],
    ),

    // ── Know ──────────────────────────────────────────────────────────
    ConnectorDefinition(
      key: 'google_sheets',
      name: 'Google Sheets',
      category: 'know',
      description: 'Keep price lists and inventory synced from a live sheet.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
    ),
    ConnectorDefinition(
      key: 'google_drive',
      name: 'Google Drive',
      category: 'know',
      description: 'Pull policy and catalog documents straight from Drive.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
    ),
    ConnectorDefinition(
      key: 'dropbox',
      name: 'Dropbox',
      category: 'know',
      description: 'Same as Drive, for businesses standardised on Dropbox.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
    ),
    ConnectorDefinition(
      key: 'hubspot',
      name: 'HubSpot CRM',
      category: 'know',
      description: 'Bring existing customer records into kola.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCrm,
    ),

    // ── Operate ───────────────────────────────────────────────────────
    ConnectorDefinition(
      key: 'google_calendar',
      name: 'Google Calendar',
      category: 'operate',
      description: 'Book appointments and deliveries onto your calendar.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCalendar,
    ),
    ConnectorDefinition(
      key: 'slack',
      name: 'Slack',
      category: 'operate',
      description: 'Route escalations to a staff channel instead of a phone.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.ownerNotifications,
    ),
    ConnectorDefinition(
      key: 'zapier',
      name: 'Zapier',
      category: 'operate',
      description: 'Connect kola to thousands of other tools without code.',
      auth: ConnectorAuth.keyDisplay,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.publicApi,
    ),
  ];

  /// Looks a connector up. Returns null rather than throwing — an
  /// unknown key usually means a stored row outlived its definition,
  /// and the endpoint should report that rather than fail the whole
  /// list.
  static ConnectorDefinition? byKey(String key) {
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }

  static List<ConnectorDefinition> inCategory(String categoryId) =>
      [for (final c in all) if (c.category == categoryId) c];
}
