#!/usr/bin/env bash
# ============================================================================
# deploy.sh — Build + deploy kola_server to Northflank
# ============================================================================
# PHASE 7a — DEPLOYMENT SCRIPTS: the third and last deployable surface in
# this repo (kola_landing and kola_dashboard already have theirs, both
# targeting Cloudflare Pages — see their own deploy.sh headers). kola_server
# is a stateful Dart binary, not a static site, so it needs an actual
# container host rather than a CDN. Northflank was the explicit choice here
# (confirmed with the project owner — no hosting decision existed anywhere
# in docs/ before this).
#
# HOW THIS ACTUALLY WORKS, RESEARCHED FIRST, NOT GUESSED: Northflank's own
# docs (northflank.com/docs/v1/application/build/build-with-a-dockerfile)
# describe builds as GIT-REPOSITORY-linked by default — Northflank clones a
# connected repo and builds the Dockerfile itself. This repo has no `.git`
# yet (see kola_server/README.md's security-note section), so that path
# isn't available today without first setting up a git remote — a separate
# decision, not assumed here.
#
# Northflank also documents a second, git-independent path that fits this
# repo as-is: "Run an image from a container registry"
# (northflank.com/docs/v1/application/run/run-an-image-from-a-container-
# registry) — a deployment service that just pulls a pre-built image by
# path (`[registry]/[account]/[image]:[tag]`, e.g. `docker.io/you/kola-
# server:latest`). This script uses THAT path: build the image locally from
# the existing Dockerfile (same one already used for local testing), push
# it to Docker Hub (Northflank's documented default registry when none is
# specified), then tell Northflank to redeploy that exact image. This is
# the same "build once, push, tell the host to run it" shape flyctl/railway
# CLIs give you elsewhere — Northflank just calls it a "deployment service
# with an external image source" instead.
#
# ONE-TIME SETUP (cannot be scripted — genuinely needs your own account):
#   1. Install the Northflank CLI:      npm i -g @northflank/cli
#   2. Install Docker, and `docker login` to Docker Hub (or your own
#      registry — set REGISTRY below if not Docker Hub).
#   3. Create a Northflank API token (Account/Team settings → API tokens)
#      with "Update Deployment" permission, and set NORTHFLANK_API_TOKEN.
#   4. Create the actual deployment service ONCE, through the Northflank
#      dashboard: https://app.northflank.com/s/project/create/service →
#      "Deployment" → source "External image" → paste
#      docker.io/<your-dockerhub-username>/kola-server:latest (this script
#      pushes that exact tag below, so the path matches) → pick a plan/
#      region → expose port 8080 (kola_server's apiServer port — see
#      server.dart's header on why this, not 8081/8082, is the one
#      kola_dashboard's KOLA_SERVER_URL should point at). Note the
#      resulting Project ID and Service ID for NORTHFLANK_PROJECT_ID /
#      NORTHFLANK_SERVICE_ID below.
#   5. Set every var from kola_server/.env.example as a runtime environment
#      variable/secret on that service (Northflank's dashboard → Service →
#      Environment, or `northflank create secret` — see "Inject runtime
#      variables" in Northflank's docs). Not scripted here on purpose: the
#      exact secret-creation request shape wasn't confirmed against a real
#      account in the environment that authored this script, and guessing
#      at it risks silently creating the wrong thing on your real
#      infrastructure — a one-time paste in the dashboard is safer than a
#      guessed API call for something you set once and rarely touch.
#
# EVERY DEPLOY AFTER THAT (what this script actually automates):
#   NORTHFLANK_API_TOKEN=... NORTHFLANK_PROJECT_ID=... \
#   NORTHFLANK_SERVICE_ID=... DOCKERHUB_USERNAME=... ./deploy.sh
#
# WHY NO AUTOMATED "FIRST DEPLOY CREATES THE SERVICE" LIKE THE OTHER TWO
# deploy.sh SCRIPTS: kola_landing/kola_dashboard's Cloudflare Pages project
# creation is a single confirmed `wrangler pages deploy` call with no other
# required inputs. Northflank's service-creation body additionally needs a
# resource plan and region, values that vary by your account/plan and
# weren't confirmed against a real one here — same "don't guess, ask for
# the one manual step" discipline used everywhere else in this project
# (e.g. the WaitlistEndpoint decision, the Meta Embedded Signup deferral).
# ============================================================================

set -e

NORTHFLANK_API_TOKEN="${NORTHFLANK_API_TOKEN:-}"
NORTHFLANK_PROJECT_ID="${NORTHFLANK_PROJECT_ID:-}"
NORTHFLANK_SERVICE_ID="${NORTHFLANK_SERVICE_ID:-}"
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
# Override this directly if you're not using Docker Hub as the registry.
IMAGE_PATH="${IMAGE_PATH:-docker.io/${DOCKERHUB_USERNAME}/kola-server:${IMAGE_TAG}}"

if [[ -z "$NORTHFLANK_API_TOKEN" || -z "$NORTHFLANK_PROJECT_ID" || -z "$NORTHFLANK_SERVICE_ID" ]]; then
  echo ""
  echo "❌  NORTHFLANK_API_TOKEN / NORTHFLANK_PROJECT_ID / NORTHFLANK_SERVICE_ID are not all set."
  echo ""
  echo "    These come from the one-time manual setup described in this script's"
  echo "    header — create the deployment service once in the Northflank"
  echo "    dashboard, then run:"
  echo ""
  echo "    NORTHFLANK_API_TOKEN=... NORTHFLANK_PROJECT_ID=... \\"
  echo "    NORTHFLANK_SERVICE_ID=... DOCKERHUB_USERNAME=... ./deploy.sh"
  echo ""
  exit 1
fi

if [[ -z "$DOCKERHUB_USERNAME" && "$IMAGE_PATH" == "docker.io/kola-server:${IMAGE_TAG}" ]]; then
  echo ""
  echo "❌  DOCKERHUB_USERNAME is not set (and IMAGE_PATH wasn't overridden either)."
  echo "    Docker Hub image paths need an account name: docker.io/<username>/kola-server."
  echo ""
  exit 1
fi

if ! command -v docker &>/dev/null; then
  echo "❌  Docker not found. Install it first: https://docs.docker.com/get-docker/"
  exit 1
fi

NORTHFLANK="northflank"
if ! command -v northflank &>/dev/null; then
  if command -v npx &>/dev/null; then
    NORTHFLANK="npx @northflank/cli"
  else
    echo "❌  Northflank CLI not found. Install it with: npm i -g @northflank/cli"
    exit 1
  fi
fi

echo ""
echo "🐳  Building kola_server image..."
echo "    IMAGE_PATH = $IMAGE_PATH"
echo ""

# Build context is the repo root, not kola_server/, per the Dockerfile's
# own header comment ("Build from the project root with: docker build -f
# kola_server/Dockerfile .") — it needs the workspace-level pubspec.lock
# alongside kola_server/ to preserve locked dependency versions.
docker build -f Dockerfile -t "$IMAGE_PATH" ..

echo ""
echo "📤  Pushing image to registry..."
echo ""

docker push "$IMAGE_PATH"

echo ""
echo "🔑  Logging in to Northflank..."
echo ""

$NORTHFLANK login -t "$NORTHFLANK_API_TOKEN" -n kola-server-deploy

echo ""
echo "🚀  Redeploying $NORTHFLANK_SERVICE_ID with the new image..."
echo ""

$NORTHFLANK patch service deployment \
  --project "$NORTHFLANK_PROJECT_ID" \
  --service "$NORTHFLANK_SERVICE_ID" \
  --input "{\"deployment\":{\"external\":{\"imagePath\":\"$IMAGE_PATH\"}}}"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅  kola_server deployed!"
echo ""
echo "  Watch the rollout:"
echo "    $NORTHFLANK get service logs --project $NORTHFLANK_PROJECT_ID --service $NORTHFLANK_SERVICE_ID -f"
echo ""
echo "  Once it's healthy, point kola_dashboard's KOLA_SERVER_URL and every"
echo "  business's WhatsApp/Telegram webhook base URL at this service's"
echo "  public Northflank URL (or your own domain, once linked)."
echo "═══════════════════════════════════════════════════════════════"
echo ""
