# Implement config.cudaCapabilities

Status: `ready`
Suggested branch: `feat/cuda-capabilities-config`
Priority: `medium`

## Goal

Expose and wire up the standard Nixpkgs `config.cudaCapabilities` in the NixOS module.

## Tasks

- [ ] Map the `tesla-inference.gpu` setting to the corresponding Nixpkgs `cudaCapabilities` string (e.g., "6.1" for P40).
- [ ] Set `nixpkgs.config.cudaCapabilities` globally when `tesla-inference.enable` is true.
- [ ] Ensure `nixpkgs.config.cudaSupport = true` is also set.
