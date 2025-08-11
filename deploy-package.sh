#!/bin/bash

# Deploy script for FishFinder project
# This script builds the frontend locally and creates a complete deployment package

set -e  # Exit on any error

PROJECT_NAME="fishfinder"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
SERVER_USER="ubuntu"
SERVER_HOST="35.93.33.231"
SERVER_PATH="/opt/inventree/src"
SERVER_PEM_FILE="~/.ssh/anvil.pem"
SERVER_TEMP_DIR="/tmp"

BUILD_FRONTEND=${BUILD_FRONTEND:-true}


# Function to build the frontend
build_frontend() {

    # if SKIP_FRONTEND_BUILD is set, skip the frontend build
    if [ "$BUILD_FRONTEND" == "false" ]; then
        echo "🔨 Skipping frontend build..."
        return
    fi

    echo "🔨 Building frontend..."
    
    # Check if Node.js and yarn are available locally
    if ! command -v node &> /dev/null; then
        echo "Error: Node.js is not installed locally. Please install Node.js 20+ to build the frontend."
        exit 1
    fi

    if ! command -v yarn &> /dev/null; then
        echo "Error: Yarn is not installed locally. Please install yarn to build the frontend."
        exit 1
    fi

    # Navigate to frontend directory and build
    cd src/frontend

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        echo "Installing frontend dependencies..."
        yarn install
    fi

    # Build the frontend
    echo "Building frontend bundle..."
    yarn install
    yarn run extract # extract the translations
    yarn run compile # compile the translations
    yarn run build
    
    # Copy compiled locales to the build output.  Vite does not do this automatically.
    echo "Copying locales to build output..."
    if [ -d "src/locales" ]; then
        cp -r src/locales ../../src/backend/InvenTree/web/static/web/
        echo "Locales copied successfully"
    else
        echo "Warning: src/locales directory not found"
    fi
    
    # Go back to project root
    cd ../..

    echo "Frontend built successfully!"
}

cleanup_static_files() {
    echo "Cleaning up static files..."
    source venv/bin/activate
    cd src/backend/InvenTree
    
    # Backup the built frontend files before collectstatic
    echo "Backing up built frontend files..."
    if [ -d "web/static/web" ]; then
        cp -r web/static/web /tmp/frontend_backup
    fi
    
    # Run collectstatic to organize Django static files
    python manage.py collectstatic --noinput --clear
    
    # Restore the built frontend files
    echo "Restoring built frontend files..."
    if [ -d "/tmp/frontend_backup" ]; then
        cp -r /tmp/frontend_backup/* web/static/web/
        rm -rf /tmp/frontend_backup
    fi
    
    deactivate
    echo "Static files cleaned up"
    cd ../../..
}


tar_package() {
    echo "📦 Creating deployment package... $ARCHIVE_NAME"
    
    # Clean macOS extended attributes to prevent tar warnings
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🧹 Cleaning macOS extended attributes..."
        find src/backend -type f -exec xattr -c {} \; 2>/dev/null || true
    fi
    
    # Create tar archive with only the essential files for deployment
    # Includes: src/backend (with built frontend in static/web)
    # Excludes: src/backend/config (contains local configuration)
    # Note: We don't include the root static/ directory as it would overwrite the built frontend
    tar -czf "$ARCHIVE_NAME" \
        --exclude='src/backend/config' \
        -C . src/backend

    echo "Archive created: $ARCHIVE_NAME"
    echo "Size: $(du -h "$ARCHIVE_NAME" | cut -f1)"
}

publish() {
    echo "Publishing to server..."
    scp -i ${SERVER_PEM_FILE} "$ARCHIVE_NAME" ${SERVER_USER}@${SERVER_HOST}:${SERVER_TEMP_DIR}
    # ssh ${SERVER_USER}@${SERVER_HOST} "cd /opt/inventree/src && tar -xzf /tmp/$ARCHIVE_NAME -C /opt/inventree && sudo chown -R inventree:inventree /opt/inventree"
    # ssh ${SERVER_USER}@${SERVER_HOST} "cd /opt/inventree/src && python3 -m venv env && source env/bin/activate && pip install --require-hashes -U -r backend/requirements.txt"
    # ssh ${SERVER_USER}@${SERVER_HOST} "cd /opt/inventree/src && source env/bin/activate && invoke update"
    # ssh ubuntu@35.93.33.231 "rm /tmp/$ARCHIVE_NAME"
    echo "Published to server!"
}


deploy_nginx() {
    echo "Deploying nginx configuration..."
    scp -i ${SERVER_PEM_FILE} src/backend/InvenTree/nginx.conf ${SERVER_USER}@${SERVER_HOST}:/tmp/nginx.conf
    # The nginx.conf file will be renamed to /etc/nginx/sites-available/inventree.  
    # Then a symlink will be created to /etc/nginx/sites-enabled/inventree before testig the configuration.
    echo "You should now ssh into the server and run the following commands:"
    echo "sudo mv /tmp/nginx.conf /etc/nginx/sites-available/inventree"
    echo "sudo ln -s /etc/nginx/sites-available/inventree /etc/nginx/sites-enabled/"
    echo "sudo rm /etc/nginx/sites-enabled/default"
    echo "sudo nginx -t"
    echo "sudo systemctl reload nginx"
    echo "sudo systemctl restart nginx"
    echo "sudo systemctl status nginx"
    echo "sudo systemctl restart nginx"


}

echo "Creating deployment package..."

# Build the frontend
build_frontend
cleanup_static_files
tar_package
publish


# Optionally copy to server (uncomment and modify as needed)
# SERVER_USER="ubuntu"
# SERVER_HOST="your-server-ip"
# SERVER_PATH="/path/to/destination/"
# 
# echo "Copying to server..."
# scp "$ARCHIVE_NAME" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH"
# 
# echo "Extracting on server..."
# ssh "$SERVER_USER@$SERVER_HOST" "cd $SERVER_PATH && tar -xzf $ARCHIVE_NAME"

echo "Done!"
# echo ""
# echo "=== DEPLOYMENT COMMANDS ==="
# echo "1. Copy to server:"
# echo "   scp $ARCHIVE_NAME ubuntu@35.93.33.231:/tmp/"
# echo ""
# echo "2. Extract on server (recommended):"
# echo "   ssh ubuntu@35.93.33.231 'sudo mkdir -p /opt/inventree && sudo tar -xzf /tmp/$ARCHIVE_NAME -C /opt/inventree && sudo chown -R inventree:inventree /opt/inventree'"
# echo ""
# echo "3. Set up the environment on server:"
# echo "   ssh ubuntu@35.93.33.231 'cd /opt/inventree/src && python3 -m venv env && source env/bin/activate && pip install --require-hashes -U -r backend/requirements.txt'"
# echo ""
# echo "4. Initialize database:"
# echo "   ssh ubuntu@35.93.33.231 'cd /opt/inventree/src && source env/bin/activate && invoke update'"
# echo ""
# echo "5. Cleanup archive:"
# echo "   ssh ubuntu@35.93.33.231 'rm /tmp/$ARCHIVE_NAME'"
# echo ""
# echo "=== NOTES ==="
# echo "- Frontend is now pre-built and included in the package"
# echo "- No need to build frontend on the server"
# echo "- Backend dependencies will need to be installed on the server"
# echo "- Database will need to be initialized on the server"