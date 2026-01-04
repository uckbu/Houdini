#!/bin/bash
# Build script for Houdini.app

set -e

echo "Building Houdini..."
swift build -c release

echo "Creating app bundle..."
mkdir -p Houdini.app/Contents/MacOS
mkdir -p Houdini.app/Contents/Resources

cp .build/release/Houdini Houdini.app/Contents/MacOS/
cp Info.plist Houdini.app/Contents/

echo "Generating app icon from Resources/AppIcon.png..."
mkdir -p AppIcon.iconset
for size in 16 32 128 256 512; do
    sips -s format png -z $size $size Resources/AppIcon.png --out AppIcon.iconset/icon_${size}x${size}.png
    double=$((size * 2))
    sips -s format png -z $double $double Resources/AppIcon.png --out AppIcon.iconset/icon_${size}x${size}@2x.png
done
iconutil -c icns AppIcon.iconset -o Houdini.app/Contents/Resources/AppIcon.icns
rm -rf AppIcon.iconset

echo "Creating zip for distribution..."
rm -f Houdini.app.zip
zip -r Houdini.app.zip Houdini.app

echo "Done! Houdini.app is ready."
