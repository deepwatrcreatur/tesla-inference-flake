# tesla-inference-flake: Recent Improvements

## 1. Added `tesla-p40-binaries` template and package
- **Change**: Exported a new flake template `tesla-p40-binaries` in `flake.nix`.
- **Change**: Exposed `ollama-official-binaries` as a top-level package in `packages/default.nix`.
- **Path**: `templates.tesla-p40-binaries` → `examples/tesla-p40-binaries`.
- **Impact**: Makes the official-binaries P40 example and package discoverable via flake outputs (e.g. `nix flake show`, `nix profile install`), and ensures CI checks can evaluate the package.

## 2. CI now validates all templates
- **Change**: GitHub Actions `ci.yml` now instantiates and runs `nix flake check` for both `tesla-p40` and `tesla-p40-binaries` templates.
- **Impact**: Prevents template regressions and keeps examples in sync with the flake outputs.

## 3. Cleaned up P40 binaries example
- **Change**: Removed an incorrect `boot.kernelParams` stub from `examples/tesla-p40-binaries/flake.nix`.
- **Reason**: The previous example suggested P40-specific kernel parameters that were not accurate and could cause confusion.
- **Impact**: Safer, more portable template; host-specific kernel parameters can be added by operators as needed.

## 4. Future candidates
- Add tests that exercise NixOS modules (`tesla-inference`, `ollama-cuda-service`, `gpu-monitoring`).
- Extend CI to evaluate overlays on more systems and capture build-time metadata (e.g., supported architectures).
- Document recommended NixOS options for multi-GPU Tesla setups in `docs/`.