# Tesla inference flake improvements

## CUDA architecture handling and CI-only builds

The Tesla packages in this flake target older GPUs on purpose:

- `llama-cpp-tesla` and `llama-cpp-python-tesla` build for compute
  capabilities **3.5, 3.7, 5.2, 6.0, 6.1** so K20/K40/K80, Maxwell, and
  Pascal cards all work from a single build.

Some CI environments (notably **nix-ci.com** and GitHub Actions with
**CUDA 12.8**) ship an `nvcc` that no longer supports Kepler
(`compute_35/37`), producing errors like:

> nvcc fatal   : Unsupported gpu architecture 'compute_35'

To keep CI green without dropping Kepler support:

- We pin `CMAKE_CUDA_ARCHITECTURES` / `CUDA_ARCHITECTURES` explicitly to
  the Tesla sets instead of relying on upstream CMake defaults that may
  pick unsupported future architectures (e.g. `compute_121a`).
- We added **CI-only variants** that omit Kepler but keep Maxwell/Pascal:
  - `llama-cpp-tesla-ci`
  - `llama-cpp-python-tesla-ci`

CI jobs on nix-ci.com and GitHub Actions should reference these `*-ci`
packages when they must pass with the CUDA 12.8 toolchain. Real
deployments that need K-series GPUs should continue to use the full
`llama-cpp-tesla` / `llama-cpp-python-tesla` attributes.

