# 13 llama-cpp-python Distributed Inference

Status: `ready`
Suggested branch: `research/llama-cpp-distributed`
Priority: `medium`

## Goal

Investigate and document the most stable path for distributed inference (multiple nodes) on legacy Tesla (P40/M40) hardware using `llama-cpp-python` or `llama-cpp` directly.

## Context

vLLM has been rejected for this hardware (see Work Item 07). llama.cpp's RPC backend or `llama-cpp-python` with custom build flags are the primary alternatives.

## Tasks

- [ ] Investigate the current status of the `llama-cpp` RPC backend for multi-node inference.
- [ ] Document the required build flags for `llama-cpp-python` to enable distributed backends.
- [ ] Identify any performance bottlenecks or stability issues with distributed llama.cpp on Pascal/Maxwell GPUs.
- [ ] Provide a prototype Nix configuration or script to launch a multi-node inference cluster using this flake's overlays.

## Validation

- A written recommendation on the preferred distributed inference stack for P40.
- Documentation or examples on how to set up multi-node inference with this flake.
