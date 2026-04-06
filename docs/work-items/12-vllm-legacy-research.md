# Research: vLLM on Pascal/Maxwell (sm_61/sm_52)

Status: `done`
Suggested branch: `research/vllm-legacy-support`
Priority: `medium`

## Goal

Investigate the feasibility of running vLLM on legacy Tesla hardware (P40/M40), which is officially unsupported (requires sm_70+).

## Context

vLLM is the optimal engine for the "2+1" distributed inference strategy, but it relies on modern CUDA kernels that assume Volta+ hardware.

## Tasks

- [x] Identify community patches or forks that enable vLLM on Pascal (sm_61).
- [x] Determine which features (e.g., Flash Attention) must be disabled or replaced with fallbacks.
- [x] Document if `llama-cpp-python` is a more viable alternative for distributed inference on this specific hardware.

## Findings

- Upstream vLLM requires Volta-or-newer GPUs (SM ≥ 7.0). Pascal (P40, sm_61) and Maxwell (M40, sm_52) are not supported.
- Community forks (for example, "vllm-pascal" variants) experiment with Pascal support but are not widely maintained or guaranteed stable.
- Some core vLLM optimizations (Flash Attention, newer CUDA graph paths) assume modern architectures and recent CUDA toolchains.

## Constraints

- CUDA 12.x is effectively the last realistic toolkit generation for Pascal/Maxwell; newer releases drop these architectures.
- Relying on unmaintained forks for production inference on P40/M40 would be fragile and hard to support long-term.

## Recommendation

For Tesla P40/M40 in the 2+1 strategy, treat vLLM as experimental only. For a stable, supportable path, prefer `llama-cpp-python` (and related CUDA builds) as the primary inference stack for this hardware.

## Future work

If we later decide to pursue vLLM on Pascal, create a new work item for an **experimental** `vllm-pascal` overlay that:

- Pins a known-good Pascal-capable fork and CUDA version,
- Disables unsupported features (like Flash Attention) when needed,
- Is clearly marked as "best effort" and non-production by default.
