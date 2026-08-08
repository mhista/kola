#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# ⚠  DEPLOYS THE COMPETITION ENTRY. READ BEFORE RUNNING.
#
#   Cloudflare Pages project : kola          ← NOT "kymaa"
#   Live domain              : kymaa.online
#
# THE PROJECT IS NAMED "kola" AND THAT IS NOT A MISTAKE. This landing
# page was deployed to the "kola" Pages project before the product was
# renamed, and it is still serving from there. The project name is
# historical; the site it serves is kymaa.
#
# An earlier version of this header claimed the project was "kymaa" and
# the domain "kymaa.tech". Both were wrong. Corrected against what is
# actually live, Aug 2026.
#
# ⚠  kola_landing/deploy.sh (the NEW landing page) used to default to
#    this same "kola" project. Running it would have replaced this site.
#    It now defaults to "kola-landing". Do not undo that.
# ─────────────────────────────────────────────────────────────────────────
# ============================================================================
# deploy.sh — Build + deploy the KYMAA copy of the Kola landing page to
# its OWN Cloudflare Pages project (separate from kola_landing's "kola"
# project — see this repo's pubspec.yaml for why this is a full copy,
# not a second custom domain on the same project). Content is identical
# to kola_landing; only the deploy target differs.
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
# FIRST DEPLOY (creates the Cloudflare Pages project — named "kymaa" by
# default, see PROJECT_NAME below):
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./deploy.sh
#
# SUBSEQUENT DEPLOYS (just re-run):
#   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./deploy.sh
#
# LAUNCH_MODE (optional, defaults to "waitlist"): set to "launched" at
# real launch — build-time-only flag, no runtime UI control. Example:
#   LAUNCH_MODE=launched SUPABASE_URL=... SUPABASE_ANON_KEY=... ./deploy.sh
#
# AFTER THIS FIRST DEPLOY, POINT kymaa.tech AT IT (in the Cloudflare
# dashboard, NOT this script — wrangler doesn't manage custom domains):
#   1. dash.cloudflare.com → sign in
#   2. If kymaa.tech isn't already a zone in this Cloudflare account: Add
#      a site → kymaa.tech → follow the nameserver-change instructions at
#      your registrar (skip this if you registered it through Cloudflare
#      directly — it's already there).
#   3. Workers & Pages → your "kymaa" Pages project → Custom domains →
#      Set up a custom domain → enter "kymaa.tech" → Cloudflare adds the
#      DNS record for you automatically since the zone is already there.
#   4. DNS updates are near-instant when the zone is on Cloudflare; give
#      it a few minutes and reload kymaa.tech.
# ============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
# ⚠ THIS IS THE DEFAULT THAT WINS. deploy.sh passes LAUNCH_MODE down to
#   build.sh, which passes it to the compiler — so the defaults in
#   build.sh and lib/config/env.dart never apply to a deploy made
#   through this script. All three were changed together.
#
#   This page is live now, not collecting a waitlist. In "waitlist" mode
#   every pricing CTA is relabelled "Join waitlist" and scrolls to the
#   form instead of going to the dashboard.
LAUNCH_MODE="${LAUNCH_MODE:-launched}"
PROJECT_NAME="${PROJECT_NAME:-kola}"

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
echo "📦  Building the Kymaa copy of the Kola landing page..."
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

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME"

PAGES_URL="https://$PROJECT_NAME.pages.dev"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  Landing page deployed!"
echo ""
echo "  URL:  $PAGES_URL"
echo ""
echo "  ── Next steps ───────────────────────────────────────────────"
echo ""
echo "  1. Point kymaa.tech at this Cloudflare Pages project — see this"
echo "     script's header for the exact dash.cloudflare.com steps."
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
