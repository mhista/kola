#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# ⚠  PROJECT NAME CHANGED — Aug 2026.
#
#   Cloudflare Pages project : kola-app     (was: kola-dashboard)
#
# WHY: kymaa_dashboard/ (the frozen competition dashboard) was recovered
# from the same codebase and originally carried this script with the
# "kola-dashboard" default. Moving the NEW dashboard to its own project
# means the two can never overwrite each other regardless of which
# folder someone runs deploy.sh from.
# ─────────────────────────────────────────────────────────────────────────
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
# SUPABASE_URL, SUPABASE_ANON_KEY and GOOGLE_CLIENT_ID all default to the
# real kola project's values below, so the plain form just works:
#   KOLA_SERVER_URL=https://api.kolaa.co ./deploy.sh
#
# Override any of them explicitly if you ever need to point at a
# different Supabase project or OAuth client:
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... \
#   KOLA_SERVER_URL=https://api.kolaa.co ./deploy.sh
#
# SUBSEQUENT DEPLOYS: same command again.
#
# PROJECT_NAME (optional, defaults to "kola-dashboard"):
#   PROJECT_NAME=kola-app ./deploy.sh
# ============================================================================

set -e

# Defaulted for the same reason build.sh's are — see that script's own
# note. Both safe to hardcode: anon key is public-by-design.
SUPABASE_URL="${SUPABASE_URL:-https://jwyrmptiehkkizwjbqtg.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eXJtcHRpZWhra2l6d2picXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzE0NzEsImV4cCI6MjEwMDIwNzQ3MX0.jqjS8ZDrdSNj1hT01PTMoEFDFQITA9MoQyQJn4EagBY}"
KOLA_SERVER_URL="${KOLA_SERVER_URL:-https://api.kolaa.co}"
# Task #138 — sidebar Docs link; see build.sh's own note.
KOLA_DOCS_URL="${KOLA_DOCS_URL:- https://kola-docs.pages.dev}"
# Public OAuth client ID, not a secret — see lib/config/env.dart's header.
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-3591873336-klkujp9qlgs76985688s41guv1fvk1dj.apps.googleusercontent.com}"
PROJECT_NAME="${PROJECT_NAME:-kola-app}"

# ── BRANCH: verified live 19 Aug 2026, kola-app specifically ────────────────
# Unlike kola-landing/kola-docs (whose Cloudflare Pages "Production branch"
# setting really is named `production` — see kola_landing/deploy.sh's own
# header), kola-app's is `main`: a deploy tagged --branch production landed
# as PREVIEW at a *.kola-app.pages.dev url, while the existing --branch main
# deploy was the one Cloudflare actually served at dash.kolaa.co. Copying
# kola_landing's `production` default onto this script without checking
# kola-app's own Settings → Builds & deployments was the bug — don't repeat
# it by "fixing" this back to `production` without checking that page first.
BRANCH="${BRANCH:-main}"

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
GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
./build.sh

echo ""
echo "🚀  Deploying to Cloudflare Pages (project: $PROJECT_NAME)..."
echo ""

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME" --branch "$BRANCH"

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


