FROM continuumio/miniconda3

ENV DEBIAN_FRONTEND=noninteractive

# Install system-level dependencies.
RUN apt-get update && apt-get install -y \
    default-jre-headless \
    libopenmpi-dev \
    git \
    wget \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    unzip \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Create a conda environment with Python 3.7.
RUN conda create -n minerl python=3.7 -y

# MineRL's legacy ForgeGradle build requires Java 8 Pack200 APIs.
RUN conda install -n minerl -c conda-forge openjdk=8 -y

# Step 1: Install TensorFlow first (needed by Baselines setup.py)
RUN conda run -n minerl pip install --no-cache-dir tensorflow==1.15.5

# Step 2: Install remaining pre-compiled deps
RUN conda run -n minerl pip install --no-cache-dir \
    mpi4py \
    pillow \
    pytest \
    mock \
    gym==0.19.0

# Step 3: Install Baselines
RUN conda run -n minerl pip install --no-cache-dir \
    git+https://github.com/openai/baselines.git

# -------------------------------------------------------------------------
# Patched MineRL install
#
# minerl==0.4.4 builds the Minecraft/Malmo Java mod from source using Gradle.
# The original MixinGradle commit is no longer published by JitPack.
#
# Fix: download the source and use SpongePowered's Maven repository for the maintained plugin artifact.
# -------------------------------------------------------------------------
RUN conda run -n minerl pip download --no-deps minerl==0.4.4 -d /tmp/minerl_dl

RUN cd /tmp && tar -xzf minerl_dl/minerl-0.4.4.tar.gz

# Build the exact ForgeGradle 2.x-compatible MixinGradle commit locally; its old JitPack publication is unavailable.
RUN git clone --depth 1 https://github.com/SpongePowered/MixinGradle.git /tmp/MixinGradle \
    && cd /tmp/MixinGradle \
    && git fetch --depth 1 origin dcfaf61de110fbce80e0e77a080d42baf7a4ee4b \
    && git checkout dcfaf61de110fbce80e0e77a080d42baf7a4ee4b \
    && wget -q https://services.gradle.org/distributions/gradle-4.10.2-bin.zip -O /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /opt \
    && /opt/gradle-4.10.2/bin/gradle install --no-daemon \
    && rm -rf /tmp/MixinGradle /tmp/gradle.zip

# Use the locally published plugin and Sponge's Maven repository for its Mixin dependency.
RUN find /tmp/minerl-0.4.4 -name "*.gradle" | \
    xargs perl -pi -e "s|com.github.SpongePowered:MixinGradle:dcfaf61|org.spongepowered:mixingradle:0.6-SNAPSHOT|g; s|repositories \{|repositories {\n        mavenLocal()|g; s|jcenter\(\)|maven { url 'https://repo.spongepowered.org/maven/' }\n        jcenter()|g"

# Now install from the patched source
RUN conda run -n minerl pip install --no-cache-dir /tmp/minerl-0.4.4/

ENV JAVA_HOME=/opt/conda/envs/minerl
ENV PATH=/opt/conda/envs/minerl/bin:$PATH

# Headless rendering environment variables for MineRL's Minecraft server
ENV DISPLAY=:99
ENV MINERL_DATA_ROOT=/workspace/data

WORKDIR /workspace
