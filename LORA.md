# LoRA Support in KoboldCpp Docker - Charluv Fork

> **ℹ️ Notice**: This is part of the Charluv-specialized KoboldCpp fork. LoRA features work the same as official KoboldCpp. For Charluv-specific features, see [DOCKER_CHARLUV.md](DOCKER_CHARLUV.md).

KoboldCpp supports LoRA (Low-Rank Adaptation) adapters for both text generation and image generation.

## Quick Start

### 1. Organize Your Files

```
./models/
├── model.gguf                    # Your main LLM model
├── sd-model.safetensors          # Optional: Stable Diffusion model
└── loras/
    ├── character-lora.gguf       # Text LoRAs (GGUF format)
    ├── writing-style.gguf
    ├── anime-style.safetensors   # Image LoRAs (safetensors or GGUF)
    └── portrait-lora.safetensors
```

### 2. Run with LoRA

**Using docker-compose.yml:**

Edit the environment section:
```yaml
environment:
  - KOBOLDCPP_MODEL=/models/model.gguf

  # Text LoRA (for LLM)
  - KOBOLDCPP_LORA=/models/loras/character-lora.gguf
  - KOBOLDCPP_LORA_MULT=1.0

  # Image LoRA (for Stable Diffusion)
  - KOBOLDCPP_SDLORA=/models/loras/anime-style.safetensors
  - KOBOLDCPP_SDLORA_MULT=0.8
```

Then start:
```bash
docker-compose --profile cpu up -d
```

**Using docker run:**
```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_LORA=/models/loras/character-lora.gguf \
  -e KOBOLDCPP_LORA_MULT=1.0 \
  koboldcpp:cpu
```

### 3. Multiple LoRAs

You can load multiple LoRAs by separating them with `|`:

```yaml
environment:
  # Multiple text LoRAs
  - KOBOLDCPP_LORA=/models/loras/lora1.gguf|/models/loras/lora2.gguf

  # Multiple image LoRAs
  - KOBOLDCPP_SDLORA=/models/loras/style1.safetensors|/models/loras/style2.safetensors
```

## LoRA Types

### Text LoRAs (for Language Models)

**Format:** GGUF (`.gguf`)

**Use Cases:**
- Character personalities and behavior
- Writing styles (formal, casual, poetic)
- Domain-specific knowledge (medical, legal, technical)
- Instruction following improvements
- Language or dialect variations

**Where to Find:**
- [Hugging Face](https://huggingface.co/models?other=lora&sort=downloads) - Search "lora gguf"
- Convert from PyTorch: Use `convert_lora_to_gguf.py`

**Example:**
```bash
# Character personality LoRA
-e KOBOLDCPP_LORA=/models/loras/sherlock-holmes.gguf
-e KOBOLDCPP_LORA_MULT=1.0
```

### Image LoRAs (for Stable Diffusion)

**Format:** Safetensors (`.safetensors`) or GGUF (`.gguf`)

**Use Cases:**
- Art styles (anime, oil painting, watercolor)
- Character appearances
- Specific concepts or objects
- Lighting and composition
- Photography styles

**Where to Find:**
- [CivitAI](https://civitai.com/) - Largest collection
- [Hugging Face](https://huggingface.co/models?pipeline_tag=text-to-image&other=lora)

**Example:**
```bash
# Anime art style LoRA
-e KOBOLDCPP_SDLORA=/models/loras/anime-style.safetensors
-e KOBOLDCPP_SDLORA_MULT=0.7
```

## Multiplier Settings

The multiplier controls how strongly the LoRA affects the output:

| Multiplier | Effect | Use Case |
|------------|--------|----------|
| 0.1 - 0.4  | Very subtle | Minor tweaks, blending styles |
| 0.5 - 0.7  | Noticeable | Balanced effect, recommended for testing |
| 0.8 - 1.2  | Standard | Full LoRA effect, default |
| 1.3 - 1.8  | Strong | Emphasize LoRA characteristics |
| 1.9 - 2.0  | Very strong | Maximum effect, may cause artifacts |

**Recommendations:**
- **Start with 1.0** - The default multiplier
- **Lower for subtlety** - 0.6-0.8 for gentle style changes
- **Higher for emphasis** - 1.2-1.5 for strong characteristics
- **Image LoRAs** - Often work best at 0.6-0.9
- **Multiple LoRAs** - Use lower multipliers to avoid conflicts

## Advanced Usage

### Combining Multiple LoRAs

When using multiple LoRAs, they're applied sequentially:

```yaml
environment:
  # Combine character + writing style
  - KOBOLDCPP_LORA=/models/loras/character.gguf|/models/loras/writing-style.gguf
  - KOBOLDCPP_LORA_MULT=0.8  # Applies to all LoRAs
```

**Tips for Multiple LoRAs:**
- Use compatible LoRAs (avoid conflicts)
- Lower the multiplier (0.6-0.8) to prevent over-fitting
- Order matters - first LoRA has priority
- Test combinations individually first

### Converting LoRAs to GGUF

If you have PyTorch LoRA files, convert them:

```bash
# Run conversion inside container or on host
python convert_lora_to_gguf.py \
  --base /path/to/base/model \
  --lora /path/to/lora.safetensors \
  --outfile /models/loras/converted-lora.gguf
```

### Dynamic LoRA Switching

To change LoRAs without rebuilding:

1. **Mount LoRA directory as volume:**
   ```bash
   -v ./models/loras:/models/loras
   ```

2. **Add new LoRA files** to `./models/loras/`

3. **Restart container** with new environment variables:
   ```bash
   docker-compose restart
   ```

### Per-Request LoRA (API)

LoRAs can also be specified per API request (if supported by your client):

```json
{
  "prompt": "Your prompt here",
  "lora": "/models/loras/specific-lora.gguf",
  "lora_scale": 0.8
}
```

## Troubleshooting

### LoRA Not Loading

**Problem:** LoRA file not found or not applied

**Solutions:**
1. Check file path is absolute: `/models/loras/file.gguf` not `./loras/file.gguf`
2. Verify file exists: `docker exec koboldcpp ls /models/loras/`
3. Check file format: Text LoRAs must be GGUF
4. Ensure volume is mounted: `-v ./models/loras:/models/loras`
5. Check container logs: `docker logs koboldcpp`

### Incompatible LoRA

**Problem:** LoRA causes errors or degraded quality

**Solutions:**
1. Verify LoRA matches base model architecture
2. Check LoRA was trained for your model size (7B, 13B, etc.)
3. Try lowering multiplier to 0.5-0.7
4. Test LoRA individually without other LoRAs
5. Ensure LoRA format matches requirements (GGUF for text)

### Multiple LoRAs Conflicting

**Problem:** Output is incoherent or unstable

**Solutions:**
1. Reduce multiplier to 0.5-0.7 for all LoRAs
2. Test each LoRA individually
3. Remove conflicting LoRAs
4. Reorder LoRAs - put most important first
5. Use fewer LoRAs simultaneously

### Out of Memory

**Problem:** Container crashes when loading LoRAs

**Solutions:**
1. LoRAs add memory overhead - reduce GPU layers
2. Use smaller LoRAs or fewer simultaneously
3. Increase Docker memory limit
4. Use CPU-only mode if GPU memory is limited

## Examples

### Example 1: Character Roleplay

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/llama3-8b.gguf \
  -e KOBOLDCPP_LORA=/models/loras/sherlock-holmes.gguf \
  -e KOBOLDCPP_LORA_MULT=1.2 \
  -e KOBOLDCPP_CONTEXT_SIZE=8192 \
  koboldcpp:cpu
```

### Example 2: Creative Writing

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/mistral-7b.gguf \
  -e KOBOLDCPP_LORA=/models/loras/fantasy-writer.gguf|/models/loras/descriptive-style.gguf \
  -e KOBOLDCPP_LORA_MULT=0.9 \
  koboldcpp:cpu
```

### Example 3: Anime Image Generation

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/llama3-8b.gguf \
  -e KOBOLDCPP_SDLORA=/models/loras/anime-v3.safetensors|/models/loras/detailed-eyes.safetensors \
  -e KOBOLDCPP_SDLORA_MULT=0.75 \
  --gpus all \
  koboldcpp:cuda
```

### Example 4: Multi-Modal with LoRAs

```bash
docker run -d \
  -p 5001:5001 \
  -v ./models:/models \
  -e KOBOLDCPP_MODEL=/models/model.gguf \
  -e KOBOLDCPP_LORA=/models/loras/assistant.gguf \
  -e KOBOLDCPP_LORA_MULT=1.0 \
  -e KOBOLDCPP_SDLORA=/models/loras/photorealistic.safetensors \
  -e KOBOLDCPP_SDLORA_MULT=0.8 \
  koboldcpp:vulkan
```

## Best Practices

1. **Start Simple**
   - Test with one LoRA at default multiplier (1.0)
   - Add complexity gradually

2. **Organize Files**
   - Keep LoRAs in dedicated directory (`./models/loras/`)
   - Use descriptive filenames
   - Document LoRA purpose and optimal multiplier

3. **Test Multipliers**
   - Try 0.5, 0.8, 1.0, 1.2 to find sweet spot
   - Different LoRAs work best at different strengths

4. **Version Control**
   - Track which LoRAs work well together
   - Document successful combinations

5. **Monitor Resources**
   - LoRAs increase memory usage
   - Watch for performance degradation

## Resources

- **Official KoboldCpp Docs:** https://github.com/LostRuins/koboldcpp/wiki
- **LoRA Training:** https://github.com/cloneofsimo/lora
- **CivitAI:** https://civitai.com/ (Image LoRAs)
- **Hugging Face:** https://huggingface.co/models?other=lora (Text & Image LoRAs)

## See Also

- [DOCKER.md](DOCKER.md) - Complete Docker deployment guide
- [CLAUDE.md](CLAUDE.md) - Development and architecture documentation
- [README.md](README.md) - Main KoboldCpp documentation
