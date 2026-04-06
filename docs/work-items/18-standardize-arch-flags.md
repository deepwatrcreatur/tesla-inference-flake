# Standardize Architecture Flags

Status: `ready`
Suggested branch: `refactor/standardize-arch-flags`
Priority: `low`

## Goal

Replace manual architecture string generation with standard Nixpkgs CUDA helpers.

## Tasks

- [ ] Locate manual `buildArchString` logic in `lib/default.nix`.
- [ ] Refactor to use `cudaPackages.lib.flags.dropDot` and other official helpers.
- [ ] Ensure `-gencode` and `CMAKE_CUDA_ARCHITECTURES` remain consistent with Nixpkgs upstream standards.
