# KoboldCpp Docker - Charluv Fork

## ⚠️ Important Notice

**This is NOT the official KoboldCpp Docker image.**

This is a **Charluv-specialized fork** of KoboldCpp with the following modifications:

### Key Differences from Official KoboldCpp

1. **Modified Horde Integration**
   - Custom horde implementation optimized for Charluv services
   - Different API endpoints and worker configuration
   - Charluv-specific authentication and routing

2. **Charluv Backend Optimization**
   - Tuned for Charluv's infrastructure
   - Custom caching and performance optimizations
   - Specialized load balancing

3. **API Modifications**
   - Extended API endpoints for Charluv features
   - Custom response formats where applicable
   - Charluv-specific metadata handling

### Official KoboldCpp Resources

- **Official Docker Image**: https://hub.docker.com/r/koboldai/koboldcpp
- **Official Repository**: https://github.com/LostRuins/koboldcpp
- **Official Documentation**: https://github.com/LostRuins/koboldcpp/wiki

### Charluv Resources

- **Charluv Platform**: https://charluv.com
- **This Fork**: Specialized for Charluv backend deployment
- **Contact**: For Charluv-specific questions, contact Charluv support

---

## What is Charluv?

Charluv is a character AI chat platform that uses KoboldCpp as its inference backend. This Docker image is specifically configured to work optimally with Charluv's infrastructure.

## When to Use This Fork

✅ **Use this fork if:**
- You are deploying KoboldCpp for Charluv backend services
- You need Charluv horde integration
- You are part of the Charluv infrastructure team

❌ **Do NOT use this fork if:**
- You want standard KoboldCpp functionality
- You are not affiliated with Charluv
- You need official KoboldCpp support

**For general KoboldCpp usage, use the official Docker image instead.**

---

## Quick Start (Charluv Deployment)

### Prerequisites

- Docker and Docker Compose installed
- Model files or download URLs
- Charluv API credentials (if required)

### 1. Download a Model

```bash
./download-model.sh
```

Or place your `.gguf` model in `./models/`

### 2. Configure for Charluv

Edit `docker-compose.yml` environment section:

```yaml
environment:
  # Basic configuration
  - KOBOLDCPP_MODEL=/models/your-model.gguf
  - KOBOLDCPP_PORT=5001
  - KOBOLDCPP_CONTEXT_SIZE=8192

  # Charluv-specific settings
  - CHARLUV_HORDE_ENABLED=true
  - CHARLUV_API_KEY=your-charluv-api-key
  - CHARLUV_WORKER_NAME=your-worker-name
```

### 3. Deploy

```bash
# CPU deployment
docker-compose --profile cpu up -d

# GPU deployment (NVIDIA)
docker-compose --profile cuda up -d

# GPU deployment (Vulkan - AMD/Intel/NVIDIA)
docker-compose --profile vulkan up -d
```

### 4. Verify Deployment

```bash
# Check container status
docker-compose logs -f

# Test API endpoint
curl http://localhost:5001/api/v1/info

# Check Charluv horde connection
curl http://localhost:5001/api/charluv/horde/status
```

---

## Charluv-Specific Configuration

### Environment Variables

In addition to standard KoboldCpp variables, this fork supports:

| Variable | Default | Description |
|----------|---------|-------------|
| `CHARLUV_HORDE_ENABLED` | `false` | Enable Charluv horde worker mode |
| `CHARLUV_API_KEY` | - | Charluv API authentication key |
| `CHARLUV_WORKER_NAME` | `docker-worker` | Worker identifier for Charluv |
| `CHARLUV_WORKER_PRIORITY` | `normal` | Worker priority (`low`, `normal`, `high`) |
| `CHARLUV_MAX_CONTEXT` | `8192` | Maximum context for Charluv jobs |
| `CHARLUV_MAX_LENGTH` | `512` | Maximum generation length for Charluv |
| `CHARLUV_ENDPOINT` | Auto | Charluv backend endpoint URL |

### Horde Worker Mode

When deploying as a Charluv horde worker:

```yaml
environment:
  # Enable horde mode
  - CHARLUV_HORDE_ENABLED=true
  - CHARLUV_API_KEY=your-api-key
  - CHARLUV_WORKER_NAME=gpu-worker-01

  # Resource limits
  - CHARLUV_MAX_CONTEXT=16384
  - CHARLUV_MAX_LENGTH=1024
  - KOBOLDCPP_GPU_LAYERS=-1  # Use GPU

  # Performance tuning
  - KOBOLDCPP_THREADS=8
  - KOBOLDCPP_CONTEXT_SIZE=16384
```

### API Endpoints

This fork includes additional Charluv-specific endpoints:

- `POST /api/charluv/generate` - Charluv-optimized generation
- `GET /api/charluv/horde/status` - Horde worker status
- `POST /api/charluv/horde/register` - Register as horde worker
- `GET /api/charluv/metrics` - Charluv performance metrics

---

## Standard Features (From Official KoboldCpp)

All standard KoboldCpp Docker features are included:

- ✅ Model download on first run
- ✅ CPU and GPU support (CUDA, Vulkan, ROCm)
- ✅ LoRA adapter support
- ✅ Environment-based configuration
- ✅ Health checks and monitoring
- ✅ Volume mounts for models and data

See [DOCKER.md](DOCKER.md) for standard Docker usage documentation.

---

## Differences in Horde Implementation

### Official KoboldCpp Horde

The official KoboldCpp supports **AI Horde** (https://aihorde.net):

```bash
# Official KoboldCpp with AI Horde
python koboldcpp.py \
  --hordemodelname "Model Name" \
  --hordeworkername "Worker Name" \
  --hordekey "AI_HORDE_API_KEY"
```

### Charluv Fork Horde

This fork uses **Charluv Horde** with different:
- API endpoints and protocols
- Authentication mechanisms
- Job distribution logic
- Prioritization algorithms
- Metrics and monitoring

**Do not mix Charluv and AI Horde configurations** - they are incompatible.

---

## Migration from Official KoboldCpp

If migrating from official KoboldCpp Docker:

### What Stays the Same

- Model files and formats (GGUF)
- LoRA adapters
- Basic API endpoints (`/api/v1/...`)
- Volume mounts and configuration

### What Changes

- Horde integration (Charluv instead of AI Horde)
- Some API response formats
- Performance tuning defaults
- Monitoring endpoints

### Migration Steps

1. **Backup existing configuration:**
   ```bash
   docker-compose down
   cp docker-compose.yml docker-compose.yml.backup
   ```

2. **Update docker-compose.yml:**
   - Add Charluv environment variables
   - Remove AI Horde settings if present
   - Update image reference

3. **Update models directory:**
   ```bash
   # Models are compatible - no changes needed
   ls -la ./models/
   ```

4. **Deploy Charluv fork:**
   ```bash
   docker-compose --profile cpu up -d
   ```

5. **Verify Charluv connectivity:**
   ```bash
   docker-compose logs -f | grep -i charluv
   ```

---

## Support and Issues

### For Charluv-Specific Issues

- **Charluv Support**: Contact through Charluv platform
- **Horde Integration**: Charluv backend team
- **API Questions**: Charluv documentation

### For General KoboldCpp Issues

- **GitHub Issues**: https://github.com/LostRuins/koboldcpp/issues
- **Discord**: https://koboldai.org/discord
- **Wiki**: https://github.com/LostRuins/koboldcpp/wiki

**Note**: Official KoboldCpp support may not cover Charluv-specific modifications.

---

## License and Attribution

This fork is based on **KoboldCpp** by LostRuins:
- **Original Project**: https://github.com/LostRuins/koboldcpp
- **License**: AGPL v3.0 (see LICENSE.md)
- **Llama.cpp**: MIT License (see MIT_LICENSE_GGML_SDCPP_LLAMACPP_ONLY.md)

Charluv-specific modifications:
- Maintained by Charluv team
- Same AGPL v3.0 license applies
- Contributions to Charluv fork: Contact Charluv

---

## Disclaimer

This Docker image is a **specialized fork** and may diverge from official KoboldCpp over time.

- ⚠️ Not officially supported by KoboldCpp maintainers
- ⚠️ Charluv-specific features may break compatibility
- ⚠️ Use official KoboldCpp for general purposes
- ✅ Use this fork only for Charluv deployments

---

## Additional Documentation

- [DOCKER.md](DOCKER.md) - Complete Docker deployment guide
- [LORA.md](LORA.md) - LoRA adapter configuration
- [CLAUDE.md](CLAUDE.md) - Development and architecture
- [README.md](README.md) - Main KoboldCpp documentation

## Quick Links

- 🏠 **Charluv Platform**: https://charluv.com
- 📦 **Official KoboldCpp Docker**: https://hub.docker.com/r/koboldai/koboldcpp
- 📖 **Official Docs**: https://github.com/LostRuins/koboldcpp/wiki
- 💬 **Official Discord**: https://koboldai.org/discord
