#!/bin/bash
# Dependency installer for MinUI build

set -e

echo "📥 Installing MinUI build dependencies..."

# Update package list
sudo apt-get update -qq

# Install build essentials
sudo apt-get install -y -qq \
    build-essential \
    git \
    make \
    cmake \
    pkg-config

# Install SDL2 libraries
sudo apt-get install -y -qq \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    libsdl2-mixer-dev

# Install image tools (for pngquant, mogrify)
sudo apt-get install -y -qq \
    imagemagick \
    pngquant \
    optipng

# Install additional tools
sudo apt-get install -y -qq \
    zip \
    unzip \
    curl \
    wget \
    dos2unix \
    patch

# Install Python and pip
sudo apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-dev

echo "✅ Dependencies installed successfully!"

# Verify installations
echo ""
echo "🔍 Verification:"
echo "----------------"
which gcc && gcc --version | head -1
which make && make --version | head -1
pkg-config --modversion sdl2 || echo "SDL2 not found"
which python3 && python3 --version
