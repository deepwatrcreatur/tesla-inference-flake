# Enum Eval Coverage

Status: `done`
Suggested branch: `ci/enum-eval-coverage`
Priority: `medium`

## Goal

Add cheap full-enum evaluation coverage for supported GPU values without
pretending CI provides real hardware-backed validation.

## Implementation

- Added `tests/eval-enum.nix` which evaluates the NixOS module for every GPU in the enum.
- Integrated this as a `checks.enum-eval-coverage` in `flake.nix`.
- Expanded the `evaluation-matrix` in `.github/workflows/ci.yml` to cover all 7 supported GPUs.
- Verified that all architectures evaluate successfully with modern nixpkgs (as of 2026-04-01).
