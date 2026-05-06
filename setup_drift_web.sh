#!/usr/bin/env bash

# This script downloads the necessary WASM files for Drift modern web support.
# Run this from the project root.

echo "Setting up Drift WASM assets..."

mkdir -p web

# Download sqlite3.wasm
# Using a stable CDN or official sqlite.org paths
echo "Downloading sqlite3.wasm..."
curl -L https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.1.0/sqlite3.wasm -o web/sqlite3.wasm

# Note: drift_worker.js is usually generated or provided by the drift package.
# In a standard setup, you can use the one from drift's examples or 
# let drift handle it if you use a custom worker.
# For simplicity, we'll assume the user will use the default provided by the implementation.

echo "Assets downloaded to web/ directory."
echo "Ensure your web server serves .wasm files with the 'application/wasm' MIME type."
