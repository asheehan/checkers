#!/bin/bash
# Checkers setup script

set -e

echo "🔧 Setting up Checkers..."

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get

# Setup database
echo "💾 Setting up database..."
mix ecto.setup

# Build assets
echo "🎨 Building assets..."
mix assets.build

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 Start the server with:"
echo "   mix phx.server"
echo ""
echo "Then visit http://localhost:4000"
