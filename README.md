# Inference Infrastructure Portfolio

Fifteen hands-on projects that cover what an inference infrastructure engineer actually does: serve models, measure them honestly, make them faster and cheaper, and keep them up when things break.

Each project is its own repository with a concept primer (`CONCEPTS.md`), working code, CPU-runnable tests, GPU notebooks that produce the numbers, and a write-up of what was measured and learned. Everything was built on free-tier GPUs (Kaggle and Colab T4s), and each README is explicit about where that hardware limits the results.

## Projects

| # | Repo | What it proves | Status |
|---|------|----------------|--------|
| 1 | [servellm](https://github.com/NomanJafar/servellm) | Serve an open model on vLLM with continuous batching behind an OpenAI-compatible API | in progress |
| 2 | [tokenbench](https://github.com/NomanJafar/tokenbench) | TTFT / inter-token latency / throughput under rising concurrency; the harness every later project reuses | planned |
| 3 | [kvcalc](https://github.com/NomanJafar/kvcalc) | Predict KV cache VRAM per model and config, then watch live utilisation | planned |
| 4 | [prefixrouter](https://github.com/NomanJafar/prefixrouter) | Route shared-prefix requests to the same replica to reuse KV blocks | planned |
| 5 | [quantlab](https://github.com/NomanJafar/quantlab) | FP16 vs INT8 vs AWQ (vs FP8 where possible): quality, latency, VRAM | planned |
| 6 | [specdec](https://github.com/NomanJafar/specdec) | Draft + target speculative decoding with acceptance-rate tracking | planned |
| 7 | [fusedkernels](https://github.com/NomanJafar/fusedkernels) | Fused softmax and RMSNorm in Triton, benchmarked against PyTorch | planned |
| 8 | [chunkedprefill-lab](https://github.com/NomanJafar/chunkedprefill-lab) | Chunked prefill under mixed prefill/decode load | planned |
| 9 | [pagedattention-under-pressure](https://github.com/NomanJafar/pagedattention-under-pressure) | vLLM paging under memory pressure: fragmentation, preemption, eviction | planned |
| 10 | [splitserve](https://github.com/NomanJafar/splitserve) | Disaggregated prefill/decode on separate GPUs | planned |
| 11 | [gpuscaler](https://github.com/NomanJafar/gpuscaler) | Queue-depth autoscaling with cold-start mitigation | planned |
| 12 | [tokenmeter](https://github.com/NomanJafar/tokenmeter) | Per-tenant token accounting, $/M tokens, MFU | planned |
| 13 | [llmgateway](https://github.com/NomanJafar/llmgateway) | Multi-provider routing with SLOs, rate limits, retries, degradation chains | planned |
| 14 | [inferchaos](https://github.com/NomanJafar/inferchaos) | GPU throttling, replica kills, traffic spikes; SLO burn and recovery | planned |
| 15 | [serving-benchmarks](https://github.com/NomanJafar/serving-benchmarks) | Public, reproducible benchmark of three serving configs with full methodology | planned |

## Build order

1 → 2 → 3 → 7 → 5 → 6 → 8 → 9 → 4 → 13 → 12 → 11 → 14 → 10 → 15

The benchmark harness (2) comes early because every later project is measured with it. The kernel project (7) sits in the middle as a deliberate change of pace from serving-stack work. The disaggregated cluster (10) and the public teardown (15) come last because they draw on everything before them.

## Conventions shared by every repo

- `CONCEPTS.md` is written before any code: the theory, the math, and what to look for in the results.
- `tests/` run on a laptop with no GPU.
- `notebooks/` hold the GPU runs; each notebook clones the repo, installs it, runs the experiment and writes `results/`.
- Default model: Qwen2.5-1.5B-Instruct in FP16, which fits a 16 GB T4 with room for KV cache. Speculative decoding uses Qwen2.5-3B as target and 0.5B as draft.
- READMEs report what was measured, including the runs that disproved the hypothesis.

## Hardware

Free-tier only: Kaggle and Colab T4s (16 GB, Turing). Two-GPU projects (4, 10) use Kaggle's 2×T4 option. Consequences, stated once here and again where relevant: no FP8, no FlashAttention-2, and the autoscaler (11) runs against local replica processes with a Kubernetes manifest as reference rather than a real GPU cluster.

## Results

Headline numbers from each project will be collected here as they land.
