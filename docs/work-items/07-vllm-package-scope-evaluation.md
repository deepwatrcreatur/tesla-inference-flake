# 07 Vllm Package Scope Evaluation

Status: `done`
Suggested branch: `research/vllm-package-scope`
Priority: `medium`

## Goal

Decide whether `tesla-inference-flake` should integrate the nixpkgs `vllm`
package at all, and if so, whether that support belongs only on newer GPUs
rather than the Tesla/P40 path.

## Research Findings

- **Architecture Support**: Nixpkgs `vllm` package evaluations for `sm_61` (P40) and older currently fail due to `cudnn` dependency platform constraints.
- **Hardware Target**: vLLM is effectively Volta+ (SM 7.0) software. Backporting it to Pascal/Maxwell is out of scope for this flake's support model.
- **Detailed Findings**: See [`docs/research/vllm-findings.md`](../research/vllm-findings.md).

## Recommendation

- Do not add `vllm` support to the Tesla/P40 baseline.
- Focus distributed inference efforts on `llama-cpp-python` and `ollama` (distributed via `llama-cpp` / RPC backend).
- Create a new research item for distributed inference options on legacy Tesla hardware.

