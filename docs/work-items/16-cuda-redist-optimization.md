# Optimize Closure Size via cuda-redist

Status: `in-progress`
Suggested branch: `perf/cuda-redist-optimization`
Priority: `medium`

## Goal

Reduce the multi-gigabyte closure size of inference packages by utilizing granular `cuda-redist` components.

## Tasks

- [x] Verified that `cudatoolkit` is NOT in the closure; redists are already in use.
- [ ] Investigate removing `openblas` (83 MiB) and `blas` (143 MiB) from `llama-cpp` when CUDA is enabled.
- [ ] Verify that the final package closure size is significantly reduced.
