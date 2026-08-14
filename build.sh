#!/bin/bash
set -e

echo "Cleaning previous build cache..."
rm -rf flutter build/web

if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "Building Flutter Web application..."
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "Copying API functions to build/web..."
mkdir -p build/web/api
cp -r api/* build/web/api/ 2>/dev/null || true

echo "Build completed successfully!"
