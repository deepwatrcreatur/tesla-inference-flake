# 07 Vllm Package Scope Evaluation

Status: `in-progress`
Suggested branch: `research/vllm-package-scope`
Priority: `medium`

## Goal

Decide whether `tesla-inference-flake` should integrate the nixpkgs `vllm`
package at all, and if so, whether that support belongs only on newer GPUs
rather than the Tesla/P40 path.

## Context

`vllm` already exists in nixpkgs, so the first question is not packaging from
scratch. The harder question is hardware fit.

This flake is currently centered on Tesla-era support through Ollama and
llama.cpp overlays. Upstream vLLM documents a newer CUDA support floor than the
Tesla P40/Pascal path this flake optimizes today, so adding it blindly would
expand the support boundary without evidence.

## Tasks

- [ ] Confirm the current nixpkgs `vllm` package shape, dependencies, and any
  obvious CUDA assumptions.
- [ ] Decide whether `vllm` should be exposed only for newer GPUs (for example
  V100/T4+) instead of being treated as part of the Tesla/P40 baseline.
- [ ] Treat Pascal/Maxwell support as explicit research only: document any
  community patches or forks and whether they are worth carrying.
- [ ] Document whether `llama-cpp-python` remains the more realistic path for
  legacy Tesla distributed inference.

## Non-Goals

- creating a separate flake repo for `vllm`
- promising Tesla P40 support without a successful prototype
- widening the flake's default support claims beyond what current hardware and
  CI can validate

## Validation

- the repo has a written recommendation on whether `vllm` belongs in this flake
- any recommended integration path is explicit about GPU generation boundaries
- legacy Tesla support is either prototyped with evidence or clearly rejected
