#!/bin/bash
# A simple script to build and run the Docker container on a standard Linux machine.

echo "Building the Docker image..."
docker build -t curiosity-minerl .

echo ""
echo "Starting the container..."
echo "Once inside, run: xvfb-run python run.py --env_kind minecraft"
echo ""

# -v "$PWD":/workspace mounts the current directory
# --gpus all allows TensorFlow to see the GPU (if you install nvidia-container-toolkit)
docker run -it --rm \
    --gpus all \
    -v "$PWD":/workspace \
    curiosity-minerl bash
