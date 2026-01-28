#!/bin/bash
set -e

# Checkers Deployment Script
# Called by GitHub Actions on push to main

APP_DIR="/root/clawd/projects/checkers"
RELEASE_DIR="$APP_DIR/_build/prod/rel/checkers"

echo "🚀 Starting deployment..."

# Source asdf
export PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"

cd "$APP_DIR"

# Pull latest code
echo "📥 Pulling latest code..."
git fetch origin main
git reset --hard origin/main

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get --only prod

# Compile
echo "🔨 Compiling..."
MIX_ENV=prod mix compile

# Build assets
echo "🎨 Building assets..."
MIX_ENV=prod mix assets.deploy

# Build release
echo "📦 Building release..."
MIX_ENV=prod mix release --overwrite

# Stop existing service
echo "🛑 Stopping existing service..."
sudo systemctl stop checkers || true

# Start new release
echo "🚀 Starting new release..."
sudo systemctl start checkers

echo "✅ Deployment complete!"

# Health check
sleep 3
if curl -s http://localhost:4000 > /dev/null; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    exit 1
fi
