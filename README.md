# Inference Infrastructure Portfolio

Fifteen hands-on projects that cover what an inference infrastructure engineer actually does: serve models, measure them honestly, make them faster and cheaper, and keep them up when things break.

Each project is its own repository with a concept primer (`CONCEPTS.md`), working code, CPU-runnable tests, GPU notebooks that produce the numbers, and a write-up of what was measured and learned. Everything was built on free-tier GPUs (Kaggle and Colab T4s), and each README is explicit about where that hardware limits the results.

## Projects

| # | Repo | What it proves | Status |
|---|------|----------------|--------|
| 1 | [servellm](https://github.com/NomanJafar/servellm) | Serve an open model on vLLM with continuous batching behind an OpenAI-compatible API | **done** |
| 2 | [tokenbench](https://github.com/NomanJafar/tokenbench) | TTFT / inter-token latency / throughput under rising concurrency; the harness every later project reuses | **done** |
| 3 | [kvcalc](https://github.com/NomanJafar/kvcalc) | Predict KV cache VRAM per model and config, then watch live utilisation | **done** |
| 4 | [prefixrouter](https://github.com/NomanJafar/prefixrouter) | Route shared-prefix requests to the same replica to reuse KV blocks | **done** |
| 5 | [quantlab](https://github.com/NomanJafar/quantlab) | FP16 vs INT8 vs AWQ (vs FP8 where possible): quality, latency, VRAM | **done** |
| 6 | [specdec](https://github.com/NomanJafar/specdec) | Draft + target speculative decoding with acceptance-rate tracking | **done** |
| 7 | [fusedkernels](https://github.com/NomanJafar/fusedkernels) | Fused softmax and RMSNorm in Triton, benchmarked against PyTorch | **done** |
| 8 | [chunkedprefill-lab](https://github.com/NomanJafar/chunkedprefill-lab) | Chunked prefill under mixed prefill/decode load | **done** |
| 9 | [pagedattention-under-pressure](https://github.com/NomanJafar/pagedattention-under-pressure) | vLLM paging under memory pressure: fragmentation, preemption, eviction | **done** |
| 10 | [splitserve](https://github.com/NomanJafar/splitserve) | Disaggregated prefill/decode on separate GPUs | **done** |
| 11 | [gpuscaler](https://github.com/NomanJafar/gpuscaler) | Queue-depth autoscaling with cold-start mitigation | **done** |
| 12 | [tokenmeter](https://github.com/NomanJafar/tokenmeter) | Per-tenant token accounting, $/M tokens, MFU | **done** |
| 13 | [llmgateway](https://github.com/NomanJafar/llmgateway) | Multi-provider routing with SLOs, rate limits, retries, degradation chains | **done** |
| 14 | [inferchaos](https://github.com/NomanJafar/inferchaos) | GPU throttling, replica kills, traffic spikes; SLO burn and recovery | **done** |
| 15 | [serving-benchmarks](https://github.com/NomanJafar/serving-benchmarks) | Public, reproducible benchmark of three serving configs with full methodology | **done** |

## Scope

Scope, per-project day budgets and exclusions are in [SCOPE.md](SCOPE.md).

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

Headline numbers from each project, collected as they land.

- **servellm (1):** Qwen2.5-1.5B FP16 on a T4: hand-calculated KV cache (28,672 B/token) matched vLLM exactly (9.08 GiB, 340k tokens); continuous batching took aggregate throughput from 67 to 1,637 tok/s at 64 users (24x) while per-user ITL rose only 14.7 → 36.8 ms; with batching off, throughput stayed at 67 tok/s and median TTFT reached 29 s at 16 users; 16-token requests finished in 0.35 s alongside 8.9 s ones.
- **tokenbench (2):** reproduces servellm's closed-loop numbers within 2–5%; the open-loop sweep put the saturation point for a realistic prompt mix between 8 and 16 req/s: at 16 req/s the server generated *more* tokens (2,013 tok/s) but goodput halved (TTFT p50 1.8 s, 29% of requests within SLO) while vLLM's waiting queue stayed at 0.
- **kvcalc (3):** predicted KV cache capacity within 1.7% of vLLM's reported 340,064 tokens (per-token math exact, 1.05 GiB measured for activations + overhead); cache size unchanged between max-model-len 2048 and 8192; prefix caching made 64 users with identical 1,024-token prompts use 5.4% of cache instead of 24%.
- **prefixrouter (4):** two vLLM replicas on 2xT4 behind a system-prompt-affinity gateway: cold-start TTFT −45% (2,139 → 1,168 ms p50) and prefix-cache hit rate 0.87 → 0.94 versus round-robin; no difference after the first turn because a 4-prompt working set fits in every replica's cache; the load-threshold fallback kept a 3:1 skewed mix balanced (24/40 split) at no TTFT cost.
- **quantlab (5):** Qwen2.5-3B on a T4: single-stream ITL 40.3 → 16.8 (INT8, 2.4x) → 12.5 ms (INT4, 3.2x, tracking the weight-size ratio), fading to +27% throughput at 64 users; KV cache +64% at 4-bit; INT8 lossless (perplexity identical, GSM8K within noise); 4-bit costs 8–15 GSM8K points while perplexity moves only 8%, and AWQ's checkpoint loses more than GPTQ-Int4's.
- **specdec (6):** Qwen2.5-0.5B drafting for Qwen2.5-3B on a T4: greedy outputs byte-identical across all configurations; per-position acceptance decays geometrically (0.67 → 0.48 → 0.35, α≈0.68); k=1 is the best setting (+30% throughput at 4 users, +7% at 16) and k=5 is a net loss everywhere; speculation cost 37% of the KV cache; n-gram speculation proposed drafts in only 7% of steps on chat prompts.
- **chunkedprefill-lab (8):** with 3,500-token prompts arriving next to interactive chat on a T4, the worst inter-token stall an interactive user sees equals one chunk's prefill time: 1.35 s at `max-num-batched-tokens` 512, 2.1 s at 1024, 3.5 s at 2048 and above (a monolithic prefill); the long prompts paid only +2.5% TTFT for being chunked, so small budgets are nearly free; p99 ITL hid the single-stall cases entirely (152 ms vs a 3.5 s max), so the maximum is the metric to report.
- **pagedattention-under-pressure (9):** with prefix caching off and the cache shrunk to 52k tokens, vLLM preempted 203 times in 8 bursts: usage pinned at 100%, throughput −42%, ITL p99 486 ms vs a 62 ms median, a third of requests lost to a 120 s timeout; with prefix caching on, identical prompts never filled the cache at all; block size 32 cost 23% of capacity on this stack for no measurable gain.
- **splitserve (10):** on Kaggle's 2xT4 with vLLM 0.31's NixlConnector, a prefill GPU plus a decode GPU cut the interactive user's worst inter-token stall from 749 ms (one monolithic server) and 613 ms (two monolithic replicas) to 134 ms, and p99 from 584 to 55 ms, at identical throughput; the price was TTFT (+220 ms interactive, +450 ms for 1,500-token prompts), and the proxy's per-hop timing showed it was the second scheduler pass, not the KV bytes, that cost it; vLLM's filesystem ExampleConnector crashed the decode engine 90 s into the run.
- **gpuscaler (11):** on a T4-calibrated replay (90 s cold start, 10x bursts), reactive queue-depth scaling saved only 6% of GPU-hours against a peak-sized pool while adding 40 s waits at every burst start, because the queue built during the cold start and the policy overshot; one warm standby beat it on both axes (−11% GPU-hours vs peak-sized, p95 wait 1.9 s).
- **tokenmeter (12):** three tenants metered through the proxy on a T4 for 8 minutes: $0.047 of GPU time became $0.112 per M completion tokens fully loaded ($0.028 per M prompt tokens at a 1/4 weight), 5.4x cheaper than a $0.15/$0.60 hosted tier at only 36% of the card's measured capacity; MFU 2.8% and memory-bandwidth utilisation 39% put the server firmly in the memory-bound decode regime; weighting prompt tokens at 1/4 moved the RAG tenant from 42% of raw tokens to 23% of the bill.
- **llmgateway (13):** a FastAPI gateway with per-tenant token buckets, retries, a fallback chain and a TTFT-p95/error-rate circuit breaker with half-open probes; under inferchaos's injected faults a throttled provider burned 523% of the error budget before the breaker opened while a dead one burned 0%, and the chaos run found a real bug (the TTFT header reported the fallback attempt's time, not the user's wait).
- **inferchaos (14):** killing a real vLLM replica behind the gateway on a T4 produced 0 user-visible errors (breaker open 5.1 s after the kill, users served faster by the fallback); the restart took 96 s after the process-group kill released the GPU in 0.6 s; every bad event in the run came from the freshly started replica's Triton JIT compilations (3.5 s TTFTs, twice), which paged and opened the breaker: readiness is not warmth, and a slow replica costs more than a dead one.
- **serving-benchmarks (15):** Qwen2.5-3B on a T4 under an open-loop sweep with a stated SLO (TTFT ≤ 1 s, TPOT ≤ 60 ms): the knee moved from 1 req/s (FP16, no prefix caching: 700 shared prompt tokens re-prefilled per request, throughput *falling* under overload) to 2 req/s with prefix caching to 4 req/s with AWQ 4-bit, and $/M SLO-meeting tokens from 1.40 to 0.47 to 0.20 at $0.35/h; speculative decoding at k=1 was a wash once a chunk-counting TPOT bug in tokenbench was found and fixed through its row; all-token $/M kept falling into overload where under 8% of requests met the SLO, which is why goodput is the only cost that means anything.
- **fusedkernels (7):** hand-written Triton softmax and RMSNorm reach 67–75% of the T4's 320 GB/s on five of six shapes, beating `torch.softmax` by up to 35% (240 vs 178 GB/s at 4096x4096); `torch.compile` of the unfused code drops to 21–38% of peak on long rows; the single-block design hits a register-spill cliff at 65k-column rows.
