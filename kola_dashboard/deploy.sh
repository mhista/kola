#!/usr/bin/env bash
# ============================================================================
# deploy.sh — Build + deploy the Kola dashboard to Cloudflare Pages
# ============================================================================
# TASK #107 — SPA FALLBACK: kola_dashboard is a client-routed single-page
# app (jaspr_router, see lib/app.dart) — a direct browser navigation or
# hard-refresh on e.g. /errands must be served index.html (so the router
# can take over), not a plain static-file 404. Cloudflare Pages does this
# AUTOMATICALLY for every deployment with no config file needed — "Pages'
# default single-page application behavior matches all incoming paths to
# the root, allowing you to capture URLs like /about... from within your
# SPA" (developers.cloudflare.com/pages/configuration/serving-pages/).
#
# DO NOT add a web/_redirects file with the seemingly-obvious `/* /index.html
# 200` rule — Cloudflare's own build system detects that specific rule as
# an infinite loop and ignores it (confirmed via a live Cloudflare
# Community/GitHub report, not assumed). The built-in behavior above is
# both simpler and the one that actually works — nothing to configure here.
#
# LOCAL DEV STILL NEEDS THIS HANDLED MANUALLY: `python3 -m http.server` (or
# any other plain static file server) has no SPA fallback and WILL 404 on
# a direct load of /errands locally. Use a server that supports it instead,
# e.g.:
#   npx serve -s web       # `-s` = rewrite every unmatched path to index.html
#
# PREREQUISITES (one-time, same as kola_landing/kola_docs's deploy.sh):
#   1. Install Node.js — needed for the Wrangler CLI (and `npx serve` above)
#   2. npm install -g wrangler
#   3. wrangler login
#
# FIRST DEPLOY (creates the Cloudflare Pages project):
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... \
#   KOLA_SERVER_URL=https://api.kola.app ./deploy.sh
#
# SUBSEQUENT DEPLOYS: same command again.
#
# PROJECT_NAME (optional, defaults to "kola-dashboard"):
#   PROJECT_NAME=kola-app ./deploy.sh
# ============================================================================

set -e

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
KOLA_SERVER_URL="${KOLA_SERVER_URL:-http://localhost:8090}"
# Task #138 — sidebar Docs link; see build.sh's own note.
KOLA_DOCS_URL="${KOLA_DOCS_URL:- https://kola-docs.pages.dev}"
PROJECT_NAME="${PROJECT_NAME:-kola-dashboard}"

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
  echo ""
  echo "❌  SUPABASE_URL and/or SUPABASE_ANON_KEY are not set."
  echo ""
  echo "    SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... \\"
  echo "    KOLA_SERVER_URL=https://api.kola.app ./deploy.sh"
  echo ""
  exit 1
fi

if ! command -v wrangler &>/dev/null && ! command -v npx &>/dev/null; then
  echo "❌  wrangler CLI not found. Install it with: npm install -g wrangler"
  exit 1
fi

WRANGLER="wrangler"
if ! command -v wrangler &>/dev/null; then
  WRANGLER="npx wrangler"
fi

echo ""
echo "📦  Building Kola dashboard..."
echo "    SUPABASE_URL     = $SUPABASE_URL"
echo "    KOLA_SERVER_URL  = $KOLA_SERVER_URL"
echo ""

SUPABASE_URL="$SUPABASE_URL" \
SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
KOLA_SERVER_URL="$KOLA_SERVER_URL" \
KOLA_DOCS_URL="$KOLA_DOCS_URL" \
./build.sh

echo ""
echo "🚀  Deploying to Cloudflare Pages (project: $PROJECT_NAME)..."
echo ""

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  Dashboard deployed! → https://$PROJECT_NAME.pages.dev"
echo ""
echo "  Direct links like https://$PROJECT_NAME.pages.dev/errands should"
echo "  load correctly (Cloudflare Pages' built-in SPA fallback — see"
echo "  this script's header). If they 404 instead, re-check the Pages"
echo "  project's Build settings before assuming code is at fault."
echo "═══════════════════════════════════════════════════════════════"
echo ""


