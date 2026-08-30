#!/usr/bin/env bash
# Build kola_admin (Jaspr client-mode). Run from the kola_admin/ directory.
#
# Usage:
#   KOLA_SERVER_URL=https://api.kolaa.co ./build.sh
#
# KOLA_SERVER_URL defaults to the real deployed kola_server below, same
# convention as kola_dashboard/build.sh. Override for local dev:
#   KOLA_SERVER_URL=http://localhost:8080 ./build.sh

set -e

KOLA_SERVER_URL="${KOLA_SERVER_URL:-https://api.kolaa.co}"

echo "📦 Installing dependencies..."
dart pub get

echo "🔨 Compiling Jaspr app (KOLA_SERVER_URL=$KOLA_SERVER_URL)..."
dart compile js \
  -O2 \
  -o web/main.dart.js \
  lib/main.dart \
  -DKOLA_SERVER_URL="$KOLA_SERVER_URL"

echo "✅ Build complete → web/"
echo "   Deploy the web/ directory to your static host."
