# Progress

Ordered task queue for the daily build. One task per day. `[gpu]` tasks need Kaggle credentials and are skipped until they exist. The routine ticks tasks here and writes the story in [DAYLOG.md](DAYLOG.md).

## servellm (project 1)
- [x] Scaffold, CONCEPTS.md, launcher, client, metrics, sweep, plots, notebook (2026-10-10)
- [ ] [gpu] Run `notebooks/kaggle_servellm.ipynb` on a T4; commit `results/`; write README Results with the five experiments interpreted against CONCEPTS.md section 9

## tokenbench (project 2)
- [x] Scaffold, CONCEPTS.md, metrics, mockserver, client, load generators, report, CLI, README with mock demo (2026-10-10)
- [ ] [gpu] Run `notebooks/kaggle_tokenbench.ipynb` on a T4; commit `results/`; add the closed-loop cross-check against servellm and the open-loop saturation point to README
- [ ] Add `tokenbench/notebooks/kernel-metadata.json` and `servellm/notebooks/kernel-metadata.json` for `kaggle kernels push` (slug `nomanjafar/<repo>`, gpu, internet)

## kvcalc (project 3)
- [ ] CONCEPTS.md: KV cache math (MHA/GQA/MLA), block allocation in vLLM, why OOMs happen, what `gpu-memory-utilization` really controls
- [ ] Calculator: parse HF `config.json` (from a local file or `huggingface_hub` download), compute bytes/token, max tokens and max concurrency for VRAM + utilisation + max-model-len; comparison table for Llama-3.1-8B, Qwen2.5-7B, Qwen2.5-1.5B, Mistral-7B, DeepSeek-V2-Lite (MLA); tests; CLI
- [ ] Live monitor: poll `/metrics`, print predicted vs actual block usage and running/waiting; mock-server test; README
- [ ] [gpu] Validate prediction vs vLLM's reported KV cache size on the T4 for Qwen2.5-1.5B at two `max-model-len` values; README Results

## fusedkernels (project 7)
- [ ] CONCEPTS.md: GPU memory hierarchy, why fusion matters, Triton programming model (blocks, masks, tl.load/store), softmax and RMSNorm as row-wise reductions
- [ ] Triton softmax forward with tests under `TRITON_INTERPRET=1`; Triton RMSNorm forward with tests; benchmark harness over 6 shapes vs PyTorch eager and `torch.compile`
- [ ] [gpu] Run benchmarks on the T4; README Results with the walkthrough of block sizes and memory traffic

## quantlab (project 5)
- [ ] CONCEPTS.md: weight-only vs activation quantization, GPTQ, AWQ, INT8/FP8, where quality is lost, why T4 can't do FP8
- [ ] Notebook: serve FP16, GPTQ-Int8, AWQ checkpoints of Qwen2.5-1.5B/3B; tokenbench sweep; VRAM from startup log; perplexity on 200 fixed samples and 100 GSM8K exact-match; `quantlab.report` builds the comparison table; tests for the report code
- [ ] [gpu] Run; README Results

## specdec (project 6)
- [ ] CONCEPTS.md: draft/verify, acceptance rate, why it's lossless, when it hurts (batch size, bad drafts), n-gram speculation
- [ ] Notebook + `specdec.analysis`: sweep `num_speculative_tokens` 1–5 with Qwen2.5-0.5B draft / 3B target and n-gram; acceptance rate from metrics; tokenbench at concurrency 1, 4, 16; tests for the analysis
- [ ] [gpu] Run; README Results

## chunkedprefill-lab (project 8)
- [ ] CONCEPTS.md: prefill/decode interference, chunked prefill, `max-num-batched-tokens`, the TTFT vs ITL trade-off
- [ ] Notebook: mixed open-loop load (long-prompt + short interactive via tokenbench), sweep chunk sizes and on/off; analysis + plots; tests
- [ ] [gpu] Run; README Results

## pagedattention-under-pressure (project 9)
- [ ] CONCEPTS.md: block tables, fragmentation, preemption (recompute vs swap), block size trade-offs
- [ ] Notebook: shrink KV cache, drive load, record preemptions/KV usage/waiting/throughput timelines; block size 16 vs 32; swap on/off; annotated timeline plots; tests
- [ ] [gpu] Run; REPORT.md with annotated timelines; README

## prefixrouter (project 4)
- [ ] CONCEPTS.md: automatic prefix caching, hash-based block reuse, why replica affinity matters, consistent hashing
- [ ] Proxy (FastAPI): system-prompt hash → consistent-hash ring → replica; least-loaded fallback above a load threshold; `/metrics`; tests against two mockservers; CLI
- [ ] [gpu] 2×T4 run with `--enable-prefix-caching`: TTFT with vs without affinity, prefix-cache hit rate; README Results

## llmgateway (project 13)
- [ ] CONCEPTS.md: SLOs, rate limiting (token bucket), retries/backoff/jitter, fallback chains, degradation, why TTFT is the right SLO signal
- [ ] Gateway (FastAPI): provider registry, per-tenant token bucket, retries, fallback chain, rolling p95 TTFT per provider with SLO-triggered degradation; tests against mockservers with injected faults; CLI; README

## tokenmeter (project 12)
- [ ] CONCEPTS.md: unit economics of inference, $/M tokens, MFU, how to attribute cost per tenant
- [ ] Proxy middleware → SQLite; price table + GPU $/h → $/M tokens; MFU; single-page HTML dashboard; tests; README
- [ ] [gpu] One real run through the proxy on the T4 to fill the dashboard; README Results

## gpuscaler (project 11)
- [ ] CONCEPTS.md: queue-depth scaling, KEDA model, cold start, warm pools, cost vs latency
- [ ] Controller loop over N mockservers; target-queue-depth policy with cooldown and warm standby; bursty trace replay; plots of replicas/queue/p95/GPU-hours with and without warm pool; KEDA ScaledObject reference manifest; tests; README

## inferchaos (project 14)
- [ ] CONCEPTS.md: SLOs, error budgets, burn rate, multi-window alerts, chaos engineering principles
- [ ] Injectors (slow replica, kill, spike) against llmgateway + mockservers; burn-rate calculator; recovery-time measurement; per-fault timeline report; tests
- [ ] [gpu] Kill a real vLLM process mid-load on the T4 and measure recovery; README Results

## splitserve (project 10)
- [ ] CONCEPTS.md: why disaggregate, KV transfer, DistServe, what a 2-GPU toy can and cannot show
- [ ] [gpu] vLLM disaggregated prefill on 2×T4 (fallback: event-driven simulator); tokenbench sweeps vs monolithic 1×T4; README Results

## serving-benchmarks (project 15)
- [ ] METHODOLOGY.md; run scripts for the three configs (FP16 baseline, AWQ + prefix caching, speculative decoding)
- [ ] [gpu] Run all three; curves, goodput, $/M tokens; README

## Wrap-up
- [ ] Index README: fill the Results column with headline numbers from every project
