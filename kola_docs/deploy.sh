#!/usr/bin/env bash
# ============================================================================
# deploy.sh — Build + deploy the Kola docs site to Cloudflare Pages
# ============================================================================
# PREREQUISITES (one-time, same as kola_landing's deploy.sh):
#   1. Install Node.js — needed for the Wrangler CLI
#   2. npm install -g wrangler
#   3. wrangler login
#
# FIRST DEPLOY (creates the Cloudflare Pages project):
#   ./deploy.sh
#
# SUBSEQUENT DEPLOYS: just re-run ./deploy.sh
#
# PROJECT_NAME (optional, defaults to "kola-docs"):
#   PROJECT_NAME=kola-developer-docs ./deploy.sh
# ============================================================================

set -e

PROJECT_NAME="${PROJECT_NAME:-kola-docs}"

if ! command -v wrangler &>/dev/null && ! command -v npx &>/dev/null; then
  echo "❌  wrangler CLI not found. Install it with: npm install -g wrangler"
  exit 1
fi

WRANGLER="wrangler"
if ! command -v wrangler &>/dev/null; then
  WRANGLER="npx wrangler"
fi

echo ""
echo "📦  Building Kola docs site..."
echo ""

./build.sh

echo ""
echo "🚀  Deploying to Cloudflare Pages (project: $PROJECT_NAME)..."
echo ""

$WRANGLER pages deploy web/ --project-name "$PROJECT_NAME"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  Docs site deployed! → https://$PROJECT_NAME.pages.dev"
echo ""
echo "  Point docs.kola.app (or your chosen subdomain) at this"
echo "  Cloudflare Pages project via a CNAME once registered."
echo "═══════════════════════════════════════════════════════════════"
echo ""
