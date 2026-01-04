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

``nix
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
``

### Direct Package Installation

**Note**: This flake includes unfree CUDA packages by default.

``bash
# Install Tesla-optimized Ollama
nix profile install github:deepwatrcreatur/tesla-inference-flake#ollama-cuda-tesla-p40

## Installation Options

This flake provides **two approaches** for installing Ollama with Tesla GPU support:

### Option 1: Source Builds (Default) - Tesla-Optimized

Builds Ollama from source with specific CUDA architecture optimizations for your Tesla GPU.

**When to use:**
- Legacy Tesla cards (K20/K40 with compute 3.5, K80 with compute 3.7)
- Maximum performance optimization (10-20% improvement on legacy cards)
- Want to ensure CUDA compatibility with specific driver versions

**Advantages:**
- Tesla-specific CUDA architecture compilation
- Optimized for your exact GPU model
- Full control over build flags
- Better support for older Tesla hardware

**Disadvantages:**
- Longer build time (30-60 minutes on P40)
- Manual updates for new Ollama versions

**Usage:**
\`\`\`nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # Source build (default)
        { nixpkgs.overlays = [ tesla-inference.overlays.ollama-cuda ]; }
        tesla-inference.nixosModules.tesla-inference
      ];
    };
  };
}
\`\`\`

### Option 2: Official Binaries - Fast & Latest

Downloads pre-built Ollama binaries from GitHub releases with bundled CUDA libraries.

**When to use:**
- Modern Tesla cards (P40/P100 with compute 6.0/6.1)
- Want latest Ollama versions quickly
- Proven working configuration
- Minimal setup time

**Advantages:**
- Latest Ollama versions (no wait for rebuilds)
- Fast installation (~2 minutes)
- Official builds with bug fixes
- Minimal maintenance

**Disadvantages:**
- Generic CUDA support (not Tesla-specific)
- Slightly less optimized on legacy cards (~5-10% on K-series)
- Dependent on Ollama maintaining binary releases

**Usage:**
\`\`\`nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # Official binaries
        { nixpkgs.overlays = [ tesla-inference.overlays.ollama-official-binaries ]; }
        tesla-inference.nixosModules.tesla-inference
      ];
    };
  };
}
\`\`\`

### Performance Comparison

| GPU | Source Build | Official Binaries | Difference |
|------|---------------|-------------------|------------|
| P40 (6.1) | Baseline | ~5-10% slower | Minimal |
| P100 (6.0) | Baseline | ~5-10% slower | Minimal |
| M40/M60 (5.2) | Baseline | ~10-15% slower | Moderate |
| K20/K40 (3.5) | Baseline | ~10-20% slower | Significant |
| K80 (3.7) | Baseline | ~15-20% slower | Significant |

*Note: These are estimated differences. Actual performance varies by workload and model.*

### Which to Choose?

**Choose Source Builds if:**
- You have K20/K40/K80 cards
- You want maximum performance
- You can tolerate 30-60 minute builds
- You want to customize CUDA flags

**Choose Official Binaries if:**
- You have P40/P100 or newer
- You want latest Ollama quickly
- You prefer proven configurations
- You want minimal maintenance

## Examples

### Source Build Example (P40)

See \`examples/tesla-p40/\` for complete NixOS configuration.

\`\`\`bash
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40
\`\`\`

### Official Binaries Example (P40)

See \`examples/tesla-p40-binaries/\` for complete NixOS configuration.

\`\`\`bash
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40-binaries
\`\`\`
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
``

### Using Templates

``bash
# Tesla P40 configuration template
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40

# Modern GPU template
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#modern-gpu
``

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

``nix
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
``

### Multi-GPU Configuration

``nix
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
``

## Development

``bash
# Clone and enter development environment
git clone https://github.com/deepwatrcreatur/tesla-inference-flake
cd tesla-inference-flake
nix develop

# Build all packages
nix build .#ollama-cuda-tesla

# Run checks
nix flake check
``

## Integration with Other Flakes

This flake is designed to integrate cleanly with existing NixOS configurations:

``nix
# In your existing flake.nix
{
  inputs.tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";

  # Apply overlays to get Tesla-optimized packages
  nixpkgs.overlays = [ tesla-inference.overlays.ollama-cuda ];

  # Or use the NixOS module for complete setup
  imports = [ tesla-inference.nixosModules.tesla-inference ];
}
``

## FlakeHub

This flake is automatically published to [FlakeHub](https://flakehub.com) on tagged releases:

``bash
# Use via FlakeHub
nix profile install "https://flakehub.com/f/deepwatrcreatur/tesla-inference-flake/*.tar.gz"
``

## Contributing

1. Fork the repository
2. Make changes in a feature branch
3. Ensure `nix flake check` passes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.## Installation Options

This flake provides **two approaches** for installing Ollama with Tesla GPU support:

### Option 1: Source Builds (Default) - Tesla-Optimized

Builds Ollama from source with specific CUDA architecture optimizations for your Tesla GPU.

**When to use:**
- Legacy Tesla cards (K20/K40 with compute 3.5, K80 with compute 3.7)
- Maximum performance optimization (10-20% improvement on legacy cards)
- Want to ensure CUDA compatibility with specific driver versions

**Advantages:**
- Tesla-specific CUDA architecture compilation
- Optimized for your exact GPU model
- Full control over build flags
- Better support for older Tesla hardware

**Disadvantages:**
- Longer build time (30-60 minutes on P40)
- Manual updates for new Ollama versions

**Usage:**
\`\`\`nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # Source build (default)
        { nixpkgs.overlays = [ tesla-inference.overlays.ollama-cuda ]; }
        tesla-inference.nixosModules.tesla-inference
      ];
    };
  };
}
\`\`\`

### Option 2: Official Binaries - Fast & Latest

Downloads pre-built Ollama binaries from GitHub releases with bundled CUDA libraries.

**When to use:**
- Modern Tesla cards (P40/P100 with compute 6.0/6.1)
- Want latest Ollama versions quickly
- Proven working configuration
- Minimal setup time

**Advantages:**
- Latest Ollama versions (no wait for rebuilds)
- Fast installation (~2 minutes)
- Official builds with bug fixes
- Minimal maintenance

**Disadvantages:**
- Generic CUDA support (not Tesla-specific)
- Slightly less optimized on legacy cards (~5-10% on K-series)
- Dependent on Ollama maintaining binary releases

**Usage:**
\`\`\`nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tesla-inference.url = "github:deepwatrcreatur/tesla-inference-flake";
  };

  outputs = { nixpkgs, tesla-inference, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # Official binaries
        { nixpkgs.overlays = [ tesla-inference.overlays.ollama-official-binaries ]; }
        tesla-inference.nixosModules.tesla-inference
      ];
    };
  };
}
\`\`\`

### Performance Comparison

| GPU | Source Build | Official Binaries | Difference |
|------|---------------|-------------------|------------|
| P40 (6.1) | Baseline | ~5-10% slower | Minimal |
| P100 (6.0) | Baseline | ~5-10% slower | Minimal |
| M40/M60 (5.2) | Baseline | ~10-15% slower | Moderate |
| K20/K40 (3.5) | Baseline | ~10-20% slower | Significant |
| K80 (3.7) | Baseline | ~15-20% slower | Significant |

*Note: These are estimated differences. Actual performance varies by workload and model.*

### Which to Choose?

**Choose Source Builds if:**
- You have K20/K40/K80 cards
- You want maximum performance
- You can tolerate 30-60 minute builds
- You want to customize CUDA flags

**Choose Official Binaries if:**
- You have P40/P100 or newer
- You want latest Ollama quickly
- You prefer proven configurations
- You want minimal maintenance

## Examples

### Source Build Example (P40)

See \`examples/tesla-p40/\` for complete NixOS configuration.

\`\`\`bash
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40
\`\`\`

### Official Binaries Example (P40)

See \`examples/tesla-p40-binaries/\` for complete NixOS configuration.

\`\`\`bash
nix flake init -t github:deepwatrcreatur/tesla-inference-flake#tesla-p40-binaries
\`\`\`
