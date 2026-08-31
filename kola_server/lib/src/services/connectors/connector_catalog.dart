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
      // FIELD 5 IS BACK TO APP SECRET, REVERSING THE EARLIER "the design
      // is more correct than the server" call.
      //
      // The design export's field 5 is a webhook verify token — a phrase
      // the OWNER invents and pastes into Meta's Callback URL form — and
      // that IS the more correct design for a multi-tenant product (see
      // the previous version of this comment, kept in git history). But
      // integrations_page.dart's connect form was never actually wired
      // to submit anywhere until now (it called connectConnector, which
      // explicitly rejects store != generic — every WhatsApp/Telegram
      // connect attempt from the dashboard failed, every time). Wiring
      // it for real means matching what ChannelEndpoint
      // .connectWhatsAppChannelManual ACTUALLY requires today —
      // whatsappAppSecret, not a verify token the server has nowhere to
      // store per-workspace (WHATSAPP_WEBHOOK_VERIFY_TOKEN is still one
      // global env var). Building the per-workspace verify-token column
      // is real, separate server work (a migration + a field on Channel
      // + reading it in the webhook handshake instead of the env var) —
      // out of scope for "make the existing form actually submit."
      // Revisit this field again once that lands.
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
            key: 'appSecret',
            label: 'App secret',
            placeholder: 'From App Settings → Basic',
            secret: true),
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
    // Instagram DM — a communication channel (store: channel), distinct
    // from 'instagram_shop' below (a catalog-sync connector, store:
    // generic, OAuth-based). Backed by ChannelEndpoint
    // .connectInstagramChannelManual (see GATE_INSTAGRAM_STATUS.md — the
    // server side has been real since 2026-08-30; this catalog entry
    // and integrations_page.dart's dispatch to it are what were missing
    // to make it reachable from the dashboard at all).
    //
    // featureKey is FeatureKeys.channelInstagram, which sits in an
    // unreleased wave (R5, not R1 — see feature_keys.dart) — so this
    // tile renders as 'soon' until an Owner flips it to available/beta
    // in kola_admin's release control page. That is deliberate: shipping
    // this catalog entry doesn't itself release the feature, the same
    // "decouple build from release" principle every other gateable
    // capability in this codebase follows.
    ConnectorDefinition(
      key: 'instagram',
      name: 'Instagram',
      category: 'sell',
      description: 'Automate DMs on your Instagram professional account.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.channel,
      featureKey: FeatureKeys.channelInstagram,
      helpText: 'Needs an Instagram professional account, an access token with '
          'instagram_business_basic + instagram_business_manage_messages, and '
          'your Meta App\'s App Secret.',
      fields: [
        ConnectorField(
            key: 'igUserId',
            label: 'Instagram professional account ID',
            placeholder: '17841400000000000'),
        ConnectorField(
            key: 'accessToken',
            label: 'Access token',
            placeholder: 'IGAAG...',
            secret: true),
        ConnectorField(
            key: 'appSecret',
            label: 'App secret',
            placeholder: 'From App Settings → Basic',
            secret: true),
      ],
    ),
    // Messenger — the fourth channel connector, built 31 Aug 2026 as the
    // direct sibling of Instagram above (same store: channel, same
    // manual-fields auth, same ChannelEndpoint probe-before-persist
    // shape via .connectMessengerChannelManual). featureKey is
    // FeatureKeys.channelMessenger, which sits in the same unreleased
    // Group 5 wave as channelInstagram — same "soon" until an Owner
    // flips it, same "decouple build from release" reasoning.
    ConnectorDefinition(
      key: 'messenger',
      name: 'Messenger',
      category: 'sell',
      description: 'Automate DMs on your Facebook Page.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.channel,
      featureKey: FeatureKeys.channelMessenger,
      helpText: 'Needs a Facebook Page, a Page access token with '
          'pages_messaging, the Page ID, and your Meta App\'s App Secret.',
      fields: [
        ConnectorField(
            key: 'pageId',
            label: 'Facebook Page ID',
            placeholder: '61550000000000'),
        ConnectorField(
            key: 'accessToken',
            label: 'Page access token',
            placeholder: 'EAAG...',
            secret: true),
        ConnectorField(
            key: 'appSecret',
            label: 'App secret',
            placeholder: 'From App Settings → Basic',
            secret: true),
      ],
    ),
    // Fix-properly pass — real OAuth flow now exists (MetaOAuthService,
    // shared with facebook_catalog below — one Meta App, two scopes).
    // helpText filled in now that clicking Connect leads somewhere real
    // instead of the "not wired up yet" tile.
    ConnectorDefinition(
      key: 'instagram_shop',
      name: 'Instagram Shop',
      category: 'sell',
      description: 'Sync your product tags for shoppable DMs.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
      helpText: 'Needs an Instagram professional account linked to a Facebook '
          'Page with a product catalog already set up in Commerce Manager.',
    ),
    ConnectorDefinition(
      key: 'facebook_catalog',
      name: 'Facebook Catalog',
      category: 'sell',
      description: 'Sync your product catalog for richer WhatsApp replies.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
      helpText: 'Needs a product catalog already set up in Meta Commerce '
          'Manager, owned by a Business Manager account.',
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
    // Gate 4 — same fields-into-generic-store shape Shopify already
    // uses, extended to TWO secret fields rather than one. Confirmed
    // against a real, live Bumpa account (not guessed from docs alone —
    // see bumpa_service.dart's header): the secret key authenticates
    // orders, and the PUBLIC key — a genuinely separate value, not the
    // same key relabeled — is required for the product catalog. Passing
    // the secret key where the public one belongs fails with a clear
    // "Invalid or inactive public API key" error rather than silently
    // working, so both are collected up front instead of only asking for
    // the public one when a product sync first fails.
    ConnectorDefinition(
      key: 'bumpa',
      name: 'Bumpa',
      category: 'sell',
      description: 'Pull orders and products from your Bumpa storefront.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCommerce,
      helpText: 'Bumpa dashboard → Settings → API Keys. Both keys are needed — '
          'the secret key reads orders, the public key reads your product catalog.',
      fields: [
        ConnectorField(
            key: 'secretKey',
            label: 'Secret key',
            placeholder: 'sk_live_...',
            secret: true),
        ConnectorField(
            key: 'publicKey',
            label: 'Public key',
            placeholder: 'pk_live_...',
            secret: true),
      ],
    ),

    // ── Get paid ──────────────────────────────────────────────────────
    // Gate 4 — was ConnectorAuth.manage pointing at /billing, which is
    // kolaa's OWN subscription billing settings (which gateway kolaa
    // uses to charge a workspace ITS Kola fee), not this business's own
    // Paystack/Flutterwave account. That page has never rendered a
    // connect form for either — see DESIGN_DELTA.md and
    // payment_endpoint.dart's header on the real distinction (platform
    // account vs. connected account). PaymentEndpoint.connectGateway
    // already exists and already probes-before-persisting; the gap was
    // only ever the missing UI, closed here by giving these the same
    // fields-based shape Stripe already uses, routed through the
    // paymentGateway store's own connect flow rather than
    // ConnectorEndpoint.connectConnector — see connector_status
    // .isPaymentGateway and integrations_page.dart's _submit for why.
    ConnectorDefinition(
      key: 'paystack',
      name: 'Paystack',
      category: 'pay',
      description: 'Payments and order confirmation directly inside chats.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      helpText: 'Paystack dashboard → Settings → API Keys & Webhooks. '
          'Use the SECRET key, not the public key.',
      fields: [
        ConnectorField(key: 'secretKey', label: 'Secret key', secret: true),
      ],
    ),
    ConnectorDefinition(
      key: 'flutterwave',
      name: 'Flutterwave',
      category: 'pay',
      description: 'Payments and order confirmation directly inside chats.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      helpText: 'Flutterwave dashboard → Settings → API. The webhook secret '
          'hash is set separately, under Settings → Webhooks — both are '
          'needed for kolaa to confirm payments automatically.',
      fields: [
        ConnectorField(key: 'secretKey', label: 'Secret key', secret: true),
        ConnectorField(
          key: 'webhookSecret',
          label: 'Webhook secret hash',
          secret: true,
        ),
      ],
    ),
    // Gate 11 (breadth) — sync/graph-landing only, deliberately: no
    // checkout-initiation path exists for this gateway yet (see
    // payment_checkout_service.dart's explicit refusal for 'monnify' and
    // monnify_service.dart's header). A business already collecting
    // payments through Monnify can connect it so those transactions land
    // on the same customer/sales graph as every other gateway; a
    // business wanting kolaa to GENERATE a Monnify checkout link cannot
    // yet, unlike Paystack/Flutterwave/Stripe.
    ConnectorDefinition(
      key: 'monnify',
      name: 'Monnify',
      category: 'pay',
      description: 'Sync existing Monnify payments into your customer records.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      helpText: 'Monnify dashboard → Developers → API Keys & Contracts. '
          'Both the API key and secret key are required — kolaa uses '
          'them together to sign in, the same way your own integration does.',
      fields: [
        ConnectorField(key: 'apiKey', label: 'API key', secret: true),
        ConnectorField(key: 'secretKey', label: 'Secret key', secret: true),
      ],
    ),
    // Gate 11 (breadth) — same sync/graph-landing-only cut as Monnify
    // above (see that entry's comment). Unlike Monnify, Fincra needs
    // only ONE secret — its auth is a single static `api-key` header,
    // no login step — see fincra_service.dart's header.
    ConnectorDefinition(
      key: 'fincra',
      name: 'Fincra',
      category: 'pay',
      description: 'Sync existing Fincra payments into your customer records.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.paymentGateway,
      featureKey: FeatureKeys.payments,
      helpText: 'Fincra dashboard → Developers → API Keys. Use the '
          'Secret key, not the Public key — kolaa reads your existing '
          'payments, it does not render the checkout widget.',
      fields: [
        ConnectorField(key: 'secretKey', label: 'Secret key', secret: true),
      ],
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
    // Gate 4 — OneDrive/SharePoint, not "Excel file upload". A plain
    // .xlsx upload is a Business Memory (knowledge ingestion) concern,
    // not a connector — see docs/connectors/onedrive-excel.md's header
    // on that distinction. This entry is specifically live sync from a
    // workbook stored in a business's own Microsoft 365 account, same
    // shape as google_sheets below but through Microsoft Graph. A
    // PERSONAL Microsoft account (outlook.com/hotmail.com) cannot use
    // this — see helpText and microsoft_oauth_service.dart's header on
    // why.
    ConnectorDefinition(
      key: 'onedrive_excel',
      name: 'Excel (OneDrive/SharePoint)',
      category: 'know',
      description: 'Keep price lists and inventory synced from a live workbook.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
      helpText: 'Needs a Microsoft 365 work or school account — a personal '
          'outlook.com/hotmail.com account cannot be used here.',
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
    // Gate 11 (breadth) — fifth and final connector named in the Rev 6
    // addendum (Instagram intentionally last/unbuilt — see this
    // codebase's status docs on why it's a different shape of
    // connector, not a sync() case). Static internal-integration token,
    // NOT OAuth — see notion_service.dart's header on why that's the
    // correct auth model here, not a shortcut.
    ConnectorDefinition(
      key: 'notion',
      name: 'Notion',
      category: 'know',
      description: 'Pull notes, SOPs, and policy pages straight from Notion.',
      auth: ConnectorAuth.fields,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
      helpText: 'notion.so/profile/integrations → create an internal integration, '
          'copy its token here, THEN open each Notion page you want kolaa to read → '
          '••• menu → Add connections → select your integration. Notion only shows '
          'kolaa pages you explicitly share this way — connecting the token alone '
          'shares nothing.',
      fields: [
        ConnectorField(key: 'integrationToken', label: 'Internal integration token', secret: true),
      ],
    ),
    // Fix-properly pass — real OAuth flow now exists (DropboxOAuthService).
    ConnectorDefinition(
      key: 'dropbox',
      name: 'Dropbox',
      category: 'know',
      description: 'Same as Drive, for businesses standardised on Dropbox.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsStorage,
      helpText: "You'll be asked to sign in to Dropbox and approve kolaa's "
          'access — no keys to copy.',
    ),
    // Fix-properly pass — real OAuth flow now exists (HubSpotOAuthService).
    ConnectorDefinition(
      key: 'hubspot',
      name: 'HubSpot CRM',
      category: 'know',
      description: 'Bring existing customer records into kola.',
      auth: ConnectorAuth.oauth,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.connectorsCrm,
      helpText: "You'll be asked to sign in to HubSpot and install kolaa on "
          'your account — no keys to copy.',
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
    // Fix-properly pass — this was ConnectorAuth.oauth, which is simply
    // wrong: there is no Kola-owned Slack App and no OAuth client for
    // it anywhere in this codebase. Slack notifications are BYO
    // Incoming Webhook (see slack_owner_notifier.dart's header) and are
    // already fully built — configured on the Settings page's owner
    // notifications section, not here. `manage` is the auth type this
    // catalog already has for exactly this shape ("already configured
    // elsewhere in the product; this screen links to where it is
    // managed"). Recategorizing rather than building a second, redundant
    // Slack App OAuth integration next to a working one.
    ConnectorDefinition(
      key: 'slack',
      name: 'Slack',
      category: 'operate',
      description: 'Route escalations to a staff channel instead of a phone.',
      auth: ConnectorAuth.manage,
      store: ConnectorStore.generic,
      featureKey: FeatureKeys.ownerNotifications,
      manageRoute: '/settings',
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
