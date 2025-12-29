# Tesla Inference Flake

A Nix flake providing CUDA-optimized inference tools for Tesla GPUs (K-series, M-series, P-series).

## Features

- **Tesla GPU Support**: Optimized for Tesla K20/K40/K80, M40/M60, P40/P100
- **CUDA Compute Capabilities**: Automatic support for compute 3.5, 3.7, 5.2, 6.0, 6.1
- **Ollama with CUDA**: Pre-built Ollama packages with Tesla-optimized CUDA support
- **GPU Monitoring**: Enhanced monitoring tools with Tesla GPU recognition
- **NixOS Modules**: Complete service configurations for easy deployment

## Quick Start

### Using as a Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        tesla-inference.nixosModules.tesla-inference
        {
          tesla-inference = {
            enable = true;
            gpu = "P40";  # or K80, M40, etc.
            ollama.enable = true;
          };
        }
      ];
    };
  };
}
```

### Direct Package Installation

**Note**: This flake includes unfree CUDA packages by default.

```bash
# Install Tesla-optimized Ollama
nix profile install github:deepwatrcreatur/tesla-inference-flake#ollama-cuda-tesla-p40

# Install Tesla-optimized llama.cpp
nix profile install github:deepwatrcreatur/tesla-inference-flake#llama-cpp-tesla-p40

# Install llama-cpp-python for Tesla P40
nix profile install github:deepwatrcreatur/tesla-inference-flake#llama-cpp-python-tesla-p40

# Enter a shell with Tesla P40-optimized tools
nix shell github:deepwatrcreatur/tesla-inference-flake#ollama-cuda-tesla-p40 \
         github:deepwatrcreatur/tesla-inference-flake#llama-cpp-tesla-p40

# Install GPU monitoring tools
nix profile install github:deepwatrcreatur/tesla-inference-flake#gpu-monitoring-tools

# Enter development environment with CUDA tools
nix develop github:deepwatrcreatur/tesla-inference-flake
```

### Using Templates

```bash
# Tesla P40 configuration template
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40

# Modern GPU template
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#modern-gpu
```

## Supported Tesla GPUs

| GPU Series | Models | Compute Capability | Architecture |
|------------|--------|-------------------|--------------|
| K-series | K20, K40, K80 | 3.5, 3.7 | Kepler |
| M-series | M40, M60 | 5.2 | Maxwell |
| P-series | P40, P100 | 6.0, 6.1 | Pascal |

## Available Packages

### Tesla-Optimized Ollama
- `ollama-cuda-tesla`: Ollama optimized for all Tesla GPUs
- `ollama-cuda-tesla-p40`: Specifically optimized for Tesla P40
- `ollama-cuda-tesla-pascal`: Optimized for Pascal-generation Tesla GPUs
- `ollama-cuda-tesla-maxwell`: Optimized for Maxwell-generation Tesla GPUs

### Tesla-Optimized llama.cpp
- `llama-cpp-tesla`: llama.cpp optimized for all Tesla GPUs
- `llama-cpp-tesla-p40`: Specifically optimized for Tesla P40 (compute 6.1)
- `llama-cpp-tesla-pascal`: Optimized for Pascal-generation Tesla GPUs
- `llama-cpp-tesla-maxwell`: Optimized for Maxwell-generation Tesla GPUs

### Tesla-Optimized llama-cpp-python
- `llama-cpp-python-tesla`: Python bindings optimized for all Tesla GPUs
- `llama-cpp-python-tesla-p40`: Python bindings for Tesla P40
- `llama-cpp-python-tesla-pascal`: Python bindings for Pascal Tesla GPUs
- `llama-cpp-python-tesla-maxwell`: Python bindings for Maxwell Tesla GPUs

### GPU Monitoring Tools
- `tesla-gpu-info`: Tesla GPU information and monitoring tool
- `gpu-monitoring-tools`: Collection of GPU monitoring utilities
- `nvtop-tesla`: Tesla-specific GPU monitoring dashboard

## Configuration Examples

### Tesla P40 Setup

```nix
{
  tesla-inference = {
    enable = true;
    gpu = "P40";

    ollama = {
      enable = true;
      modelsPath = "/models/ollama";
      port = 11434;
    };

    monitoring.enable = true;
  };
}
```

### Multi-GPU Configuration

```nix
{
  tesla-inference = {
    enable = true;

    # Support multiple Tesla GPU generations
    cudaArchitectures = [ "35" "61" ]; # K40 + P40

    ollama = {
      enable = true;
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0,1";
      };
    };
  };
}
```

## Development

```bash
# Clone and enter development environment
git clone https://github.com/deepwatrcreatur/tesla-inference-flake
cd tesla-inference-flake
nix develop

# Build all packages
nix build .#ollama-cuda-tesla

# Run checks
nix flake check
```

## Integration with Other Flakes

This flake is designed to integrate cleanly with existing NixOS configurations:

```nix
# In your existing flake.nix
{
  inputs.tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";

  # Apply overlays to get Tesla-optimized packages
  nixpkgs.overlays = [ tesla-inference.overlays.ollama-cuda ];

  # Or use the NixOS module for complete setup
  imports = [ tesla-inference.nixosModules.tesla-inference ];
}
```

## FlakeHub

This flake is automatically published to [FlakeHub](https://flakehub.com) on tagged releases:

```bash
# Use via FlakeHub
nix profile install "https://flakehub.com/f/deepwatrcreatur/tesla-inference-flake/*.tar.gz"
```

## Contributing

1. Fork the repository
2. Make changes in a feature branch
3. Ensure `nix flake check` passes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.