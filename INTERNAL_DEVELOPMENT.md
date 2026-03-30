# Internal Development Notes

This document contains notes, pitfalls, and lessons learned during the development of `tesla-inference-flake`.

## Pitfalls & Lessons Learned

### `autoPatchelfHook` and Pre-built Binaries

When working with pre-built binaries, such as the `ollama` binary in the `ollama-official-binaries.nix` overlay, `autoPatchelfHook` can be tricky.

**Pitfall:** `autoPatchelfHook` runs *before* the `installPhase`. If your `installPhase` is what extracts or places the binaries into `$out`, `autoPatchelfHook` won't find any ELF files to patch, and it will fail with a "No paths to patch, stopping" error.

**Lesson Learned:** Instead of relying on `autoPatchelfHook` for pre-built binaries, it's often more reliable to manually patch the binaries in the `installPhase` using `patchelf`. This gives you more control over the RPATH and ensures that the patching happens after the binaries are in their final location.

In the case of `ollama-official-binaries.nix`, the solution was to remove `autoPatchelfHook` from the `nativeBuildInputs` and add `patchelf` to the `buildInputs`. Then, in the `installPhase`, the binary is manually patched:

```nix
installPhase = ''
  mkdir -p $out/bin $out/lib
  cp bin/ollama $out/bin/ollama
  cp -r lib/* $out/lib/

  # Set RPATH to include bundled CUDA libraries and the standard C++ library
  patchelf --set-rpath "${final.stdenv.cc.cc.lib}/lib:$ORIGIN/../lib/ollama/cuda_v12:$ORIGIN/../lib/ollama/cuda_v13:$ORIGIN/..:$ORIGIN" $out/bin/ollama
'';
```

### Multiple Layers of Configuration

When developing flakes that are consumed by other flakes, it's important to be mindful of how they are configured.

**Pitfall:** In the `unified-nix-configuration`, `ollama` was being configured in multiple places:

1.  In `unified-nix-configuration/flake.nix` via overlays.
2.  In `unified-nix-configuration/hosts/nixos/inference-vm/modules/configuration.nix` via a direct override of the `services.ollama.package` attribute.
3.  In `tesla-inference-flake/modules/tesla-inference.nix` via the `services.ollama` options.

This made it very difficult to debug why the `ollama-official-binaries` overlay was not being used. The direct override in `configuration.nix` was taking precedence over the overlay.

**Lesson Learned:** When possible, try to consolidate configuration into a single place. The `tesla-inference` module now exposes a `package` option that defaults to the optimized variant based on the `gpu` selection, making configuration more explicit and easier to debug.

### Update Automation

Ollama releases frequently, and manually updating hashes can be tedious.

- **Solution:** A dedicated update script (`scripts/update-ollama.sh`) is exposed as a flake app (`nix run .#update-ollama`).
- **Safety:** The script verifies asset availability via HTTP HEAD before updating, preventing broken links.
- **CI:** A GitHub Action runs weekly to check for updates and automatically open Pull Requests.
