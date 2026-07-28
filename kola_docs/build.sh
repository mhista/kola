#!/usr/bin/env bash
# Build the Kola docs site (Jaspr client-mode). Run from kola_docs/.
#
# Unlike kola_landing/kola_dashboard, this site makes NO network calls at
# all — every "call" shown on every page is inert example text (a code
# block, not a live request), so there is nothing to configure at build
# time. No env vars, no -D flags.

set -e

echo "📦 Installing dependencies..."
dart pub get

echo "🔨 Compiling Jaspr app..."
dart compile js -O2 -o web/main.dart.js lib/main.dart

echo "✅ Build complete → web/"
echo "   Deploy the web/ directory to your static host."
