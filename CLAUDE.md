# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ Repository Notice

**This is a Charluv-specialized fork of KoboldCpp.**

Key modifications from upstream:
- Custom horde integration for Charluv services (not AI Horde)
- Charluv-specific API endpoints and optimizations
- Modified worker deployment configuration

Official KoboldCpp: https://github.com/LostRuins/koboldcpp

## Project Overview

KoboldCpp is an easy-to-use AI text-generation software for GGML and GGUF models. It's a single self-contained distributable built on top of llama.cpp with extensive additional features including:

- LLM text generation (all GGML/GGUF models)
- Image generation (Stable Diffusion)
- Speech-to-text (Whisper)
- Text-to-speech (OuteTTS, Kokoro, Parler, Dia)
- Multiple API endpoints (KoboldCpp, OpenAI, Ollama, A1111, ComfyUI, Whisper, XTTS)

**Current version**: 1.108.2 (see `koboldcpp.py`)

## Build System

### Standard Build Commands

The project uses a Makefile-based build system:

```bash
# Build all variants (default target)
make

# Build specific variants
make koboldcpp_default        # Standard CPU build
make koboldcpp_vulkan         # Vulkan GPU support
make koboldcpp_cublas         # CUDA support
make koboldcpp_hipblas        # AMD ROCm support

# Build with specific options
make LLAMA_VULKAN=1           # Enable Vulkan
make LLAMA_CUBLAS=1           # Enable CUDA
make LLAMA_HIPBLAS=1          # Enable ROCm/HIP
make LLAMA_PORTABLE=1         # Portable build (required for distribution)
make LLAMA_METAL=1            # MacOS Metal support

# Clean build
make clean

# Build utility tools
make tools                     # Builds quantization and conversion tools
```

### Platform-Specific Builds

**Linux automated build** (recommended):
```bash
./koboldcpp.sh rebuild        # Auto-configures conda environment and builds
./koboldcpp.sh dist           # Creates PyInstaller binary
```

**Windows**:
- Use w64devkit terminal: `make` or `make LLAMA_VULKAN=1`
- For CUDA: Use Visual Studio with CMakeLists.txt (CMake GUI or command line)
- Create executable: `make_pyinstaller.bat`

**MacOS**:
```bash
make                          # Basic build
make LLAMA_METAL=1           # With Metal GPU support
```

### Running

```bash
# Python script (after building libraries)
python koboldcpp.py --help
python koboldcpp.py --model path/to/model.gguf

# Using prebuilt binary
./koboldcpp                   # Opens GUI
./koboldcpp --help           # CLI usage
./koboldcpp --model model.gguf --port 5001 --usevulkan --gpulayers 32
```

## Code Architecture

### Core Components

**Python Layer** (`koboldcpp.py`):
- HTTP server providing web UI and API endpoints
- Argument parsing and configuration
- Wraps C++ backend via ctypes bindings
- Default port: 5001

**C++ Backend** (expose.cpp/gpttype_adapter.cpp/model_adapter.cpp):
- `expose.cpp`: Primary C interface exposed to Python via ctypes
- `gpttype_adapter.cpp`: Model format detection and delegation
- `model_adapter.cpp`: Main model loading/generation orchestrator that includes all architecture-specific implementations

**Model Format Support**:
The codebase maintains backward compatibility with many legacy formats:
- GGUF (modern, preferred format) - handled by `src/llama.cpp`
- Legacy GGML formats (v1-v5) in `otherarch/`:
  - `llama_v2.cpp`, `llama_v3.cpp` - Legacy Llama formats
  - `gptj_v1.cpp`, `gptj_v2.cpp`, `gptj_v3.cpp` - GPT-J variants
  - `gpt2_v1.cpp`, `gpt2_v2.cpp`, `gpt2_v3.cpp` - GPT-2 variants
  - `neox_v2.cpp`, `neox_v3.cpp` - GPT-NeoX variants
  - `mpt_v3.cpp` - MPT models
  - `rwkv_v2.cpp`, `rwkv_v3.cpp` - RWKV models

Format detection happens in `expose.cpp:load_model()` via `check_file_format()`, which tries different format loaders with automatic fallback.

**Multimodal Components**:
- Image generation: `otherarch/sdcpp/` (Stable Diffusion)
- Speech recognition: `otherarch/whispercpp/` (Whisper)
- Text-to-speech: `otherarch/ttscpp/` (various TTS models)
- Vision/image understanding: `tools/mtmd/` (multimodal)

**Adapter System** (`kcpp_adapters/`):
JSON files defining chat format templates (Alpaca, ChatML, Llama-3, Mistral, etc.). Used for proper prompt formatting per model type.

### Key Data Flow

1. Python receives HTTP request → validates/processes via `koboldcpp.py`
2. Calls C++ backend via ctypes → `expose.h` interface
3. `expose.cpp` delegates to appropriate model loader
4. `model_adapter.cpp` orchestrates loading based on detected format
5. Generation happens in format-specific code or modern `src/llama.cpp`
6. Results returned through ctypes to Python → formatted as HTTP response

### Important Headers

- `expose.h`: C interface for Python bindings (load_model_inputs, generation_inputs, etc.)
- `model_adapter.h`: FileFormat enum, ModelLoadResult, model loading interface
- `llama.h`: Modern llama.cpp API (in `include/`)

## Development Tasks

### Model Conversion

Convert HuggingFace models to GGUF:
```bash
python convert_hf_to_gguf.py /path/to/hf/model --outfile output.gguf
python convert_hf_to_gguf.py --help  # See all options
```

Update conversion script:
```bash
python convert_hf_to_gguf_update.py
```

### Testing

Limited automated tests exist:
```bash
# Test Jinja template handling
cd tests && ./test-jinja

# Test model autodetection
python tests/test_autoguess.py
```

Most testing is manual via running models and checking generation quality.

### Creating PyInstaller Binary

**Linux**:
```bash
./koboldcpp.sh dist           # Creates dist/koboldcpp-linux-x64
```

**Windows**:
```bash
make_pyinstaller.bat          # Creates dist/koboldcpp.exe
```

Requires PyInstaller: `pip install PyInstaller`

## Docker Deployment

### Quick Start

**Download a model** (first time only):
```bash
./download-model.sh          # Interactive model selection
# Or manually place .gguf file in ./models/ directory
```

**Run with Docker Compose** (CPU):
```bash
docker-compose --profile cpu up -d
```

**Access the UI**:
- Web UI: http://localhost:5001
- API docs: http://localhost:5001/api

### Docker Compose Profiles

The `docker-compose.yml` includes multiple profiles for different hardware:

```bash
# CPU-only (default, no GPU required)
docker-compose --profile cpu up -d

# NVIDIA CUDA (requires nvidia-docker)
docker-compose --profile cuda up -d

# Vulkan (works with NVIDIA, AMD, Intel GPUs)
docker-compose --profile vulkan up -d

# AMD ROCm (AMD GPUs)
docker-compose --profile rocm up -d
```

### Docker Build Arguments

Custom builds with different GPU backends:

```bash
# CPU-only build (default)
docker build -t koboldcpp:cpu .

# Vulkan build (universal GPU support)
docker build --build-arg BUILD_TYPE=vulkan -t koboldcpp:vulkan .

# CUDA build (NVIDIA only)
docker build --build-arg BUILD_TYPE=cuda \
  --build-arg BASE_IMAGE=nvidia/cuda:12.1.1-runtime-ubuntu22.04 \
  -t koboldcpp:cuda .
```

### Environment Variables

Configure KoboldCpp via environment variables in docker-compose.yml or `docker run`:

**Model Configuration**:
- `KOBOLDCPP_MODEL`: Path to model file (e.g., `/models/model.gguf`)
- `KOBOLDCPP_MODEL_URL`: Download model from URL on first run
- `KOBOLDCPP_MODEL_URL_FILENAME`: Where to save downloaded model (default: `/models/model.gguf`)

**Server Settings**:
- `KOBOLDCPP_HOST`: Bind address (default: `0.0.0.0`)
- `KOBOLDCPP_PORT`: Port number (default: `5001`)
- `KOBOLDCPP_CONTEXT_SIZE`: Context window size (default: `8192`)
- `KOBOLDCPP_THREADS`: CPU threads, 0=auto (default: `0`)
- `KOBOLDCPP_QUIET`: Reduce logging (default: `true`)

**GPU Settings**:
- `KOBOLDCPP_USE_GPU`: GPU type (`cuda`, `vulkan`, `rocm`, or empty for CPU)
- `KOBOLDCPP_GPU_LAYERS`: Layers to offload, -1=auto (default: `0`)
- `CUDA_VISIBLE_DEVICES`: Select NVIDIA GPU by ID (e.g., `0`, `1`, `0,1`)
- `HIP_VISIBLE_DEVICES`: Select AMD GPU by ID

**LoRA Settings**:
- `KOBOLDCPP_LORA`: Text LoRA file(s), pipe-separated for multiple
- `KOBOLDCPP_LORA_MULT`: Text LoRA strength multiplier (default: `1.0`)
- `KOBOLDCPP_SDLORA`: Image LoRA file(s), pipe-separated for multiple
- `KOBOLDCPP_SDLORA_MULT`: Image LoRA strength multiplier (default: `1.0`)

### Manual Docker Run

```bash
# CPU-only with mounted model
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  koboldcpp:cpu

# Download model from URL on first run
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL_URL=https://huggingface.co/bartowski/L3-8B-Stheno-v3.2-GGUF/resolve/main/L3-8B-Stheno-v3.2-Q4_K_S.gguf \
  -e KOBOLDCPP_MODEL_URL_FILENAME=/models/model.gguf \
  koboldcpp:cpu

# NVIDIA GPU with CUDA
docker run -d \
  --gpus all \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_USE_GPU=cuda \
  -e KOBOLDCPP_GPU_LAYERS=-1 \
  koboldcpp:cuda
```

### Volume Mounts

- `/models` - Directory for model files (.gguf)
- `/models/loras` - Directory for LoRA adapter files (.gguf for text, .safetensors/.gguf for images)
- `/data` - Persistent data storage (optional)

### Docker Entrypoint

The `docker-entrypoint.sh` script handles:
1. Model download from URL if `KOBOLDCPP_MODEL_URL` is set
2. Automatic model discovery in `/models` directory
3. Configuration validation
4. Building command-line arguments from environment variables

You can override the entrypoint or pass additional arguments:
```bash
docker run -d -p 5001:5001 -v ./models:/models koboldcpp:cpu \
  --model /models/custom.gguf --contextsize 16384 --threads 8
```

### Docker Files

- `Dockerfile` - Multi-stage build with CPU/GPU support
- `docker-compose.yml` - Pre-configured services for different hardware
- `docker-entrypoint.sh` - Startup script with model download support
- `.dockerignore` - Excludes unnecessary files from build context
- `download-model.sh` - Helper script to download recommended models

### Official Docker Image

An official Docker image is maintained at: https://hub.docker.com/r/koboldai/koboldcpp

The Dockerfile in this repository provides an alternative with additional features:
- Model download on first run
- Environment variable configuration
- Multiple GPU backend support in one file
- Optimized multi-stage build

## Important Build Flags

- `LLAMA_PORTABLE=1`: Required for binaries to work on other machines (disables native CPU optimizations)
- `LLAMA_USE_BUNDLED_GLSLC=1`: Use included Vulkan shader compiler
- `LLAMA_NOAVX2=1`: Disable AVX2 (old CPU compatibility)
- `KCPP_DEBUG`: Enable debug symbols and disable optimizations
- `LOG_DISABLE_LOGS`: Reduce logging (enabled by default)

## Key Constraints

1. **Backward Compatibility**: Changes must not break loading of older GGML models. The project explicitly maintains support for all legacy formats.

2. **Single File Distribution**: The goal is a standalone executable with no external dependencies.

3. **Python-C++ Boundary**: All communication happens through fixed-size structs defined in `expose.h`. No dynamic memory allocation across the boundary.

4. **Minimal llama.cpp Changes**: The upstream llama.cpp code (`src/llama.cpp`, `ggml/`) should remain as close to original as possible for easier updates. Custom logic goes in adapters.

## Common Pitfalls

- When adding new parameters to `load_model_inputs` or `generation_inputs` in `expose.h`, you must update both the struct definition AND the Python ctypes binding in `koboldcpp.py`
- The Makefile builds multiple variants (default, vulkan, cublas, etc.) - changes to C++ code affect all variants
- Format detection in `expose.cpp` uses trial-and-error loading; a model failing to load may try multiple format parsers
- CMakeLists.txt is ONLY for Windows CUDA builds via Visual Studio, not general use

## File Organization

```
koboldcpp.py           - Main Python server and CLI
expose.cpp/h           - C interface to Python
gpttype_adapter.cpp    - Model format detection and dispatch
model_adapter.cpp/h    - Model loading orchestration
otherarch/             - Legacy model implementations and subsystems
  ├── *_v*.cpp         - Legacy format loaders
  ├── sdcpp/           - Stable Diffusion
  ├── whispercpp/      - Whisper speech recognition
  └── ttscpp/          - Text-to-speech
src/llama.cpp          - Modern llama.cpp (GGUF models)
ggml/                  - GGML library (low-level tensor ops)
common/                - Shared utilities from llama.cpp
tools/                 - Conversion and quantization tools
kcpp_adapters/         - Chat format templates (JSON)
```

## Dependencies

Python requirements (requirements.txt):
- numpy, sentencepiece, transformers - Model conversion
- customtkinter, darkdetect - GUI
- gguf - GGUF format handling
- jinja2 - Template rendering

Build dependencies:
- C++17 compiler
- CUDA Toolkit (for CUBLAS builds)
- Vulkan SDK (for Vulkan builds)
- ROCm (for HIPBLAS builds)
