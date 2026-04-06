# Optimize Closure Size via cuda-redist

Status: `ready`
Suggested branch: `perf/cuda-redist-optimization`
Priority: `medium`

## Goal

Reduce the multi-gigabyte closure size of inference packages by utilizing granular `cuda-redist` components.

## Tasks

- [ ] Identify large monolithic dependencies in `ollama` and `llama-cpp`.
- [ ] Replace broad `cudatoolkit` imports with specific `cudaPackages.libcublas`, `cudaPackages.libcufft`, etc.
- [ ] Verify that the final package closure size is significantly reduced.
