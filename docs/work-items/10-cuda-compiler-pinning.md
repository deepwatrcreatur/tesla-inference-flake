# CUDA Compiler Pinning

Status: `ready`
Priority: `medium`
Branch: `refactor/cuda-compiler-pinning-design`

## Goal

Define and validate a safe strategy for pinning the CUDA compiler (nvcc/ptxas)
for Tesla inference workloads without changing behavior for non-Tesla users.

## Why

- Some Tesla targets are sensitive to CUDA toolchain drift, especially
  Pascal-era GPUs.
- Today the overlays rely on whatever `cudaPackages` come from the selected
  channel; there is no explicit compiler pinning.
- A naive switch to `backendStdenv` risks surprising rebuilds and regressions
  across unrelated packages.

## Scope

This item is design + spike only.

- Identify which derivations in this flake actually need a pinned CUDA
  toolchain (likely a subset of `llama-cpp-tesla`, `ollama-cuda`, and any
  modern-gpu examples).
- Propose a dedicated pinned CUDA stdenv or wrapper that is used only by those
  derivations, not globally.
- Outline how CI would exercise the pinned toolchain behind an opt-in feature
  flag.

Out of scope:

- Flipping all CUDA consumers in one shot.
- Changing default behavior for non-Tesla consumers of these overlays.

## Proposed Design

1. **Dedicated pinned CUDA stdenv**

   - Introduce a helper in `lib/` or `overlays/` that constructs a
     `cudaPinnedStdenv` (name to be confirmed) derived from `backendStdenv`
     plus the desired `cudaPackages` set.
   - Keep this helper internal to this flake; do not expose it as a generic
     upstream pattern.
   - Use this stdenv only in explicitly Tesla-facing packages that we validate
     in CI.

2. **Opt-in feature flag**

   - Add a flake option (for example
     `tesla-inference.cuda.enableCompilerPinning = lib.mkEnableOption ...`) or a
     similar configuration knob.
   - Default: `false` — existing behavior, no compiler pinning.
   - When enabled, the affected packages switch to the pinned stdenv for their
     CUDA builds.

3. **CI spike build**

   - Add at least one CI job that builds a representative Tesla target
     (e.g. `.#llama-cpp-tesla` or a P40 example configuration) with
     `enableCompilerPinning = true`.
   - Keep this job non-blocking initially if runtime coverage is limited; treat
     red builds as a signal to revisit the design, not as a default gate for all
     PRs.

## Risks & Mitigations

- **Closure size / rebuild cost**: Pinning via a custom stdenv can increase the
  closure size and rebuild surface.
  - Mitigation: keep the pinned stdenv as narrow as possible and reuse existing
    `cudaPackages` where feasible.
- **Compatibility with future CUDA releases**:
  - Mitigation: document the supported CUDA versions and GPU families for the
    pinned configuration; revisit when upstream drops Pascal support.
- **User surprise**: silently changing the default compiler toolchain could
  break existing consumers.
  - Mitigation: keep pinning behind an explicit opt-in flag until we have
    confidence and clear release notes.

## Validation

- Document which packages are wired to the pinned stdenv and why.
- Add CI coverage for at least one Tesla target using the pinned toolchain.
- Confirm that leaving the flag disabled preserves current builds.

## Outcome

Once this design doc is merged and a minimal CI spike exists (even if
non-blocking), this item can be flipped from `ready` to `in-progress` for the
actual implementation of the pinned stdenv and wiring changes.
