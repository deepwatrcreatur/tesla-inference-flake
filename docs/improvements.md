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

## April 2026 retrospective: module ergonomics and CI critique

### What is going well

- **Flake structure is clean and readable.** Outputs are separated cleanly into
  overlays, packages, apps, modules, and templates, which makes the repo easy
  to navigate and extend.
- **Module ergonomics improved in the right place.** Automatic GPU-aware
  package selection in `modules/tesla-inference.nix` lowers user friction for
  the common case where the user knows the Tesla model but does not want to
  hand-pick packages.
- **CI now covers onboarding paths, not just package evaluation.** Template
  initialization checks are a strong addition because they validate the
  first-contact user experience rather than only low-level package attrs.

### Main gaps still worth addressing

1. **The evaluation matrix has a small redundancy.**
   - `.github/workflows/ci.yml` evaluates `ollama-cuda-tesla-p40`
     unconditionally and then evaluates it again inside the `P40` branch of the
     matrix job.
   - This is low-risk but noisy and easy to simplify.

2. **K-series package selection is functionally correct but implicit.**
   - `K20`, `K40`, and `K80` currently fall through to
     `pkgs.ollama-cuda-tesla`.
   - That fallback works, but explicit entries would make the intent clearer to
     future maintainers and reduce ambiguity if the package set grows.

3. **Local-only firewall behavior could be more explicit.**
   - The module currently opens the Ollama TCP port whenever the host is not
     exactly `127.0.0.1` or `::1`.
   - That means values like `localhost` are treated as non-local and may open a
     firewall rule unexpectedly.

4. **The example template is convenient but a bit too permissive.**
   - Example configurations that disable the firewall entirely are easy to
     cargo-cult into real deployments.
   - A safer default is to keep the firewall enabled and open only the required
     port, with comments for temporary lab/debug loosening.

5. **CI coverage should grow by cheap eval coverage, not pretend hardware coverage.**
   - The review suggestion to expand the GPU matrix to every supported model is
     not a good fit if GitHub Actions and nix-ci.com do not provide meaningful
     hardware-backed validation for those GPUs.
   - A better next step is a lightweight “all supported enum values evaluate”
     path, not a misleading full hardware matrix.

6. **Two module follow-ups are worth tracking explicitly.**
   - If `cudaArchitectures` is exposed as a user-facing option, the module
     should either implement it end-to-end or document clearly that it is not
     yet wired into package selection.
   - Legacy Tesla/Kepler users may also benefit from clearer NVIDIA driver
     guidance so older cards do not depend on trial-and-error host driver
     selection.

### Suggested direction (next few PRs)

1. **Clean up the CI evaluation matrix.**
   - Remove the redundant unconditional `ollama-cuda-tesla-p40` evaluation.
   - If more coverage is desired, add a cheap full-enum eval path rather than a
     fake hardware matrix.

2. **Make GPU package selection more explicit.**
   - Add `K20`, `K40`, and `K80` explicitly to the package map even if they all
     resolve to the same package today.
   - This improves readability and future-proofs the module if the package set
     splits later.

3. **Harden local-only host handling.**
   - Treat `localhost` as local-only alongside `127.0.0.1` and `::1`.
   - Consider whether interface-bound local forms should also avoid opening the
     firewall automatically.

4. **Make templates safer by default.**
   - Keep `networking.firewall.enable = true` in examples.
   - Open only the required inference port and document any broader firewall
     disablement as temporary debug/lab behavior.

5. **Add a small amount of early validation.**
   - Consider assertions for obviously invalid or contradictory option
     combinations, especially when users combine custom CUDA architecture
     overrides with package overrides.

6. **Clarify advanced legacy-GPU behavior.**
   - Either wire `cudaArchitectures` into the module behavior or narrow its
     contract so the option is not misleading.
   - Add a small note or follow-up task around recommended NVIDIA driver
     selection for older Tesla/Kepler-era cards.

### Success metrics to track

- Number of CI checks that validate real user entry paths (templates/modules),
  not just package attrs.
- Number of GPU/module regressions caught by cheap eval checks before merge.
- Reduction in example configs that encourage insecure copy-paste defaults.
