#!/bin/bash

# This script uses the ubuntu-python-3-12 image to install the requirements and generate
# a file with hashes.


CONTAINERS_DIR=$(realpath $(dirname "$0"))
ROOT_DIR=$(realpath $(dirname "$CONTAINERS_DIR"))


cd $ROOT_DIR
echo "we are at $ROOT_DIR"

docker build -f $CONTAINERS_DIR/Dockerfile.ubuntu-py-3-12 \
  -t ubuntu-python-3-12 . 2>/dev/null || echo "Image already exists"

# Generate requirements with hashes in Ubuntu environment.
# -b makes it stick to the source requirements.txt file.
docker run -it --rm \
  -v $(pwd):/app \
  -w /app \
  ubuntu-python-3.12 \
  bash -c "
    # First, try to clean up any distutils-installed packages that might cause issues
    pip uninstall pyyaml -y || true
    pip uninstall setuptools -y || true
    
    # Use uv to compile requirements for both the backend and the docker_containers
    uv pip compile \
      docker_containers/requirements.in \
      src/backend/requirements.in \
      --python-version=3.12 \
      --no-strip-extras \
      --generate-hashes \
      --system \
      -o docker_containers/requirements.txt
  "

echo "Requirements with hashes generated for Ubuntu environment!" 