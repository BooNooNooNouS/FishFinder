#!/bin/bash

# This script will build the frontend with Spanish localization and restart the backend
# When you make frontend changes, run this script to rebuild with Spanish as default

set -e  # Exit on any error

echo "🧹 Cleaning up previous builds..."

# Check available disk space
echo "💾 Checking available disk space..."
AVAILABLE_SPACE=$(df . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 1000000 ]; then
    echo "⚠️ Warning: Low disk space available ($AVAILABLE_SPACE KB)"
    echo "🧽 Running additional cleanup..."
    
    # Clean Docker system
    docker system prune -f
    
    # Clean more aggressively
    rm -rf ~/.cache/yarn/
    rm -rf ~/.npm/
fi

# Navigate to frontend directory
cd src/frontend

# Clean up previous build artifacts
echo "🗑️ Removing old build files..."
rm -rf dist/
rm -rf ../backend/InvenTree/web/static/web/
rm -rf node_modules/.vite/
rm -rf .vite/

# Clean yarn cache if space is still an issue
echo "🧽 Cleaning yarn cache..."
yarn cache clean

# Install dependencies if needed
echo "📦 Installing dependencies..."
yarn install

# Extract translations from source code
echo "🌐 Extracting translations..."
yarn run extract

# Compile translations for production
echo "🔧 Compiling translations..."
yarn run compile

# Build the frontend with Spanish as default locale
echo "🏗️ Building frontend bundle..."
yarn run build

# Go back to root directory
cd ../..

echo "🚀 Restarting Docker containers..."
docker-compose -f docker_containers/dev-docker-compose.yml restart

echo "✅ Frontend built and deployed locally!"