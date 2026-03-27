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

# Build the web application in release mode
# Note: Using --no-tree-shake-icons as it was used in previous sessions
echo "Building Flutter Web..."
flutter build web --release --no-tree-shake-icons

echo "Build complete. Ready to publish build/web directory."
