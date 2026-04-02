#!/usr/bin/env bash

# Exit on error
set -o errexit

# Define Flutter version/channel
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.22.0" # You can adjust this to match your local version

# Download and install Flutter if not already present
if [ ! -d "flutter" ]; then
    echo "Downloading Flutter..."
    git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL --depth 1
fi

# Add Flutter to the path
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-download Flutter dependencies
flutter precache --web

# Check Flutter version
flutter --version

echo "Building Flutter Web..."
flutter build web --release --no-tree-shake-icons

echo "Publishing APK to distribution directory..."
mkdir -p build/web/dist
cp downloads/ironbook_gm_latest.apk build/web/dist/

echo "Build complete. Ready to publish build/web directory."
