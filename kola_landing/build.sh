#!/usr/bin/env bash
# Build the Kola landing page (Jaspr client-mode).
# Run from the kola_landing/ directory.
#
# Usage:
#   SUPABASE_URL=https://xxxx.supabase.co \
#   SUPABASE_ANON_KEY=eyJh... \
#   ./build.sh
#
# SUPABASE_ANON_KEY is safe to bake into this public bundle — it's the
# public/anon key, not service_role. Row Level Security is what actually
# protects data (see lib/services/waitlist_api_service.dart's header
# comment for the exact RLS policy this page depends on).
#
# LAUNCH_MODE (optional, defaults to "waitlist"): set to "launched" at
# real launch to flip the whole page over. This is a build-time-only
# flag — there is no runtime UI control for it (see lib/config/env.dart's
# header comment). Example:
#   LAUNCH_MODE=launched SUPABASE_URL=... SUPABASE_ANON_KEY=... ./build.sh

set -e

# SUPABASE DEFAULTS (2026-09-09): hardcoded rather than required, so a
# plain ./build.sh (or ./deploy.sh, which sources these same defaults —
# see that script's own note) just works. Safe to hardcode: this is the
# anon/public key, protected by Row Level Security, not by secrecy — see
# the comment above. Override by exporting your own values before
# running this script, same as always.
SUPABASE_URL="${SUPABASE_URL:-https://jwyrmptiehkkizwjbqtg.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eXJtcHRpZWhra2l6d2picXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzE0NzEsImV4cCI6MjEwMDIwNzQ3MX0.jqjS8ZDrdSNj1hT01PTMoEFDFQITA9MoQyQJn4EagBY}"
LAUNCH_MODE="${LAUNCH_MODE:-waitlist}"

echo "📦 Installing dependencies..."
dart pub get

echo "🔨 Compiling Jaspr app (LAUNCH_MODE=$LAUNCH_MODE)..."
dart compile js \
  -O2 \
  -o web/main.dart.js \
  lib/main.dart \
  -DSUPABASE_URL="$SUPABASE_URL" \
  -DSUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -DLAUNCH_MODE="$LAUNCH_MODE"

echo "✅ Build complete → web/"
echo "   Deploy the web/ directory to your static host."
