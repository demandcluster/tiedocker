# KoboldCpp Docker - Charluv Fork

## 🚨 Important: Read Before Using

### This is NOT Official KoboldCpp

This Docker setup is for a **Charluv-specialized fork** of KoboldCpp.

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  CHARLUV FORK - Modified Horde Implementation          │
│                                                             │
│  This version is specifically configured for Charluv        │
│  backend services and uses Charluv Horde, not AI Horde.    │
│                                                             │
│  For official KoboldCpp:                                    │
│  https://hub.docker.com/r/koboldai/koboldcpp               │
└─────────────────────────────────────────────────────────────┘
```

### What's Different?

| Feature | Official KoboldCpp | This Fork (Charluv) |
|---------|-------------------|---------------------|
| **Horde** | AI Horde (aihorde.net) | Charluv Horde (custom) |
| **API Endpoints** | Standard KoboldAI API | Extended with Charluv endpoints |
| **Authentication** | Optional password | Charluv API keys |
| **Worker Mode** | AI Horde workers | Charluv Horde workers |
| **Use Case** | General purpose | Charluv backend |

### When to Use This Fork

✅ **Use this if you are:**
- Deploying for Charluv infrastructure
- Running Charluv horde workers
- Part of Charluv development team

❌ **Don't use this if you want:**
- Standard KoboldCpp features
- AI Horde integration
- Official KoboldCpp support

---

## Quick Start

### For Charluv Deployments

1. **Download a model:**
   ```bash
   ./download-model.sh
   ```

2. **Configure Charluv settings** in `docker-compose.yml`:
   ```yaml
   environment:
     - KOBOLDCPP_MODEL=/models/model.gguf
     - CHARLUV_HORDE_ENABLED=true
     - CHARLUV_API_KEY=your-api-key
   ```

3. **Start the container:**
   ```bash
   docker-compose --profile cpu up -d
   ```

4. **Verify deployment:**
   ```bash
   curl http://localhost:5001/api/charluv/horde/status
   ```

### For Standard KoboldCpp

**Don't use this repository.** Instead:

1. Use official Docker image:
   ```bash
   docker pull koboldai/koboldcpp:latest
   ```

2. See official documentation:
   - https://github.com/LostRuins/koboldcpp
   - https://github.com/LostRuins/koboldcpp/wiki

---

## Documentation

### Charluv-Specific

- **[DOCKER_CHARLUV.md](DOCKER_CHARLUV.md)** - ⭐ Start here for Charluv deployments
  - Charluv horde configuration
  - Charluv API endpoints
  - Environment variables
  - Worker deployment guide

### General Docker Usage

- **[DOCKER.md](DOCKER.md)** - Standard Docker features
  - CPU and GPU support
  - Model downloading
  - Performance tuning
  - Troubleshooting

### Additional Guides

- **[LORA.md](LORA.md)** - LoRA adapter configuration
- **[CLAUDE.md](CLAUDE.md)** - Development and architecture guide

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Docker Container                    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  KoboldCpp (Charluv Fork)                  │    │
│  │  ├─ Standard KoboldCpp Features            │    │
│  │  ├─ Charluv Horde Integration  ⭐          │    │
│  │  ├─ Charluv API Extensions     ⭐          │    │
│  │  └─ Custom Performance Tuning  ⭐          │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  Volumes:                                            │
│  • /models       - Model files                       │
│  • /models/loras - LoRA adapters                     │
│  • /data         - Persistent data                   │
└─────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
   Charluv Horde           Standard KoboldCpp APIs
   (Custom)                (Compatible)
```

---

## Supported Configurations

### Hardware Acceleration

| Backend | Profile | GPU Support |
|---------|---------|-------------|
| **CPU** | `cpu` | None (CPU-only) |
| **CUDA** | `cuda` | NVIDIA GPUs |
| **Vulkan** | `vulkan` | NVIDIA, AMD, Intel |
| **ROCm** | `rocm` | AMD GPUs |

### Deployment Profiles

```bash
# CPU-only (no GPU)
docker-compose --profile cpu up -d

# NVIDIA GPU (CUDA)
docker-compose --profile cuda up -d

# Universal GPU (Vulkan)
docker-compose --profile vulkan up -d

# AMD GPU (ROCm)
docker-compose --profile rocm up -d
```

---

## Configuration

### Standard KoboldCpp Environment Variables

All standard variables supported:
- `KOBOLDCPP_MODEL` - Model file path
- `KOBOLDCPP_PORT` - Server port (default: 5001)
- `KOBOLDCPP_CONTEXT_SIZE` - Context window size
- `KOBOLDCPP_GPU_LAYERS` - GPU layer offloading
- `KOBOLDCPP_LORA` - LoRA adapters
- And more... (see DOCKER.md)

### Charluv-Specific Variables

**Horde Configuration:**
- `CHARLUV_HORDE_ENABLED` - Enable Charluv horde worker
- `CHARLUV_API_KEY` - Charluv authentication key
- `CHARLUV_WORKER_NAME` - Worker identifier
- `CHARLUV_WORKER_PRIORITY` - Worker priority level
- `CHARLUV_MAX_CONTEXT` - Max context for jobs
- `CHARLUV_MAX_LENGTH` - Max generation length

See [DOCKER_CHARLUV.md](DOCKER_CHARLUV.md) for complete reference.

---

## Example Configurations

### Basic Charluv Worker

```yaml
services:
  koboldcpp-worker:
    build: .
    ports:
      - "5001:5001"
    volumes:
      - ./models:/models
    environment:
      - KOBOLDCPP_MODEL=/models/model.gguf
      - KOBOLDCPP_GPU_LAYERS=-1
      - CHARLUV_HORDE_ENABLED=true
      - CHARLUV_API_KEY=${CHARLUV_API_KEY}
      - CHARLUV_WORKER_NAME=worker-01
```

### High-Performance GPU Worker

```yaml
services:
  koboldcpp-gpu:
    build:
      context: .
      args:
        BUILD_TYPE: cuda
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - KOBOLDCPP_MODEL=/models/large-model.gguf
      - KOBOLDCPP_CONTEXT_SIZE=16384
      - KOBOLDCPP_GPU_LAYERS=-1
      - KOBOLDCPP_THREADS=8
      - CHARLUV_HORDE_ENABLED=true
      - CHARLUV_MAX_CONTEXT=16384
```

### LoRA-Enhanced Worker

```yaml
services:
  koboldcpp-lora:
    build: .
    environment:
      - KOBOLDCPP_MODEL=/models/base-model.gguf
      - KOBOLDCPP_LORA=/models/loras/character.gguf
      - KOBOLDCPP_LORA_MULT=1.0
      - CHARLUV_HORDE_ENABLED=true
      - CHARLUV_API_KEY=${CHARLUV_API_KEY}
```

---

## API Endpoints

### Standard KoboldCpp APIs (Compatible)

These work the same as official KoboldCpp:
- `GET /api/v1/info` - Server information
- `POST /api/v1/generate` - Text generation
- `GET /api/v1/model` - Model details
- `POST /v1/completions` - OpenAI-compatible completions
- `POST /v1/chat/completions` - OpenAI-compatible chat

### Charluv-Specific APIs ⭐

Additional endpoints for Charluv integration:
- `POST /api/charluv/generate` - Charluv-optimized generation
- `GET /api/charluv/horde/status` - Horde worker status
- `POST /api/charluv/horde/register` - Register as worker
- `GET /api/charluv/metrics` - Performance metrics
- `POST /api/charluv/config` - Dynamic configuration

---

## Migration Guide

### From Official KoboldCpp to Charluv Fork

1. **Backup configuration:**
   ```bash
   cp docker-compose.yml docker-compose.yml.backup
   ```

2. **Models are compatible** - No changes needed
   ```bash
   # Your existing models work fine
   ls ./models/*.gguf
   ```

3. **Update docker-compose.yml:**
   - Add `CHARLUV_*` environment variables
   - Remove `--horde*` flags if present (different horde)

4. **Deploy:**
   ```bash
   docker-compose --profile cpu up -d
   ```

### From Charluv Fork to Official KoboldCpp

If you want to switch to official KoboldCpp:

1. **Use official image:**
   ```bash
   docker pull koboldai/koboldcpp:latest
   docker run -p 5001:5001 -v ./models:/models koboldai/koboldcpp
   ```

2. **Remove Charluv variables** - They won't be recognized

3. **Update horde settings** - Use AI Horde credentials if needed

---

## Troubleshooting

### Charluv-Specific Issues

**Horde not connecting:**
```bash
# Check Charluv API key
docker-compose logs | grep -i charluv

# Verify horde status
curl http://localhost:5001/api/charluv/horde/status

# Test authentication
curl -H "X-API-Key: your-key" http://localhost:5001/api/charluv/metrics
```

**Worker not registering:**
- Verify `CHARLUV_API_KEY` is set correctly
- Check `CHARLUV_WORKER_NAME` is unique
- Ensure network connectivity to Charluv backend
- Review logs: `docker-compose logs -f`

### General Issues

See [DOCKER.md](DOCKER.md) troubleshooting section for:
- GPU not detected
- Out of memory errors
- Port conflicts
- Model loading failures

---

## Support

### For Charluv Fork Issues

- **Charluv Platform**: Contact through Charluv support
- **Horde Integration**: Charluv backend team
- **This Docker Setup**: Create issue on this repository

### For General KoboldCpp Issues

- **GitHub**: https://github.com/LostRuins/koboldcpp/issues
- **Discord**: https://koboldai.org/discord
- **Wiki**: https://github.com/LostRuins/koboldcpp/wiki

**Note**: Official KoboldCpp support may not cover Charluv modifications.

---

## License

Based on KoboldCpp (AGPL v3.0): https://github.com/LostRuins/koboldcpp

Charluv-specific modifications under same license.

See:
- [LICENSE.md](LICENSE.md) - AGPL v3.0 license
- [MIT_LICENSE_GGML_SDCPP_LLAMACPP_ONLY.md](MIT_LICENSE_GGML_SDCPP_LLAMACPP_ONLY.md) - MIT license for llama.cpp components

---

## Resources

### This Fork
- 📚 [DOCKER_CHARLUV.md](DOCKER_CHARLUV.md) - Charluv deployment guide
- 📚 [DOCKER.md](DOCKER.md) - General Docker guide
- 📚 [LORA.md](LORA.md) - LoRA configuration
- 📚 [CLAUDE.md](CLAUDE.md) - Developer documentation

### Official KoboldCpp
- 🏠 Homepage: https://github.com/LostRuins/koboldcpp
- 🐳 Official Docker: https://hub.docker.com/r/koboldai/koboldcpp
- 📖 Wiki: https://github.com/LostRuins/koboldcpp/wiki
- 💬 Discord: https://koboldai.org/discord

### Charluv
- 🌐 Platform: https://charluv.com
- 📧 Support: Contact via Charluv platform
