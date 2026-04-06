# Compiler Pinning via backendStdenv

Status: `ready`
Suggested branch: `fix/cuda-compiler-pinning`
Priority: `low`

## Goal

Improve build stability for legacy Tesla architectures by pinning specific stable GCC versions for CUDA kernels.

## Tasks

- [ ] Investigate optimal GCC versions for Pascal (6.1) and Maxwell (5.2) architectures.
- [ ] Implement `cudaPackages.backendStdenv` override in the overlays.
- [ ] Ensure this resolves any "device lost" or runtime glitches caused by modern GCC/CUDA kernel incompatibilities.
