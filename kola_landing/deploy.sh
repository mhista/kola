#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# ⚠  PROJECT NAME CHANGED — Aug 2026. DO NOT REVERT.
#
#   Cloudflare Pages project : kola-landing     (was: kola)
#
# WHY: the "kola" project is serving the OLD landing page at
# kymaa.online — the competition entry. This script defaulted to "kola",
# which meant a single ./deploy.sh here would have overwritten it with
# the new site, silently and irreversibly.
#
# The old landing lives in kymaa_landing/ and deploys to "kola" on
# purpose. This one must stay on its own project.
# ─────────────────────────────────────────────────────────────────────────
# ============================================================================
# deploy.sh — Build + deploy the Kola landing page to Cloudflare Pages
# ============================================================================
# PREREQUISITES (one-time setup):
#   1. Install Node.js (https://nodejs.org) — needed for Wrangler CLI
#   2. npm install -g wrangler
#   3. wrangler login          ← opens browser, signs in to Cloudflare
#   4. Get your Supabase ANON key:
#        <your Supabase project> → Settings → API → "Project API keys"
#        → copy the "anon / public" key (NOT service_role)
#   5. In Supabase, create the RLS policy waitlist_api_service.dart's
#      header comment documents — anon must be allowed to INSERT into
#      waitlist_signups (and only insert, never select).
#
# FIRST DEPLOY (creates the Cloudflare Pages project):
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./deploy.sh
#
# SUBSEQUENT DEPLOYS (just re-run):
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./deploy.sh
#
# LAUNCH_MODE (optional, defaults to "waitlist"): set to "launched" at
# real launch — build-time-only flag, no runtime UI control. Example:
#   LAUNCH_MODE=launched SUPABASE_URL=... SUPABASE_ANON_KEY=... ./deploy.sh
# ============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
LAUNCH_MODE="${LAUNCH_MODE:-waitlist}"
PROJECT_NAME="${PROJECT_NAME:-kola-landing}"

# ── BRANCH: THE REASON A "SUCCESSFUL" DEPLOY CHANGED NOTHING ──────────────────
#
# This project's production branch is named `production`. wrangler infers
# the branch from GIT instead, and this repo is on `main` — so every
# deploy landed as a PREVIEW at main.kola-landing.pages.dev, while
# kola-landing.pages.dev and kolaa.co kept serving a 25-day-old build
# from before the rename.
#
# Nothing in wrangler's output says "preview". It prints ✨ Success, gives
# a deployment URL that genuinely works, and an alias URL — and the URL
# you actually go and check is a third one it never mentions.
#
# `--branch production` is therefore NOT a description of where the code
# lives. It names the Cloudflare ENVIRONMENT to publish into, and it
# happens to be a git-shaped word for something that is not a git branch
# here. Do not "correct" this to match the checked-out branch.
#
# Verified 15 Aug 2026: main.* served the renamed copy and the apex served
# the old one, at the same moment.
BRANCH="${BRANCH:-production}"

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
  echo ""
  echo "❌  SUPABASE_URL and/or SUPABASE_ANON_KEY are not set."
  echo ""
  echo "    Get the anon key from your Supabase project:"
  echo "    Settings → API → Project API keys → anon (public) row"
  echo ""
  echo "    Then run:"
  echo "    SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./deploy.sh"
  echo ""
  exit 1
fi

# ── Check wrangler ────────────────────────────────────────────────────────────
if ! command -v wrangler &>/dev/null && ! command -v npx &>/dev/null; then
  echo "❌  wrangler CLI not found. Install it with: npm install -g wrangler"
  exit 1
fi

WRANGLER="wrangler"
if ! command -v wrangler &>/dev/null; then
  WRANGLER="npx wrangler"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "📦  Building Kola landing page..."
echo "    SUPABASE_URL = $SUPABASE_URL"
echo "    LAUNCH_MODE  = $LAUNCH_MODE"
echo ""

SUPABASE_URL="$SUPABASE_URL" \
SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
LAUNCH_MODE="$LAUNCH_MODE" \
./build.sh

echo ""
echo "🚀  Deploying to Cloudflare Pages (project: $PROJECT_NAME)..."
echo ""

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME" --branch "$BRANCH"

PAGES_URL="https://$PROJECT_NAME.pages.dev"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  Landing page deployed!"
echo ""
echo "  URL:  $PAGES_URL"
echo ""
echo "  ── Next steps ───────────────────────────────────────────────"
echo ""
echo "  1. Point your real domain (e.g. kola.app) at this Cloudflare"
echo "     Pages project via a CNAME, once you've registered it."
echo ""
echo "  2. Confirm the waitlist RLS policy is live — submit a test"
echo "     signup on $PAGES_URL and check it lands in the"
echo "     waitlist_signups table in Supabase."
echo ""
echo "  3. Once real launch is ready: redeploy with"
echo "     LAUNCH_MODE=launched — no code changes needed, it's a"
echo "     build-time flag (see lib/config/env.dart)."
echo "═══════════════════════════════════════════════════════════════"
echo ""
