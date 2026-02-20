# KoboldCpp Docker Guide - Charluv Fork

> **⚠️ IMPORTANT NOTICE**
>
> This is a **Charluv-specialized fork** of KoboldCpp with modified horde integration.
>
> - **For Charluv deployments**: Continue reading this guide
> - **For official KoboldCpp**: Use https://hub.docker.com/r/koboldai/koboldcpp
> - **For Charluv specifics**: See [DOCKER_CHARLUV.md](DOCKER_CHARLUV.md)
>
> This fork includes custom horde implementation for Charluv services and is not compatible with the standard AI Horde.

---

This guide covers running KoboldCpp in Docker containers with support for CPU and GPU acceleration.

## Quick Start

### 1. Download a Model

First-time setup requires a GGUF model file. Use the included download script:

```bash
./download-model.sh
```

Or manually download a model and place it in the `./models` directory:
- [L3-8B-Stheno-v3.2 Q4_K_S](https://huggingface.co/bartowski/L3-8B-Stheno-v3.2-GGUF/resolve/main/L3-8B-Stheno-v3.2-Q4_K_S.gguf) (~4.9GB, recommended for beginners)
- [Tiefighter 13B Q4_K_S](https://huggingface.co/KoboldAI/LLaMA2-13B-Tiefighter-GGUF/resolve/main/LLaMA2-13B-Tiefighter.Q4_K_S.gguf) (~7.4GB, versatile)

### 2. Start the Container

**CPU-only deployment:**
```bash
docker-compose --profile cpu up -d
```

**With NVIDIA GPU:**
```bash
docker-compose --profile cuda up -d
```

**With any GPU (Vulkan):**
```bash
docker-compose --profile vulkan up -d
```

**With AMD GPU (ROCm):**
```bash
docker-compose --profile rocm up -d
```

### 3. Access the Interface

- **Web UI**: http://localhost:5001
- **API Documentation**: http://localhost:5001/api
- **OpenAI-compatible API**: http://localhost:5001/v1

## Configuration

### Using Environment Variables

Edit `docker-compose.yml` or set environment variables:

```yaml
environment:
  # Model configuration
  - KOBOLDCPP_MODEL=/models/your-model.gguf

  # Or download on first run
  - KOBOLDCPP_MODEL_URL=https://example.com/model.gguf
  - KOBOLDCPP_MODEL_URL_FILENAME=/models/model.gguf

  # Server settings
  - KOBOLDCPP_PORT=5001
  - KOBOLDCPP_CONTEXT_SIZE=8192
  - KOBOLDCPP_THREADS=0  # 0 = auto-detect

  # GPU settings (if using GPU profile)
  - KOBOLDCPP_USE_GPU=cuda  # or vulkan, rocm
  - KOBOLDCPP_GPU_LAYERS=-1  # -1 = auto, 0 = CPU only
```

### Environment Variable Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `KOBOLDCPP_MODEL` | - | Path to GGUF model file |
| `KOBOLDCPP_MODEL_URL` | - | URL to download model from |
| `KOBOLDCPP_MODEL_URL_FILENAME` | `/models/model.gguf` | Where to save downloaded model |
| `KOBOLDCPP_HOST` | `0.0.0.0` | Server bind address |
| `KOBOLDCPP_PORT` | `5001` | Server port |
| `KOBOLDCPP_CONTEXT_SIZE` | `8192` | Model context window size |
| `KOBOLDCPP_THREADS` | `0` | CPU threads (0 = auto) |
| `KOBOLDCPP_USE_GPU` | - | GPU type: `cuda`, `vulkan`, `rocm` |
| `KOBOLDCPP_GPU_LAYERS` | `0` | GPU layers (-1 = auto, 0 = CPU) |
| `KOBOLDCPP_QUIET` | `true` | Reduce logging output |
| `CUDA_VISIBLE_DEVICES` | - | Select NVIDIA GPU(s) by ID |
| `HIP_VISIBLE_DEVICES` | - | Select AMD GPU(s) by ID |
| `KOBOLDCPP_LORA` | - | Path to text LoRA file(s), pipe-separated for multiple |
| `KOBOLDCPP_LORA_MULT` | `1.0` | Text LoRA strength multiplier |
| `KOBOLDCPP_SDLORA` | - | Path to SD LoRA file(s), pipe-separated for multiple |
| `KOBOLDCPP_SDLORA_MULT` | `1.0` | SD LoRA strength multiplier |

## Advanced Usage

### Custom Docker Build

Build specific GPU backends:

```bash
# CPU-only
docker build -t koboldcpp:cpu .

# Vulkan (universal GPU)
docker build --build-arg BUILD_TYPE=vulkan -t koboldcpp:vulkan .

# CUDA (NVIDIA)
docker build \
  --build-arg BUILD_TYPE=cuda \
  --build-arg BASE_IMAGE=nvidia/cuda:12.1.1-runtime-ubuntu22.04 \
  -t koboldcpp:cuda .

# ROCm (AMD)
docker build \
  --build-arg BUILD_TYPE=hipblas \
  --build-arg BASE_IMAGE=rocm/dev-ubuntu-22.04:7.1 \
  -t koboldcpp:rocm .
```

### Manual Docker Run

Without docker-compose:

```bash
# CPU-only
docker run -d \
  --name koboldcpp \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  koboldcpp:cpu

# NVIDIA GPU with CUDA
docker run -d \
  --name koboldcpp \
  --gpus all \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_USE_GPU=cuda \
  -e KOBOLDCPP_GPU_LAYERS=-1 \
  -e CUDA_VISIBLE_DEVICES=0 \
  koboldcpp:cuda

# Vulkan (any GPU)
docker run -d \
  --name koboldcpp \
  --device /dev/dri \
  -v /usr/share/vulkan/icd.d:/usr/share/vulkan/icd.d:ro \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_USE_GPU=vulkan \
  -e KOBOLDCPP_GPU_LAYERS=-1 \
  koboldcpp:vulkan
```

### Using LoRA Adapters

KoboldCpp supports LoRA (Low-Rank Adaptation) files to fine-tune model behavior:

**Text LoRA (for LLM models):**
```bash
# Single LoRA
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_LORA=/models/loras/my-lora.gguf \
  -e KOBOLDCPP_LORA_MULT=1.0 \
  koboldcpp:cpu

# Multiple LoRAs (pipe-separated)
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_LORA=/models/loras/lora1.gguf|/models/loras/lora2.gguf \
  -e KOBOLDCPP_LORA_MULT=0.8 \
  koboldcpp:cpu
```

**Image LoRA (for Stable Diffusion):**
```bash
# Image generation with LoRA
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_SDLORA=/models/loras/style-lora.safetensors \
  -e KOBOLDCPP_SDLORA_MULT=0.7 \
  koboldcpp:vulkan

# Multiple SD LoRAs
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_SDLORA=/models/loras/lora1.safetensors|/models/loras/lora2.safetensors \
  -e KOBOLDCPP_SDLORA_MULT=1.0 \
  koboldcpp:vulkan
```

**Using docker-compose:**
```yaml
environment:
  # Text LoRA for LLM fine-tuning
  - KOBOLDCPP_LORA=/models/loras/my-lora.gguf
  - KOBOLDCPP_LORA_MULT=1.0

  # Image LoRA for style transfer
  - KOBOLDCPP_SDLORA=/models/loras/anime-style.safetensors
  - KOBOLDCPP_SDLORA_MULT=0.8
```

**LoRA Tips:**
- Text LoRAs should be in GGUF format
- Image LoRAs can be .safetensors or .gguf format
- Multiplier controls LoRA strength (0.0-2.0, default 1.0)
- Lower multipliers = subtle effect, higher = stronger effect
- Multiple LoRAs are applied in order
- Store LoRAs in `./models/loras/` directory

### Download Model on First Run

Set the model URL and the container will download it automatically:

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL_URL=https://huggingface.co/bartowski/L3-8B-Stheno-v3.2-GGUF/resolve/main/L3-8B-Stheno-v3.2-Q4_K_S.gguf \
  -e KOBOLDCPP_MODEL_URL_FILENAME=/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf \
  koboldcpp:cpu
```

The model will be saved to the mounted volume and reused on subsequent starts.

### Pass Additional Arguments

Override default settings by passing extra arguments:

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  koboldcpp:cpu \
  --model /models/model.gguf \
  --contextsize 16384 \
  --threads 8 \
  --gpulayers 0
```

## GPU Support

### NVIDIA CUDA

**Requirements:**
- NVIDIA GPU with compute capability 6.0+
- nvidia-docker2 installed
- NVIDIA drivers installed on host

**Setup:**
```bash
# Install nvidia-docker (Ubuntu/Debian)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

**Test:**
```bash
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
```

### Vulkan (Universal)

**Requirements:**
- GPU with Vulkan 1.2+ support (NVIDIA, AMD, Intel)
- Vulkan drivers installed on host

**Supported GPUs:**
- NVIDIA: GTX 900 series and newer
- AMD: GCN 3rd gen and newer (RX 400 series+)
- Intel: 7th gen and newer

Vulkan provides good performance across all GPU vendors without vendor-specific runtimes.

### AMD ROCm

**Requirements:**
- AMD GPU with ROCm support
- ROCm drivers installed on host

**Supported GPUs:**
- Radeon RX 5000 series and newer
- Radeon VII
- Radeon Instinct MI series

## Performance Tuning

### Context Size

Larger context allows the model to remember more, but uses more memory:

```yaml
environment:
  - KOBOLDCPP_CONTEXT_SIZE=16384  # Double default
```

For most use cases, 8192-16384 is sufficient.

### GPU Layers

Controls how much of the model runs on GPU vs CPU:

```yaml
environment:
  - KOBOLDCPP_GPU_LAYERS=-1  # Auto (offload everything possible)
  - KOBOLDCPP_GPU_LAYERS=32  # Offload 32 layers
  - KOBOLDCPP_GPU_LAYERS=0   # CPU-only
```

**Tips:**
- Use `-1` for auto-detection (recommended)
- If running out of VRAM, reduce the number
- Monitor GPU memory with `nvidia-smi` or similar

### Thread Count

For CPU inference, adjust thread count:

```yaml
environment:
  - KOBOLDCPP_THREADS=0  # Auto (uses all cores)
  - KOBOLDCPP_THREADS=8  # Use 8 threads
```

Auto-detection works well in most cases.

## Troubleshooting

### Container won't start

**Check logs:**
```bash
docker-compose logs -f koboldcpp
```

**Common issues:**
- No model file: Ensure model exists in `./models/` or set `KOBOLDCPP_MODEL_URL`
- Port conflict: Change `KOBOLDCPP_PORT` if 5001 is in use
- GPU not detected: Verify nvidia-docker or Vulkan setup

### Out of memory

**Reduce resource usage:**
1. Use a smaller model (Q4_K_S instead of Q6_K)
2. Reduce context size: `KOBOLDCPP_CONTEXT_SIZE=4096`
3. Reduce GPU layers: `KOBOLDCPP_GPU_LAYERS=20`
4. Use CPU-only mode

### Slow performance

**Optimize performance:**
1. Use GPU acceleration (CUDA or Vulkan)
2. Increase GPU layers: `KOBOLDCPP_GPU_LAYERS=-1`
3. Use a quantized model (Q4_K_S is fastest)
4. Ensure container has enough CPU cores

### GPU not detected

**NVIDIA:**
```bash
# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi

# Check nvidia-docker
sudo systemctl status docker
```

**Vulkan:**
```bash
# Check Vulkan devices on host
vulkaninfo | grep deviceName

# Ensure /dev/dri is accessible
ls -la /dev/dri
```

## LoRA Adapters

### What are LoRAs?

LoRA (Low-Rank Adaptation) adapters are small files that fine-tune model behavior without retraining the entire model. They're useful for:

**Text LoRAs (LLM):**
- Character personalities
- Writing styles
- Domain-specific knowledge
- Instruction following improvements

**Image LoRAs (Stable Diffusion):**
- Art styles (anime, realistic, etc.)
- Character appearances
- Specific objects or concepts
- Lighting and composition styles

### LoRA File Formats

- **Text LoRAs**: GGUF format (`.gguf`)
- **Image LoRAs**: Safetensors (`.safetensors`) or GGUF (`.gguf`)

### Finding LoRAs

**Text LoRAs:**
- [Hugging Face](https://huggingface.co/models?other=lora&sort=downloads) - Search for "lora gguf"
- CivitAI - Some models available in GGUF

**Image LoRAs:**
- [CivitAI](https://civitai.com) - Largest collection
- [Hugging Face](https://huggingface.co/models?pipeline_tag=text-to-image&other=lora)

### Directory Structure

Organize LoRAs in the models directory:
```
./models/
├── model.gguf              # Main LLM model
├── sd-model.safetensors    # SD model
└── loras/
    ├── text-lora-1.gguf    # Text LoRAs
    ├── text-lora-2.gguf
    ├── style-lora.safetensors  # Image LoRAs
    └── character-lora.safetensors
```

### LoRA Strength Tuning

The multiplier controls how strongly the LoRA affects output:

```yaml
environment:
  # Subtle effect (0.3-0.6)
  - KOBOLDCPP_LORA_MULT=0.5

  # Standard effect (0.7-1.3)
  - KOBOLDCPP_LORA_MULT=1.0

  # Strong effect (1.4-2.0)
  - KOBOLDCPP_LORA_MULT=1.5
```

**Recommendations:**
- Start with 1.0 and adjust
- Lower values for subtle changes
- Higher values for dramatic effects
- SD LoRAs often work well at 0.6-0.8

## Container Management

```bash
# Start
docker-compose --profile cpu up -d

# Stop
docker-compose --profile cpu down

# Restart
docker-compose --profile cpu restart

# View logs
docker-compose logs -f

# Update and rebuild
docker-compose --profile cpu build --no-cache
docker-compose --profile cpu up -d
```

## Health Check

The container includes a health check that tests the API endpoint:

```bash
# Check container health
docker ps

# Manual health check
curl http://localhost:5001/api/v1/info
```

## Security

### API Key Protection

Add password protection:

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  koboldcpp:cpu \
  --password your-secret-key
```

Clients must include the key in API requests.

### Network Isolation

For production, use reverse proxy (nginx, traefik) and don't expose port directly:

```yaml
services:
  koboldcpp:
    # Remove ports section
    networks:
      - internal

  nginx:
    ports:
      - "443:443"
    networks:
      - internal
```

## Official Docker Image

KoboldCpp also provides an official Docker image:

```bash
docker pull koboldai/koboldcpp:latest
```

See: https://hub.docker.com/r/koboldai/koboldcpp

The Dockerfile in this repository provides additional features:
- Automated model downloads
- Environment-based configuration
- Multi-profile support
- Optimized build process

## Support

For issues and questions:
- GitHub Issues: https://github.com/LostRuins/koboldcpp/issues
- KoboldAI Discord: https://koboldai.org/discord
- Documentation: https://github.com/LostRuins/koboldcpp/wiki
