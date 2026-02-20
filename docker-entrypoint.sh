#!/bin/bash
set -e

# KoboldCpp Docker Entrypoint Script - Charluv Fork
# Handles model downloading and startup configuration
#
# ⚠️  NOTICE: This is a Charluv-specialized fork with modified horde integration

echo "========================================="
echo "KoboldCpp Docker - Charluv Fork"
echo "========================================="
echo "Version: $(grep -oP "KcppVersion = \"\K[^\"]*" koboldcpp.py || echo 'unknown')"
echo "Specialization: Charluv Horde Integration"
echo ""

# Function to download model from URL
download_model() {
    local url="$1"
    local filename="$2"

    echo "Downloading model from: $url"
    echo "Destination: $filename"

    # Use curl with progress bar and resume support
    curl -L -C - -o "$filename" "$url" || {
        echo "Error: Failed to download model from $url"
        exit 1
    }

    echo "Model downloaded successfully: $filename"
}

# Handle model configuration
MODEL_PATH=""

if [ -n "$KOBOLDCPP_MODEL_URL" ]; then
    # Download model from URL if specified
    MODEL_FILENAME="${KOBOLDCPP_MODEL_URL_FILENAME:-/models/model.gguf}"

    if [ ! -f "$MODEL_FILENAME" ]; then
        echo "Model not found at $MODEL_FILENAME, downloading..."
        mkdir -p "$(dirname "$MODEL_FILENAME")"
        download_model "$KOBOLDCPP_MODEL_URL" "$MODEL_FILENAME"
    else
        echo "Model already exists at $MODEL_FILENAME, skipping download"
    fi

    MODEL_PATH="$MODEL_FILENAME"
elif [ -n "$KOBOLDCPP_MODEL" ]; then
    # Use specified model path
    if [ ! -f "$KOBOLDCPP_MODEL" ]; then
        echo "Error: Model file not found at $KOBOLDCPP_MODEL"
        echo "Please mount a model file or set KOBOLDCPP_MODEL_URL to download one"
        exit 1
    fi
    MODEL_PATH="$KOBOLDCPP_MODEL"
else
    # Look for default model in /models directory
    if ls /models/*.gguf 1> /dev/null 2>&1; then
        MODEL_PATH=$(ls /models/*.gguf | head -n 1)
        echo "Found model: $MODEL_PATH"
    else
        echo "Error: No model specified and no .gguf files found in /models"
        echo ""
        echo "Please either:"
        echo "  1. Mount a model: docker run -v /path/to/model.gguf:/models/model.gguf ..."
        echo "  2. Set KOBOLDCPP_MODEL_URL to download a model on startup"
        echo "  3. Set KOBOLDCPP_MODEL environment variable"
        echo ""
        echo "Example models:"
        echo "  - https://huggingface.co/bartowski/L3-8B-Stheno-v3.2-GGUF/resolve/main/L3-8B-Stheno-v3.2-Q4_K_S.gguf"
        echo "  - https://huggingface.co/KoboldAI/LLaMA2-13B-Tiefighter-GGUF/resolve/main/LLaMA2-13B-Tiefighter.Q4_K_S.gguf"
        exit 1
    fi
fi

# Build command arguments
ARGS=()
ARGS+=("--model" "$MODEL_PATH")
ARGS+=("--host" "$KOBOLDCPP_HOST")
ARGS+=("--port" "$KOBOLDCPP_PORT")
ARGS+=("--skiplauncher")

# Context size
if [ "$KOBOLDCPP_CONTEXT_SIZE" -gt 0 ]; then
    ARGS+=("--contextsize" "$KOBOLDCPP_CONTEXT_SIZE")
fi

# Thread count (0 = auto-detect)
if [ "$KOBOLDCPP_THREADS" -gt 0 ]; then
    ARGS+=("--threads" "$KOBOLDCPP_THREADS")
fi

# GPU configuration
if [ -n "$KOBOLDCPP_USE_GPU" ]; then
    case "$KOBOLDCPP_USE_GPU" in
        cuda|CUDA)
            ARGS+=("--usecuda")
            echo "GPU Mode: CUDA"
            ;;
        vulkan|VULKAN)
            ARGS+=("--usevulkan")
            echo "GPU Mode: Vulkan"
            ;;
        hip|HIP|rocm|ROCM)
            ARGS+=("--usevulkan")  # ROCm typically uses Vulkan
            echo "GPU Mode: ROCm/Vulkan"
            ;;
        *)
            echo "Warning: Unknown GPU type '$KOBOLDCPP_USE_GPU', using CPU"
            ;;
    esac

    # GPU layers
    if [ "$KOBOLDCPP_GPU_LAYERS" -ne 0 ]; then
        ARGS+=("--gpulayers" "$KOBOLDCPP_GPU_LAYERS")
        echo "GPU Layers: $KOBOLDCPP_GPU_LAYERS"
    fi
fi

# Quiet mode
if [ "$KOBOLDCPP_QUIET" = "true" ] || [ "$KOBOLDCPP_QUIET" = "1" ]; then
    ARGS+=("--quiet")
fi

# LoRA configuration
if [ -n "$KOBOLDCPP_LORA" ]; then
    # Split pipe-separated LoRA files and add each one
    IFS='|' read -ra LORA_FILES <<< "$KOBOLDCPP_LORA"
    for lora_file in "${LORA_FILES[@]}"; do
        lora_file=$(echo "$lora_file" | xargs) # trim whitespace
        if [ -f "$lora_file" ]; then
            ARGS+=("--lora" "$lora_file")
            echo "Text LoRA: $lora_file"
        else
            echo "Warning: LoRA file not found: $lora_file"
        fi
    done

    # LoRA multiplier
    if [ -n "$KOBOLDCPP_LORA_MULT" ] && [ "$KOBOLDCPP_LORA_MULT" != "1.0" ]; then
        ARGS+=("--loramult" "$KOBOLDCPP_LORA_MULT")
        echo "Text LoRA Multiplier: $KOBOLDCPP_LORA_MULT"
    fi
fi

# SD LoRA configuration
if [ -n "$KOBOLDCPP_SDLORA" ]; then
    # Split pipe-separated SD LoRA files and add each one
    IFS='|' read -ra SDLORA_FILES <<< "$KOBOLDCPP_SDLORA"
    for sdlora_file in "${SDLORA_FILES[@]}"; do
        sdlora_file=$(echo "$sdlora_file" | xargs) # trim whitespace
        if [ -f "$sdlora_file" ]; then
            ARGS+=("--sdlora" "$sdlora_file")
            echo "SD LoRA: $sdlora_file"
        else
            echo "Warning: SD LoRA file not found: $sdlora_file"
        fi
    done

    # SD LoRA multiplier
    if [ -n "$KOBOLDCPP_SDLORA_MULT" ] && [ "$KOBOLDCPP_SDLORA_MULT" != "1.0" ]; then
        ARGS+=("--sdloramult" "$KOBOLDCPP_SDLORA_MULT")
        echo "SD LoRA Multiplier: $KOBOLDCPP_SDLORA_MULT"
    fi
fi

# Add any additional arguments passed to docker run
ARGS+=("$@")

# Display configuration
echo ""
echo "==================================="
echo "KoboldCpp Configuration:"
echo "==================================="
echo "Model: $MODEL_PATH"
echo "Host: $KOBOLDCPP_HOST"
echo "Port: $KOBOLDCPP_PORT"
echo "Context Size: $KOBOLDCPP_CONTEXT_SIZE"
echo "Threads: ${KOBOLDCPP_THREADS:-auto}"
echo "GPU: ${KOBOLDCPP_USE_GPU:-CPU only}"
[ "$KOBOLDCPP_GPU_LAYERS" -ne 0 ] && echo "GPU Layers: $KOBOLDCPP_GPU_LAYERS"
[ -n "$KOBOLDCPP_LORA" ] && echo "Text LoRA: Enabled (multiplier: ${KOBOLDCPP_LORA_MULT:-1.0})"
[ -n "$KOBOLDCPP_SDLORA" ] && echo "SD LoRA: Enabled (multiplier: ${KOBOLDCPP_SDLORA_MULT:-1.0})"
echo "==================================="
echo ""

# Start KoboldCpp
echo "Starting KoboldCpp..."
exec python koboldcpp.py "${ARGS[@]}"
