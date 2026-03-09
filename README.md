# README

## octen-embedding-4b

SGLang deployment of [Octen/Octen-Embedding-4B](https://huggingface.co/Octen/Octen-Embedding-4B) on the Spark platform.

- **Output**: 2560-dimensional normalized embeddings
- **API port**: 30001
- **Endpoint**: `POST /v1/embeddings` (OpenAI-compatible)

### Why `lmsysorg/sglang:spark`

The host GPU is an NVIDIA GB10 (Blackwell, `sm_121a`). The `spark` image ships CUDA 13.0 and pre-compiled kernels that support it.

### Why `--json-model-override-args '{"architectures":["Qwen3ForCausalLM"]}'`

The model `config.json` declares `"architectures": ["Qwen3Model"]`. SGLang has no native handler for that name and falls back to a Transformers compatibility shim that does not support embedding mode. Overriding to `Qwen3ForCausalLM` routes to SGLang's native Qwen3 implementation which includes a proper last-token pooler.

### Deploy

```bash
docker compose up -d
```

### Test

```bash
./test-embedding.sh localhost:30001
```

### Quick curl

```bash
curl http://localhost:30001/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model":"Octen/Octen-Embedding-4B","input":"your text here"}'
```

