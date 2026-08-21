// sync_types.dart — Gate 1. The value types the connector contract is
// built from: what a cursor is, what a sync run reports, what a
// connector declares about its own limits, and what a health check
// answers with.
//
// WHY THESE EXIST AS PLAIN VALUE TYPES, NOT SERVERPOD MODELS: none of
// this crosses the wire to the dashboard today — ConnectorStatus
// (connector_status.spy.yaml) already carries the owner-facing summary
// (status/lastError/lastSyncedAt) and stays the wire contract. These
// types are the SERVER-INTERNAL shape every adapter and the shared
// retry/observability plumbing agree on. Promoting them to Serverpod
// models is a later, additive decision if the dashboard ever needs to
// show a full sync-run history rather than just the latest summary —
// not a reason to make them wire types now.
//
// See PART III of docs/Kolaa_Connections_Backbone_Direction_v5.pdf —
// "What the contract still needs" — for the exact list this file gives
// a concrete Dart shape to: incremental sync, pagination/rate limits,
// retry/backoff with dead-letter, connection health, sync observability.

/// Opaque per-connector watermark. Adapters decide what's actually
/// inside [value] — a Paystack adapter might store a `created_at`
/// timestamp, a paginated REST adapter a page token, a webhook-driven
/// channel adapter the id of the last event it successfully processed.
/// The contract only needs to persist and hand it back; it never
/// interprets it.
class SyncCursor {
  const SyncCursor(this.value);

  /// JSON-encodable — usually a String, but left untyped so an adapter
  /// can store a small Map if one field isn't enough (e.g. a page token
  /// AND a timestamp). Callers that only need a single string watermark
  /// can just pass one.
  final Object? value;

  static const SyncCursor none = SyncCursor(null);

  bool get isEmpty => value == null;

  @override
  String toString() => 'SyncCursor($value)';
}

/// What one sync attempt produced. Every adapter returns one of these
/// from [ConnectorAdapter.sync] — this is what turns "did it work" into
/// numbers an owner can actually read, per the contract's "sync
/// observability" requirement: last sync, records seen, records
/// changed, errors, per connector, visible to the owner.
class SyncResult {
  const SyncResult({
    required this.recordsSeen,
    required this.recordsChanged,
    this.nextCursor = SyncCursor.none,
    this.errors = const [],
  });

  /// A sync that touched nothing — a webhook-driven adapter reporting
  /// "no pull needed, I'm push-fed" between events, or a genuinely empty
  /// pull. Distinct from a FAILED sync, which throws instead of
  /// returning this.
  const SyncResult.empty()
      : recordsSeen = 0,
        recordsChanged = 0,
        nextCursor = SyncCursor.none,
        errors = const [];

  final int recordsSeen;
  final int recordsChanged;

  /// What [ConnectorAdapter.sync] should be called with next time —
  /// persisted by the caller (see connector_sync_log_repository.dart),
  /// never by the adapter itself. An adapter with no incremental concept
  /// yet (a full-refresh-only source) can leave this as [SyncCursor.none].
  final SyncCursor nextCursor;

  /// Non-fatal, per-record problems from THIS run — "row 41 had no
  /// email, skipped" — as opposed to the run-level failure that makes
  /// [ConnectorAdapter.sync] throw instead of returning at all. Both are
  /// worth keeping distinct: a sync that half-succeeded is not the same
  /// owner-facing story as one that never ran.
  final List<String> errors;

  bool get hadErrors => errors.isNotEmpty;
}

/// What an adapter declares about itself once, not what it did on any
/// particular run — the contract's "pagination and rate limits,
/// declared per adapter, honoured by the framework" requirement.
class ConnectorCapabilities {
  const ConnectorCapabilities({
    this.supportsIncrementalSync = false,
    this.supportsPagination = false,
    this.maxRequestsPerMinute,
    this.isPushDriven = false,
  });

  /// Can [ConnectorAdapter.sync] be called with a non-empty cursor and
  /// do less work than a full read? False for a source with no concept
  /// of "since" (most CSV/file-upload sources).
  final bool supportsIncrementalSync;

  final bool supportsPagination;

  /// Null means "the adapter does not declare a limit" — the shared
  /// retry/backoff layer then falls back to its own conservative
  /// default rather than assuming unlimited.
  final int? maxRequestsPerMinute;

  /// True for a channel like WhatsApp or Telegram, whose "sync" is
  /// really "the platform pushes events to our webhook, and calling
  /// sync() just replays/reconciles against what's already arrived"
  /// rather than an adapter reaching out and pulling. Declared
  /// explicitly rather than inferred from `supportsPagination == false`,
  /// because a push-driven source can still be genuinely broken in a way
  /// that is worth surfacing differently from "this pull-based source
  /// has nothing new."
  final bool isPushDriven;
}

/// What [ConnectorAdapter.health] answers with. Deliberately a richer
/// type than a bool — "an expired OAuth token looks exactly like
/// 'connected' until something is attempted" (PART III) is exactly the
/// distinction [message] exists to carry back to the owner, in their own
/// language, not a log reader's.
class ConnectorHealth {
  const ConnectorHealth.healthy() : healthy = true, message = null;
  const ConnectorHealth.unhealthy(this.message) : healthy = false;

  final bool healthy;
  final String? message;
}

/// What happens to already-ingested data when a workspace disconnects a
/// connector. A field on the connector's stored state (see migration
/// 036), not a hardcoded assumption — the contract's "deletion and
/// retention" requirement, answered as a stored, per-connector decision
/// rather than left implicit.
abstract class RetentionPolicy {
  /// Credentials are revoked/cleared; everything already ingested
  /// (messages, conversations, ingested records) is kept. This is the
  /// existing, already-shipped behavior for WhatsApp/Telegram —
  /// ChannelRepository.markDisconnected and
  /// WorkspaceConnectorRepository.disconnect both already keep every row
  /// and only clear the live credential. Named here explicitly so it is
  /// a documented policy rather than an accident of how those methods
  /// happened to be written.
  static const retainOnDisconnect = 'retain_on_disconnect';

  /// Reserved for a future connector where an owner disconnecting really
  /// does mean "and forget everything you read from it" — no adapter
  /// implements this today. Declaring the value now means a future
  /// implementation has a name to target instead of inventing one under
  /// deadline.
  static const deleteOnDisconnect = 'delete_on_disconnect';

  static const values = [retainOnDisconnect, deleteOnDisconnect];
}
