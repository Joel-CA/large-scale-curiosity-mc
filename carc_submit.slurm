#!/bin/bash
#SBATCH --job-name=minerl_curiosity
#SBATCH --account=<YOUR_ACCOUNT_ID>
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1           # Request 1 GPU
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8      # MPI/MineRL requires a good amount of CPU cores
#SBATCH --mem=32G              # Memory
#SBATCH --time=24:00:00        # Max runtime
#SBATCH --output=logs/slurm-%j.out

module purge
module load gcc/11.3.0
module load openmpi/4.1.4
module load apptainer/1.1.8

# HPC Clusters like CARC do not use Docker due to security risks. 
# Instead, they use Apptainer (formerly Singularity) which can run Docker images.

# 1. First, you should build the Apptainer image from your Dockerfile once (uncomment if needed):
# apptainer build curiosity-minerl.sif docker://python:3.7-slim-bullseye (etc...) 
# NOTE: It is usually easier to build the Docker image on your local machine, push it to Docker Hub, 
# and then pull it directly on CARC:
# apptainer pull curiosity-minerl.sif docker://yourusername/curiosity-minerl:latest

echo "Starting MineRL Curiosity Training on CARC..."

# 2. Run the training script inside the Apptainer container
# xvfb-run is required to emulate a display for Minecraft's headless rendering
apptainer exec --nv --bind $PWD:/workspace curiosity-minerl.sif bash -c "cd /workspace && xvfb-run python run.py --env_kind minecraft"

echo "Job finished."
