// supabase_client.dart
//
// Initialises the Supabase client ONCE at server startup and exposes a
// global getter. Every repository in this project uses this same instance —
// this is the ONLY file that constructs a SupabaseClient.
//
// WHY service_role key (not anon key):
//   The server is trusted code — it's never shipped to a browser or device.
//   Using service_role bypasses Row Level Security (RLS) at the database
//   level, which is fine here because OUR repository layer is what enforces
//   workspace isolation (SRS.md §5) — every repository method that touches
//   a workspace-scoped table must filter by workspace_id explicitly. The
//   anon key would be for untrusted clients (a browser calling Supabase
//   directly), which is not how this project talks to its database — the
//   dashboard/API only ever talks to Supabase indirectly, through this
//   server's endpoints.
//
// WHY THIS EXISTS (reuse-before-rebuild):
//   Copied from degenbot_server's supabase_client.dart — same rationale,
//   same shape. If we ever switch persistence providers, this file (plus
//   each model's DTO) is the entire blast radius; endpoints and business
//   logic never import Supabase directly.

import 'package:logging/logging.dart';
import 'package:supabase/supabase.dart';
import 'package:kola_server/src/config/env.dart';

final _log = Logger('SupabaseClient');

late final SupabaseClient _client;

/// Call this once from server.dart's run() before starting Serverpod.
Future<void> initSupabase() async {
  _log.info('Initialising Supabase client → ${Env.supabaseUrl}');
  _client = SupabaseClient(Env.supabaseUrl, Env.supabaseServiceRoleKey);
  _log.info('Supabase client ready');
}

/// Global accessor — import this in every repository, nowhere else.
SupabaseClient get supabase => _client;
