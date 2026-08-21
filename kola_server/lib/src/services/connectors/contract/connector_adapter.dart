// connector_adapter.dart — Gate 1. The shape every connector's actual
// data-moving logic implements, as distinct from connector_catalog.dart
// (what a connector IS, product-definition-wise) and connector_service
// .dart (the credential/status marketplace merge). Neither of those
// files has ever had a method that moves data — this is that method.
//
// PRE-GATE-1, THIS DID NOT EXIST. Read PART III of
// docs/Kolaa_Connections_Backbone_Direction_v5.pdf before adding a sixth
// adapter beside a fifth that still writes its own retry logic — "if
// adapter number six is still writing its own retry logic, the contract
// is wrong" is the document's own test for this file.
//
// NOT EVERY EXISTING CONNECTOR IMPLEMENTS THIS YET. WhatsApp and
// Telegram (the two SHIPPED connectors — see connector_catalog.dart)
// are message-delivery channels, not pull-and-paginate sources: nothing
// calls [sync] on them today, because Meta/Telegram push events to a
// webhook rather than kola pulling a page at a time. What they DO adopt
// from this gate — see whatsapp_bot_registry.dart and
// telegram_bot_registry.dart — is the shared retry/backoff
// (connector_retry.dart), provenance stamping on every ingested message
// (migration 036), and sync-observability logging
// (connector_sync_log_repository.dart), which are the parts of the
// contract that genuinely apply to a push-driven channel. [sync] itself
// is here for Gate 4's pull-based adapters (Paystack, Google Sheets) to
// implement against, proven out by this gate's shared plumbing rather
// than invented fresh when the first of them is built.

import 'sync_types.dart';

abstract class ConnectorAdapter {
  /// Matches ConnectorDefinition.key in connector_catalog.dart. Never
  /// invented independently — an adapter without a matching catalog
  /// entry is a connector the marketplace can't render.
  String get connectorKey;

  ConnectorCapabilities get capabilities;

  /// Pulls (or reconciles, for a push-driven source — see
  /// [ConnectorCapabilities.isPushDriven]) whatever is new since
  /// [cursor], and returns what happened. MUST be idempotent: calling
  /// this twice with the same cursor, or replaying the same underlying
  /// payload, must never produce two records where one existed before —
  /// PART VIII's own testing requirement ("ingest the same payload
  /// twice and assert one entity, not two").
  ///
  /// Throws on a run-level failure (the source was unreachable, auth
  /// was rejected outright) rather than returning a [SyncResult] with
  /// errors — that distinction is what lets the shared retry/backoff
  /// layer in connector_retry.dart tell "retry this" apart from "this
  /// ran and some rows had problems."
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none});

  /// Actually attempts something, rather than just checking a stored
  /// status flag — "an expired OAuth token looks exactly like
  /// 'connected' until something is attempted" (PART III). Called by
  /// the nightly sweep (see channel_health_check_service.dart for the
  /// channel-store implementation of this idea, which predates and now
  /// feeds this contract) and safe to call on demand.
  Future<ConnectorHealth> health();

  /// What this adapter's retention policy says should happen to data it
  /// already ingested when the workspace disconnects it. Not "do the
  /// deletion" — that stays the caller's job, scoped to one workspace at
  /// a time with its own audit trail — just "what should happen",
  /// so the answer is decided once, in the adapter that understands its
  /// own data, rather than guessed at by whatever endpoint happens to
  /// handle a disconnect click.
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;
}
