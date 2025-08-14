#!/bin/bash

# exit when any command fails
set -e

# Required to suppress some git errors further down the line
if command -v git &> /dev/null; then
    git config --global --add safe.directory /home/***
fi

# Create required directory structure (if it does not already exist)
if [[ ! -d "$INVENTREE_STATIC_ROOT" ]]; then
    echo "Creating directory $INVENTREE_STATIC_ROOT"
    mkdir -p $INVENTREE_STATIC_ROOT
fi

if [[ ! -d "$INVENTREE_MEDIA_ROOT" ]]; then
    echo "Creating directory $INVENTREE_MEDIA_ROOT"
    mkdir -p $INVENTREE_MEDIA_ROOT
fi

if [[ ! -d "$INVENTREE_BACKUP_DIR" ]]; then
    echo "Creating directory $INVENTREE_BACKUP_DIR"
    mkdir -p $INVENTREE_BACKUP_DIR
fi

echo "INVENTREE_CONFIG_FILE: $INVENTREE_CONFIG_FILE"
echo "INVENTREE_BACKEND_DIR: $INVENTREE_BACKEND_DIR"
echo "INVENTREE_HOME: $INVENTREE_HOME"

# Check if "config.yaml" has been copied into the correct location
if test -f "$INVENTREE_CONFIG_FILE"; then
    echo "Loading config file : $INVENTREE_CONFIG_FILE"
else
    echo "Config file $INVENTREE_CONFIG_FILE does not exist. Checking if config file exists in $INVENTREE_BACKEND_DIR/InvenTree/config_template.yml"
    echo "but first, let's check the home directory: $INVENTREE_HOME"
    ls -la $INVENTREE_HOME
    echo "now the data directory: $INVENTREE_HOME/data"
    ls -la $INVENTREE_HOME/data
    echo "now the backend directory: $INVENTREE_HOME/src/backend"
    ls -la $INVENTREE_HOME/src/backend
    echo "now the config file: $INVENTREE_HOME/src/backend/InvenTree/config.yaml"
    ls -la $INVENTREE_HOME/src/backend/InvenTree/config.yaml

    if test -f "$INVENTREE_BACKEND_DIR/InvenTree/config_template.yml"; then
        echo "Copying config file from $INVENTREE_BACKEND_DIR/InvenTree/config_template.yml to $INVENTREE_CONFIG_FILE"
        cp $INVENTREE_BACKEND_DIR/InvenTree/config_template.yml $INVENTREE_CONFIG_FILE
    else
        echo "No config file found in $INVENTREE_BACKEND_DIR/InvenTree/config_template.yml"
        echo "Creating a default config file in $INVENTREE_CONFIG_FILE"
        cp $INVENTREE_BACKEND_DIR/InvenTree/config_template.yml $INVENTREE_CONFIG_FILE
    fi
fi

# Setup a python virtual environment
# This should be done on the *mounted* filesystem,
# so that the installed modules persist!
if [[ -n "$INVENTREE_PY_ENV" ]]; then

    if test -d "$INVENTREE_PY_ENV"; then
        # venv already exists
        echo "Using Python virtual environment: ${INVENTREE_PY_ENV}"
        source ${INVENTREE_PY_ENV}/bin/activate
    else
        # Setup a virtual environment (within the provided directory)
        echo "Running first time setup for python environment"
        python3 -m venv ${INVENTREE_PY_ENV} --system-site-packages --upgrade-deps

        # Ensure invoke tool is installed locally
        source ${INVENTREE_PY_ENV}/bin/activate
        python3 -m pip install --ignore-installed --upgrade invoke
    fi

fi

# Function to initialize the database with migrations
initialize_database() {
    echo "Initializing database..."
    
    cd ${INVENTREE_BACKEND_DIR}/InvenTree
    
    # Wait for database to be ready by trying to run migrations
    echo "Waiting for database to be ready..."
    while ! python manage.py migrate --run-syncdb 2>/dev/null; do
        echo "Database not ready, waiting..."
        sleep 2
    done
    
    echo "Database is ready!"
    
    # Run the full migration process
    echo "Running database migrations..."
    python manage.py makemigrations
    python manage.py migrate --run-syncdb
    python manage.py remove_stale_contenttypes --include-stale-apps --no-input
    
    # Collect static files
    echo "Collecting static files..."
    python manage.py collectstatic --no-input --verbosity 0
    
    echo "Database initialization complete!"
}

# Initialize database if we're running the server
if [[ "$1" == "runserver" ]] || [[ "$1" == "python" && "$2" == "manage.py" && "$3" == "runserver" ]]; then
    echo "Initializing database..."
    # initialize_database
fi

cd ${INVENTREE_HOME}

# Launch the CMD *after* the ENTRYPOINT completes
exec "$@"
