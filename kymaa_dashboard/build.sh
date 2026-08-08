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
# KOLA_SERVER_URL defaults to http://localhost:8080 (see
# lib/config/env.dart) if not set, for local dev against a kola_server
# instance started with `dart run bin/main.dart`.
#
# KOLA_DOCS_URL (task #138) — the deployed kola_docs site's public base
# URL, for the sidebar's Docs link. Defaults to https://docs.kola.app
# (see lib/config/env.dart) — override once you know your docs site's
# real domain.

set -e

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
# The deployed Serverpod backend (Northflank). Defaulted here so a
# deploy does not depend on remembering it — localhost:8090 was the
# old default, which silently produced a build that logged in fine
# and then failed every data call in production.
#
# Override for local work: KOLA_SERVER_URL=http://localhost:8090 ./build.sh
KOLA_SERVER_URL="${KOLA_SERVER_URL:-https://p02--kola--hnnl8wyj78qp.code.run}"
# Was https://docs.kola.app — a kola-branded link inside the kymaa
# build. Same override note as above: this value wins over the one in
# lib/config/env.dart, because this script always passes the flag.
#
# ⚠ docs.kymaa.online DOES NOT EXIST YET. The sidebar Docs link will
#   404 until it does. Override with KOLA_DOCS_URL=... to point it
#   somewhere real in the meantime.
KOLA_DOCS_URL="${KOLA_DOCS_URL:-https://docs.kymaa.online}"

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
  echo "❌ Missing env vars: SUPABASE_URL and SUPABASE_ANON_KEY required"
  echo "   Export them or edit this script with your Supabase project values."
  exit 1
fi

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
  -DKOLA_DOCS_URL="$KOLA_DOCS_URL"

echo "✅ Build complete → web/"
echo "   Deploy the web/ directory to your static host."



