# Day log

One entry per daily build: what was built, why, the key decision, what was measured, what did not work, and questions for Noman to check his own understanding. Newest at the bottom.

## 2026-10-10 (manual session, not the routine)

**Built:** all 16 repos scaffolded and published; servellm complete except GPU run (launcher, streaming client, metrics scraper, sweep, plots, Kaggle notebook, 26 tests); tokenbench complete except GPU run (metrics, mockserver, closed/open-loop generators, report, CLI, 32 tests, mock demo in README); SCOPE.md locked; daily build routine set up.

**Key decision:** tokenbench ships a mock server so that the control-plane projects (4, 11–14) can be built and tested on a laptop. Trade-off: the mock's ITL does not rise with batch size, so anything about decode saturation still needs a real GPU.

**What did not work:** httpx's in-process `ASGITransport` buffers streamed responses, hiding all timing; timing tests now run the mock in a real uvicorn thread. The permission classifier refused to create GitHub repos from the session; Noman ran `create_repos.sh`.

**Questions for Noman:**
1. For Qwen2.5-1.5B in FP16 on a T4, why can a single stream never exceed roughly 100 tokens/s no matter how fast the GPU computes? (CONCEPTS.md of servellm, section 1.)
2. Why does a closed-loop load test under-report latency during a server stall, and which loop mode finds the saturation point?
3. In the mock demo table, throughput plateaus at concurrency 16 but ITL stays flat. On a real GPU, what would make ITL rise as well, and which `/metrics` series would tell you which of the three causes it was?
