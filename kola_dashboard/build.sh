#!/usr/bin/env bash
# Build the Kola dashboard (Jaspr client-mode).
# Run from the kola_dashboard/ directory.
#
# Usage:
#   SUPABASE_URL=https://xxxx.supabase.co \
#   SUPABASE_ANON_KEY=eyJh... \
#   KOLA_SERVER_URL=https://api.kola.dev \
#   ./build.sh
#
# SUPABASE_ANON_KEY is safe to bake into this public bundle — same
# reasoning as kola_landing/build.sh: it's the public/anon key, Row
# Level Security (enforced server-side, not by this key) is what
# actually protects data. This dashboard never talks to Supabase's
# REST/Postgrest API directly for real data — only to Supabase Auth
# for login/signup (see lib/services/auth_service.dart) — everything
# else goes through KOLA_SERVER_URL via kola_client.
#
# KOLA_SERVER_URL defaults to https://api.kolaa.co below if not set —
# the real deployed kola_server, so a plain `./build.sh` (with just
# SUPABASE_URL/SUPABASE_ANON_KEY) tests a locally-served dashboard
# against the live backend. For local dev against a kola_server instance
# started with `dart run bin/main.dart` instead, override explicitly:
# KOLA_SERVER_URL=http://localhost:8080 ./build.sh
# (lib/config/env.dart's own compile-time default, used only if this
# script's -D flag is omitted entirely, is separately localhost:8080.)
#
# KOLA_DOCS_URL (task #138) — the deployed kola_docs site's public base
# URL, for the sidebar's Docs link. Defaults to https://docs.kola.app
# (see lib/config/env.dart) — override once you know your docs site's
# real domain.

set -e

# SUPABASE_URL and SUPABASE_ANON_KEY default to the real kola project
# below — both are safe to hardcode (see header above: anon key is
# public-by-design, RLS isn't what protects data here). Defaulting them
# means a plain `./build.sh` with zero env vars just works, rather than
# failing every time one gets forgotten in a long export line.
SUPABASE_URL="${SUPABASE_URL:-https://jwyrmptiehkkizwjbqtg.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eXJtcHRpZWhra2l6d2picXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzE0NzEsImV4cCI6MjEwMDIwNzQ3MX0.jqjS8ZDrdSNj1hT01PTMoEFDFQITA9MoQyQJn4EagBY}"
KOLA_SERVER_URL="${KOLA_SERVER_URL:-https://api.kolaa.co}"
KOLA_DOCS_URL="${KOLA_DOCS_URL:-https://docs.kola.app}"
# Public OAuth client ID, not a secret — see lib/config/env.dart's header.
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-3591873336-klkujp9qlgs76985688s41guv1fvk1dj.apps.googleusercontent.com}"

echo "📦 Installing dependencies..."
dart pub get

echo "🔨 Compiling Jaspr app (KOLA_SERVER_URL=$KOLA_SERVER_URL, KOLA_DOCS_URL=$KOLA_DOCS_URL)..."
dart compile js \
  -O2 \
  -o web/main.dart.js \
  lib/main.dart \
  -DSUPABASE_URL="$SUPABASE_URL" \
  -DSUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  -DKOLA_SERVER_URL="$KOLA_SERVER_URL" \
  -DKOLA_DOCS_URL="$KOLA_DOCS_URL" \
  -DGOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"

echo "✅ Build complete → web/"
echo "   Deploy the web/ directory to your static host."



