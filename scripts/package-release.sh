#!/bin/bash
# Package MinUI build for release

set -e

VERSION=${1:-"MinUI-$(date +%Y%m%d)"}
ARTIFACTS_DIR="artifacts"
RELEASE_DIR="release"
ZIP_NAME="MinUI-CI-Build-${VERSION}.zip"

echo "📦 Packaging release: $VERSION"

# Create release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy all artifacts
if [ -d "$ARTIFACTS_DIR" ]; then
    cp -r "$ARTIFACTS_DIR"/* "$RELEASE_DIR/" 2>/dev/null || true
fi

# Add README
cat > "$RELEASE_DIR/README.txt" << EOF
MinUI CI Build - $VERSION
==========================

This is an automated build of MinUI created by GitHub Actions CI/CD.

Build Information:
- Version: $VERSION
- Build Date: $(date)
- Source: https://github.com/shauninman/MinUI
- CI Repository: $GITHUB_REPOSITORY

Installation:
1. Copy the appropriate firmware file to your device's SD card
2. Follow device-specific flashing instructions
3. Reboot your device

Notes:
- This is an unofficial build
- Use at your own risk
- Report issues to the CI repository

Files included:
$(ls -1 "$RELEASE_DIR" | sed 's/^/- /')

EOF

# Create ZIP archive
cd "$RELEASE_DIR"
zip -r "../$ZIP_NAME" ./*
cd ..

echo "✅ Release packaged: $ZIP_NAME"
echo "📁 Contents:"
unzip -l "$ZIP_NAME" | tail -20
