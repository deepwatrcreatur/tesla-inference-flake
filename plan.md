# Tesla Inference Flake - Development Plan

## Current Status (Jan 3, 2026)

### Completed
- Ollama with P40 GPU working - Using official binaries v0.12.11
- Source builds functional - tesla-inference-flake provides ollama-cuda-tesla-p40 (v0.13.5)
- GPU acceleration confirmed - 33/33 layers offloading to GPU

## Roadmap

### Priority 1: Version Tagging
- [ ] Tag nix-inference-clean as v0.8
- [ ] Commit and push changes

### Priority 2: Dual-Option Architecture
- [ ] Create overlays/ollama-official-binaries.nix
- [ ] Create examples/tesla-p40-binaries/

### Priority 3: Documentation
- [ ] Update README.md

### Priority 4: Testing
- [ ] Test both options on P40
