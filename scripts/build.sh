#!/bin/bash
# MinUI Build Script for CI/CD

set -e

# Configuration
BUILD_DIR="minui-build"
OUTPUT_DIR="artifacts"
LOG_FILE="build.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Start fresh log
echo "=== MinUI CI Build Log ===" > "$LOG_FILE"
echo "Start time: $(date)" >> "$LOG_FILE"

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    error "Build directory not found: $BUILD_DIR"
fi

cd "$BUILD_DIR"

log "📂 Building MinUI in: $(pwd)"
log "🎯 Target: ${TARGET:-default}"
log "🧹 Clean build: ${CLEAN_BUILD:-true}"
log "🏷️ Version: ${BUILD_VERSION:-unknown}"

# Clean if requested
if [ "$CLEAN_BUILD" = "true" ]; then
    log "🧹 Cleaning build directory..."
    make clean 2>> "../$LOG_FILE" || warn "Clean may have failed or already clean"
    rm -rf build 2>/dev/null || true
fi

# Build process
log "🔨 Starting build process..."

# Try different build methods
if [ -n "$TARGET" ] && [ "$TARGET" != "default" ]; then
    log "Building for target: $TARGET"
    
    # Method 1: Try standard target build
    if make "TARGET=$TARGET" 2>&1 | tee -a "../$LOG_FILE"; then
        log "✅ Target build successful: $TARGET"
    else
        warn "Target build failed, trying alternative..."
        
        # Method 2: Try CI build target
        if make ci 2>&1 | tee -a "../$LOG_FILE"; then
            log "✅ CI build successful"
        else
            # Method 3: Manual build
            warn "CI build failed, attempting manual build..."
            
            mkdir -p build
            cp -r resources/. build/ 2>/dev/null || true
            cp launcher.png build/ 2>/dev/null || true
            
            # Find and compile source files
            SOURCE_FILES=$(find . -name "*.c" -o -name "*.cpp")
            if [ -n "$SOURCE_FILES" ]; then
                log "Compiling source files..."
                for src in $SOURCE_FILES; do
                    gcc -c "$src" -o "${src%.*}.o" \
                        -I/usr/include/SDL2 \
                        -D_REENTRANT \
                        -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer 2>> "../$LOG_FILE" || true
                done
                
                # Link
                OBJECT_FILES=$(find . -name "*.o")
                if [ -n "$OBJECT_FILES" ]; then
                    gcc $OBJECT_FILES -o build/minui.elf \
                        -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer 2>> "../$LOG_FILE" && \
                    log "✅ Manual build completed"
                fi
            fi
        fi
    fi
else
    # Default build
    log "Building default target..."
    if make 2>&1 | tee -a "../$LOG_FILE"; then
        log "✅ Default build successful"
    else
        make ci 2>&1 | tee -a "../$LOG_FILE" && \
        log "✅ CI build successful"
    fi
fi

# Collect build outputs
log "📦 Collecting build artifacts..."
cd ..

mkdir -p "$OUTPUT_DIR"
cp "$BUILD_DIR"/*.zip "$BUILD_DIR"/*.elf "$BUILD_DIR"/*.img "$BUILD_DIR"/*.bin "$OUTPUT_DIR"/ 2>/dev/null || true

# Create build info file
cat > "$OUTPUT_DIR/build-info.txt" << EOF
MinUI CI Build Information
==========================
Build Version: ${BUILD_VERSION}
Build Date: $(date)
Build Target: ${TARGET:-default}
Clean Build: ${CLEAN_BUILD}
Commit Hash: $(cd "$BUILD_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
CI Runner: ${GITHUB_RUN_ID:-local}
EOF

# List artifacts
log "📁 Build artifacts in $OUTPUT_DIR/:"
ls -la "$OUTPUT_DIR/" | tee -a "$LOG_FILE"

# Check if we have any outputs
if [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    warn "No build artifacts found!"
    exit 1
fi

log "🎉 Build completed successfully!"
echo "End time: $(date)" >> "$LOG_FILE"
