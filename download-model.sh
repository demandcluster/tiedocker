#!/bin/bash
# KoboldCpp Model Download Helper Script
# Downloads recommended GGUF models for use with KoboldCpp

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default download directory
DOWNLOAD_DIR="${1:-./models}"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

echo -e "${GREEN}KoboldCpp Model Download Helper${NC}"
echo "================================"
echo ""
echo "Download directory: $DOWNLOAD_DIR"
echo ""

# Function to download model
download_model() {
    local name="$1"
    local url="$2"
    local filename="$3"
    local size="$4"

    echo -e "${YELLOW}Model: $name${NC}"
    echo "Size: $size"
    echo "Downloading to: $DOWNLOAD_DIR/$filename"
    echo ""

    if [ -f "$DOWNLOAD_DIR/$filename" ]; then
        echo -e "${GREEN}File already exists, skipping download${NC}"
        echo ""
        return
    fi

    curl -L --progress-bar -C - -o "$DOWNLOAD_DIR/$filename" "$url" || {
        echo -e "${RED}Error: Failed to download $name${NC}"
        return 1
    }

    echo -e "${GREEN}✓ Download complete: $filename${NC}"
    echo ""
}

# Display menu
echo "Select a model to download:"
echo ""
echo "Small Models (8B parameters, ~4-5GB):"
echo "  1) L3-8B-Stheno-v3.2 Q4_K_S       - Recommended for beginners"
echo ""
echo "Medium Models (13B parameters, ~7-8GB):"
echo "  2) Tiefighter 13B Q4_K_S          - Versatile, good for roleplay"
echo ""
echo "Large Models (27B+ parameters, 15-20GB):"
echo "  3) Gemma-3-27B Abliterated Q4_K_M - Most powerful, requires good hardware"
echo ""
echo "Multimodal Models:"
echo "  4) Llama-3.2-11B-Vision Q4_K_M    - Vision + text understanding"
echo ""
echo "Small/Fast Models (1-3B parameters):"
echo "  5) Kobble-Tiny-1.1B Q4_K          - Very fast, limited capability"
echo ""
echo "  6) Custom URL                      - Enter your own model URL"
echo "  0) Exit"
echo ""
read -p "Enter your choice (0-6): " choice

case $choice in
    1)
        download_model \
            "L3-8B-Stheno-v3.2 Q4_K_S" \
            "https://huggingface.co/bartowski/L3-8B-Stheno-v3.2-GGUF/resolve/main/L3-8B-Stheno-v3.2-Q4_K_S.gguf" \
            "L3-8B-Stheno-v3.2-Q4_K_S.gguf" \
            "~4.9GB"
        ;;
    2)
        download_model \
            "Tiefighter 13B Q4_K_S" \
            "https://huggingface.co/KoboldAI/LLaMA2-13B-Tiefighter-GGUF/resolve/main/LLaMA2-13B-Tiefighter.Q4_K_S.gguf" \
            "LLaMA2-13B-Tiefighter.Q4_K_S.gguf" \
            "~7.4GB"
        ;;
    3)
        download_model \
            "Gemma-3-27B Abliterated Q4_K_M" \
            "https://huggingface.co/mlabonne/gemma-3-27b-it-abliterated-GGUF/resolve/main/gemma-3-27b-it-abliterated.q4_k_m.gguf" \
            "gemma-3-27b-it-abliterated.q4_k_m.gguf" \
            "~17GB"
        ;;
    4)
        download_model \
            "Llama-3.2-11B-Vision Q4_K_M" \
            "https://huggingface.co/mradermacher/Llama-3.2-11B-Vision-Instruct-GGUF/resolve/main/Llama-3.2-11B-Vision-Instruct.Q4_K_M.gguf" \
            "Llama-3.2-11B-Vision-Instruct.Q4_K_M.gguf" \
            "~7.2GB"
        ;;
    5)
        download_model \
            "Kobble-Tiny-1.1B Q4_K" \
            "https://huggingface.co/concedo/KobbleTinyV2-1.1B-GGUF/resolve/main/KobbleTiny-Q4_K.gguf" \
            "KobbleTiny-Q4_K.gguf" \
            "~0.7GB"
        ;;
    6)
        read -p "Enter model URL: " custom_url
        read -p "Enter filename to save as: " custom_filename
        download_model \
            "Custom Model" \
            "$custom_url" \
            "$custom_filename" \
            "Unknown"
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Download complete!${NC}"
echo ""
echo "To use this model with Docker:"
echo "  docker-compose --profile cpu up -d"
echo ""
echo "Or specify the model directly:"
echo "  docker run -v $DOWNLOAD_DIR:/models -p 5001:5001 koboldcpp"
echo ""
echo "Access at: http://localhost:5001"
