#!/bin/bash
# MinUI CI Patch Applicator
# Automatically patches MinUI Makefile for CI/CD environments

set -e

echo "🔧 MinUI CI Patch Applicator"
echo "=============================="

# Check if we're in MinUI directory
if [ ! -f "makefile" ]; then
    echo "❌ Error: Not in MinUI directory (makefile not found)"
    echo "📁 Current directory: $(pwd)"
    exit 1
fi

# Backup original Makefile
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="makefile.backup.$TIMESTAMP"
cp makefile "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Function to apply patch safely
apply_sed() {
    local pattern=$1
    local replacement=$2
    local file=$3
    
    echo "Applying: $pattern"
    sed -i.bak "$pattern" "$file" && rm -f "${file}.bak"
}

# Apply critical patches
echo ""
echo "📋 Applying patches..."

# 1. Disable tty check
apply_sed 's/tty -s/# tty -s  # Disabled for CI/' makefile

# 2. Fix find commands (GNU findutils compatibility)
apply_sed 's/find -E /find /g' makefile
apply_sed 's/-iregex /-regextype posix-egrep -iregex /g' makefile

# 3. Remove interactive select menu (replace with auto-select)
if grep -q "select target in" makefile; then
    echo "Patching interactive target selection..."
    sed -i '/select target in/,/^[[:space:]]*done[[:space:]]*$/c\
# Interactive selection disabled for CI\n\
# Auto-building for CI environment\n\
if [ -n "$$CI" ] || [ -n "$$TARGET" ]; then \\\
\techo "CI/Non-interactive mode detected"; \\\
\tif [ -n "$$TARGET" ]; then \\\
\t\tmake $$TARGET; \\\
\telse \\\
\t\tmake rg35xx; \\\
\tfi \\\
else \\\
\techo "Please set TARGET= device or run in CI mode"; \\\
\techo "Available targets: rg35xx rgb30 miyoomini trimuismart m17"; \\\
\texit 1; \\\
fi' makefile
fi

# 4. Add CI detection and auto-build
echo "" >> makefile
echo "# CI/CD Support" >> makefile
echo "# =============" >> makefile
echo "ci: setup build" >> makefile
echo -e "\t@echo \"✅ CI build completed\"" >> makefile
echo "" >> makefile
echo "ci-clean:" >> makefile
echo -e "\trm -rf build" >> makefile
echo -e "\t@echo \"🧹 CI clean completed\"" >> makefile

# Verify patches
echo ""
echo "✅ Patches applied successfully!"
echo ""
echo "🔍 Verification:"
echo "----------------"

# Show key patches
echo "1. tty check disabled:"
grep -n "tty" makefile | head -2

echo ""
echo "2. find commands fixed:"
grep -n "find.*resources" makefile | head -2

echo ""
echo "3. CI targets added:"
grep -n "ci:" makefile

echo ""
echo "🎯 Ready for CI/CD build!"
echo "Usage:"
echo "  make ci              # CI build"
echo "  make TARGET=rg35xx   # Build for specific target"
echo "  make ci-clean        # Clean for CI"
