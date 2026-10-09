# Scope lock

These are portfolio projects, not production systems. The goal of each is to **demonstrate a concept with measured numbers and a clear write-up**, in a bounded amount of work. Total budget: **~19 dev days**, one or two projects at a time, every day ending in a pushed commit.

## Definition of done (every project)

1. `CONCEPTS.md` explains the idea in plain terms with the relevant math.
2. Code is small, readable, and has CPU-only tests that pass.
3. One notebook or script produces `results/*.json` and plots on a free T4 (or locally against the mock server where no GPU is needed).
4. README has a **Results** section with the measured numbers, the plots, and 3–5 bullet points of what was learned, including anything that did not match the prediction.
5. Repo is public.

## What is out of scope everywhere

- Authentication, multi-user, persistence beyond SQLite/JSON, Docker images, CI pipelines, Helm charts.
- Supporting more than one model family or more than one serving engine (vLLM only; SGLang is mentioned, not used).
- Hardware we do not have: no A100/H100 numbers, no FP8, no multi-node.
- Polished UIs. A dashboard is a single static HTML page or a Streamlit app, not a frontend project.
- Hardening: retries, edge cases and error handling only where they are the subject of the project (13, 14).

## Shared infrastructure (built once, in `tokenbench`)

- `tokenbench` is a pip package. Every later project installs it from GitHub instead of copying benchmark code.
- `tokenbench.mockserver`: an OpenAI-compatible fake server with configurable TTFT, ITL, capacity and failure modes. Projects 4, 11, 12, 13, 14 develop against it on a laptop and validate once on a T4.

## Per-project scope

| # | Repo | Days | In scope (locked) | Out of scope |
|---|------|------|-------------------|--------------|
| 1 | servellm | 1.5 (1 done) | Launcher, streaming client, `/metrics` scraper, concurrency sweep, batching on/off, mixed lengths, Kaggle notebook, results write-up | Any serving engine but vLLM; tuning beyond `max-num-seqs` |
| 2 | tokenbench | 2 | Closed-loop and open-loop (fixed arrival rate) load; TTFT/ITL/E2E p50/p95/p99, goodput under an SLO; concurrency and rate sweeps; JSON + CSV output; plots; CLI; `mockserver`; pip-installable | Distributed load generation; dataset-driven prompts beyond one ShareGPT-style sample file |
| 3 | kvcalc | 1 | Calculator from a HF `config.json` (layers, KV heads, head_dim, dtype) → bytes/token, max tokens and max concurrency for a given VRAM and `gpu-memory-utilization`; MHA vs GQA vs MLA comparison table for 5 well-known models; live monitor polling `/metrics` and printing predicted vs actual block usage | GUI; quantized KV cache; exotic attention variants beyond MLA |
| 4 | prefixrouter | 1.5 | HTTP proxy (FastAPI) in front of N replicas; routes by hash of system prompt with consistent hashing; falls back to least-loaded when a replica is saturated; measures TTFT with vs without affinity on 2×T4 with `--enable-prefix-caching`; reports vLLM prefix-cache hit-rate metric | Session stickiness beyond the system prompt; replica health checking beyond a timeout |
| 5 | quantlab | 1 | FP16, GPTQ-Int8 (or INT8 via vLLM's quantization path if a checkpoint exists), AWQ for the same Qwen model; `tokenbench` latency sweep + VRAM from `/metrics` + quality via perplexity on a fixed 200-sample text set and exact-match on 100 GSM8K items; one table, one plot | FP8 (no T4 support, documented); quantizing weights ourselves; more than 3 configs |
| 6 | specdec | 1 | vLLM speculative decoding with Qwen2.5-0.5B draft / 3B target (or n-gram speculation as the second method); sweep `num_speculative_tokens` 1–5; acceptance rate from vLLM metrics; ITL and throughput vs baseline; where it helps and where it hurts (batch size) | Training a draft model; EAGLE/Medusa heads |
| 7 | fusedkernels | 1.5 | Triton softmax and RMSNorm (forward only), tests against PyTorch under `TRITON_INTERPRET=1` on CPU, GPU benchmark across 6 shapes vs `torch.softmax` / `torch.nn.functional.rms_norm` and `torch.compile`; a walkthrough of the tiling/memory reasoning | Backward passes; attention kernels; autotuning beyond 3 block sizes |
| 8 | chunkedprefill-lab | 1 | Sweep `--max-num-batched-tokens` (e.g. 512, 2048, 8192) and chunked-prefill on/off under a mixed load (long-prompt requests + short interactive requests via `tokenbench` open-loop); plot decode ITL p95 and long-prompt TTFT against chunk size; write-up of the trade-off | Modifying vLLM's scheduler |
| 9 | pagedattention-under-pressure | 1 | Shrink KV cache (`gpu-memory-utilization`, `max-num-seqs`) to force pressure; drive load; record `num_preemptions`, KV usage, waiting queue, throughput over time; compare `--block-size` 16 vs 32; a report with annotated timelines explaining recompute-vs-swap preemption | Patching vLLM; swap-to-CPU experiments beyond one on/off comparison |
| 10 | splitserve | 1.5 | vLLM disaggregated prefill on Kaggle 2×T4 (prefill instance, decode instance, KV connector); same `tokenbench` sweep against one 1×T4 monolithic server; TTFT, ITL, throughput deltas; honest discussion of why a 2-GPU toy shows what it shows. If the KV connector does not run on T4, fall back to a documented event-driven simulator with the same measurements | Multi-node; custom KV transfer |
| 11 | gpuscaler | 1 | Controller loop: reads queue depth (`num_requests_waiting`) from N `mockserver` replicas, scales replica count with a target-queue-depth policy, cooldown and a warm standby to hide cold start; replay a bursty trace; plot replicas, queue depth, p95 latency and "GPU-hours" over time with and without the warm pool; a KEDA `ScaledObject` manifest as reference | Real Kubernetes; real GPU provisioning |
| 12 | tokenmeter | 1 | Proxy middleware records tenant (header), model, prompt/completion tokens, latency into SQLite; `$ / M tokens` from a price table and an hourly GPU cost; MFU = achieved FLOPs (2 × params × tokens/s) / peak FLOPs; single-page HTML dashboard with a per-tenant table and two charts; validated with one real run on the T4 | Billing integration; auth; streaming of partial usage |
| 13 | llmgateway | 1.5 | FastAPI router: provider list (self-hosted vLLM + one or two API providers via OpenAI-compatible URLs), per-tenant token-bucket rate limit, retries with backoff, fallback chain on error/timeout, TTFT SLO: if p95 TTFT of a provider exceeds threshold over a window, degrade to next provider; tested end-to-end against `mockserver` with injected failures | Caching; prompt rewriting; cost-based routing (noted as extension) |
| 14 | inferchaos | 1 | Fault injectors for `mockserver` (slow replica = GPU throttling, replica kill, 10× traffic spike); runs each against `llmgateway` + replicas; SLO burn-rate calculation (error budget, multi-window alerts); recovery time; one report with timelines per fault; one live T4 validation (kill the vLLM process mid-load) | Real GPU clock throttling via `nvidia-smi -lgc`; Kubernetes chaos tooling |
| 15 | serving-benchmarks | 1.5 | Three configs on the same T4 and model: (a) baseline FP16, (b) AWQ + prefix caching, (c) speculative decoding; `tokenbench` open-loop sweeps; latency/throughput/goodput curves and $/M tokens at an assumed GPU hourly price; a METHODOLOGY.md anyone can rerun; raw JSON committed | Comparing against hosted APIs; more than one GPU type |

**Total: 19 days** (17.5 remaining).

## Daily rhythm

- Each day: one concept primer or one build step or one results write-up, ending in a pushed commit. Nothing stays local overnight.
- GPU runs are done by Noman on Kaggle; while a run is queued, work continues on the next project's primer or code.
- If a project is overrunning its budget by more than half a day, cut scope to what is already measured and write it up; the write-up says what was cut.

## Change control

This file is the contract. Adding to a project's scope requires removing something of equal size or an explicit decision to extend the budget. Discoveries that are interesting but outside scope go into a "Further work" line in that project's README.
