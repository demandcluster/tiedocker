# KoboldCpp Docker Image - Charluv Fork
#
# ⚠️  NOTICE: This is a specialized Charluv fork of KoboldCpp
# This version includes modified horde integration for Charluv services.
# For the official KoboldCpp Docker, see: https://hub.docker.com/r/koboldai/koboldcpp
#
# Supports CPU, CUDA, and Vulkan acceleration

ARG BASE_IMAGE=python:3.11-slim-bullseye
FROM ${BASE_IMAGE} AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy source files
COPY Makefile .
COPY koboldcpp.py .
COPY json_to_gbnf.py .
COPY expose.h expose.cpp .
COPY gpttype_adapter.cpp .
COPY model_adapter.h model_adapter.cpp .
COPY *.sh ./
COPY common/ ./common/
COPY ggml/ ./ggml/
COPY gguf-py/ ./gguf-py/
COPY include/ ./include/
COPY src/ ./src/
COPY otherarch/ ./otherarch/
COPY vendor/ ./vendor/
COPY tools/ ./tools/
COPY lib/ ./lib/

# Build KoboldCpp libraries
# Default to portable CPU build - override with --build-arg for GPU support
ARG BUILD_TYPE=default
RUN if [ "$BUILD_TYPE" = "vulkan" ]; then \
        make LLAMA_VULKAN=1 LLAMA_PORTABLE=1 -j$(nproc); \
    elif [ "$BUILD_TYPE" = "cuda" ]; then \
        make LLAMA_CUBLAS=1 LLAMA_PORTABLE=1 -j$(nproc); \
    elif [ "$BUILD_TYPE" = "hipblas" ]; then \
        make LLAMA_HIPBLAS=1 LLAMA_PORTABLE=1 -j$(nproc); \
    else \
        make LLAMA_PORTABLE=1 -j$(nproc); \
    fi

# Runtime stage
FROM ${BASE_IMAGE}

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy Python files
COPY koboldcpp.py .
COPY json_to_gbnf.py .
COPY requirements.txt .

# Copy built libraries from builder
COPY --from=builder /build/*.so ./
COPY --from=builder /build/lib/ ./lib/

# Copy necessary resources
COPY kcpp_adapters/ ./kcpp_adapters/
COPY embd_res/ ./embd_res/
COPY LICENSE.md .
COPY MIT_LICENSE_GGML_SDCPP_LLAMACPP_ONLY.md .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create directories for models, loras, and data
RUN mkdir -p /models /models/loras /data

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables with defaults
ENV KOBOLDCPP_PORT=5001 \
    KOBOLDCPP_HOST=0.0.0.0 \
    KOBOLDCPP_MODEL="" \
    KOBOLDCPP_MODEL_URL="" \
    KOBOLDCPP_CONTEXT_SIZE=8192 \
    KOBOLDCPP_THREADS=0 \
    KOBOLDCPP_GPU_LAYERS=0 \
    KOBOLDCPP_USE_GPU="" \
    KOBOLDCPP_QUIET="true" \
    KOBOLDCPP_LORA="" \
    KOBOLDCPP_LORA_MULT="1.0" \
    KOBOLDCPP_SDLORA="" \
    KOBOLDCPP_SDLORA_MULT="1.0"

# Expose default port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${KOBOLDCPP_PORT}/api/v1/info || exit 1

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command (can be overridden)
CMD []
