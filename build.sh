#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.5}"
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_HOME"
else
  git -C "$FLUTTER_HOME" fetch --depth 1 origin "$FLUTTER_VERSION"
  git -C "$FLUTTER_HOME" checkout FETCH_HEAD
fi

export PATH="$PATH:$FLUTTER_HOME/bin"

flutter config --enable-web
flutter pub get
flutter build web --release --csp --no-web-resources-cdn
