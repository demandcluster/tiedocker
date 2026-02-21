# KoboldCpp Docker Image - Charluv Fork
#
# ⚠️  NOTICE: This is a specialized Charluv fork of KoboldCpp
# This version includes modified horde integration for Charluv services.
# For the official KoboldCpp Docker, see: https://hub.docker.com/r/koboldai/koboldcpp
#
# Requires koboldcpp_cublas.so in the repo directory:
#   make LLAMA_CUBLAS=1 LLAMA_PORTABLE=1

ARG CUDA_VERSION=12.6.3
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu24.04

# Install Python and runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

WORKDIR /app

COPY koboldcpp.py .
COPY json_to_gbnf.py .
COPY requirements.txt .
COPY koboldcpp_cublas.so .
COPY kcpp_adapters/ ./kcpp_adapters/
COPY embd_res/ ./embd_res/
COPY LICENSE.md .
COPY MIT_LICENSE_GGML_SDCPP_LLAMACPP_ONLY.md .

RUN pip install --no-cache-dir --break-system-packages -r requirements.txt

RUN mkdir -p /models /models/loras /data

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV KOBOLDCPP_PORT=5001 \
    KOBOLDCPP_HOST=0.0.0.0 \
    KOBOLDCPP_MODEL="" \
    KOBOLDCPP_MODEL_URL="" \
    KOBOLDCPP_CONTEXT_SIZE=8192 \
    KOBOLDCPP_THREADS=0 \
    KOBOLDCPP_USE_GPU=cuda \
    KOBOLDCPP_GPU_LAYERS=-1 \
    KOBOLDCPP_QUIET="true" \
    KOBOLDCPP_LORA="" \
    KOBOLDCPP_LORA_URL="" \
    KOBOLDCPP_LORA_URL_FILENAME="" \
    KOBOLDCPP_LORA_MULT="1.0" \
    KOBOLDCPP_SDLORA="" \
    KOBOLDCPP_SDLORA_URL="" \
    KOBOLDCPP_SDLORA_URL_FILENAME="" \
    KOBOLDCPP_SDLORA_MULT="1.0" \
    CHARLUV_HORDE_KEY="" \
    CHARLUV_HORDE_WORKER_NAME="" \
    CHARLUV_HORDE_MODEL_NAME="" \
    CHARLUV_HORDE_MAX_CTX=0 \
    CHARLUV_HORDE_GEN_LEN=0

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${KOBOLDCPP_PORT}/api/v1/info || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
