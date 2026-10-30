#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.8}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.cache/protegeela/flutter/$FLUTTER_VERSION}"

: "${API_BASE_URL:?Configure a URL publica HTTPS da API Java}"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_HOME"
elif [ "$(git -C "$FLUTTER_HOME" rev-parse HEAD)" != "$(git -C "$FLUTTER_HOME" rev-parse "refs/tags/$FLUTTER_VERSION^{commit}" 2>/dev/null || true)" ]; then
  git -C "$FLUTTER_HOME" fetch --depth 1 origin "$FLUTTER_VERSION"
  git -C "$FLUTTER_HOME" checkout FETCH_HEAD
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --enable-web
flutter pub get --enforce-lockfile
# Validate the endpoint before compiling and generate host policy afterwards.
dart run scripts/configure_web_host.dart --validate-only
flutter build web --release --csp --no-web-resources-cdn \
  --dart-define="API_BASE_URL=$API_BASE_URL"
dart run scripts/configure_web_host.dart
