# Migrate to pkgsForCudaArch

Status: `done`
Suggested branch: `refactor/pkgs-for-cuda-arch`
Priority: `high`

## Goal

Refactor the existing manual overlays to use the Nixpkgs `pkgsForCudaArch` facility.

## Tasks

- [ ] Update `overlays/ollama-cuda.nix` to utilize `prev.pkgsForCudaArch.sm_XX`.
- [ ] Ensure all dependencies (cublas, cudnn) are inherited from the architecture-specific package set.
- [ ] Verify that this simplifies the manual `cmakeFlags` overrides.
