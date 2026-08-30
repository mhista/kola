#!/usr/bin/env bash
# ============================================================================
# deploy.sh — Build + deploy kola_admin to Cloudflare Pages
# ============================================================================
# SEPARATE PROJECT from kola_dashboard/kola-app on purpose — this is the
# internal control plane (ADMIN_APP_SPEC.md §1), never indexed
# (web/index.html's robots meta), and gets its own hostname so it is never
# one accidental link away from a customer.
#
# PREREQUISITES (one-time, same as kola_dashboard/deploy.sh):
#   1. Install Node.js
#   2. npm install -g wrangler
#   3. wrangler login
#
# Usage:
#   KOLA_SERVER_URL=https://api.kolaa.co ./deploy.sh
#
# PROJECT_NAME (optional, defaults to "kola-admin"):
#   PROJECT_NAME=kola-admin-internal ./deploy.sh
# ============================================================================

set -e

KOLA_SERVER_URL="${KOLA_SERVER_URL:-https://api.kolaa.co}"
PROJECT_NAME="${PROJECT_NAME:-kola-admin}"
# Same reasoning as kola_dashboard/deploy.sh's own BRANCH note — verify
# against this Pages project's actual "Production branch" setting before
# assuming `main` if a deploy ever lands as preview instead of production.
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
echo "📦  Building kola_admin..."
echo "    KOLA_SERVER_URL  = $KOLA_SERVER_URL"
echo ""

KOLA_SERVER_URL="$KOLA_SERVER_URL" ./build.sh

echo ""
echo "🚀  Deploying to Cloudflare Pages (project: $PROJECT_NAME)..."
echo ""

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME" --branch "$BRANCH"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  kola_admin deployed! → https://$PROJECT_NAME.pages.dev"
echo ""
echo "  This URL is never indexed (see web/index.html) but is NOT"
echo "  otherwise access-restricted at the network level — anyone with"
echo "  the link can reach the login page. Auth is the only gate."
echo "  Consider Cloudflare Access in front of this project if that's"
echo "  not sufficient for your threat model."
echo "═══════════════════════════════════════════════════════════════"
echo ""
