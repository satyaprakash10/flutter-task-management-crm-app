#!/usr/bin/env bash
set -euo pipefail

# Install Flutter stable
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.24.0"

echo "Installing Flutter ${FLUTTER_VERSION}-${FLUTTER_CHANNEL}..."
mkdir -p "$HOME/flutter"
pushd "$HOME" >/dev/null
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -o flutter.tar.xz
mkdir -p flutter-sdk
tar xf flutter.tar.xz -C flutter-sdk --strip-components=1
export PATH="$HOME/flutter-sdk/bin:$PATH"
flutter --version
popd >/dev/null

# Enable web support
flutter config --enable-web

# Fetch packages and build
flutter pub get
flutter build web --release

echo "Build complete. Output at build/web" 