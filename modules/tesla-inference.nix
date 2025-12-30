{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.tesla-inference;
in
{
  options.tesla-inference = {
    enable = lib.mkEnableOption "Tesla GPU inference configuration";

    gpu = lib.mkOption {
      type = lib.types.enum [ "K20" "K40" "K80" "M40" "M60" "P40" "P100" ];
      description = "Tesla GPU model to optimize for";
    };

    cudaArchitectures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Custom CUDA compute architectures (overrides gpu setting)";
    };

    ollama = {
      enable = lib.mkEnableOption "Ollama inference service";

      modelsPath = lib.mkOption {
        type = lib.types.str;
        default = "/models/ollama";
        description = "Path where Ollama models are stored";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Port for Ollama service";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for Ollama service";
      };

      environmentVariables = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Additional environment variables for Ollama";
      };
    };

    monitoring = {
      enable = lib.mkEnableOption "GPU monitoring tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Determine CUDA architectures
    nixpkgs.overlays = [
      (final: prev: {
        # Use Tesla-optimized Ollama based on GPU type
        ollama =
          if cfg.gpu == "P40" then final.ollama-cuda-tesla-p40
          else if lib.elem cfg.gpu [ "P40" "P100" ] then final.ollama-cuda-tesla-pascal
          else if lib.elem cfg.gpu [ "M40" "M60" ] then final.ollama-cuda-tesla-maxwell
          else final.ollama-cuda-tesla;
      })
    ];

    # Enable hardware acceleration
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      open = false; # Tesla GPUs need proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Configure Ollama service if enabled
    services.ollama = lib.mkIf cfg.ollama.enable {
      enable = true;
      package = pkgs.ollama;
      host = cfg.ollama.host;
      port = cfg.ollama.port;
      environmentVariables = cfg.ollama.environmentVariables // {
        OLLAMA_HOST = "${cfg.ollama.host}:${toString cfg.ollama.port}";
        OLLAMA_MODELS = "${cfg.ollama.modelsPath}/models";
      };
    };

    # Model storage configuration
    systemd.services.ollama = lib.mkIf cfg.ollama.enable {
      environment.HOME = lib.mkForce cfg.ollama.modelsPath;
      serviceConfig = {
        ReadWritePaths = lib.mkForce [ cfg.ollama.modelsPath ];
        WorkingDirectory = lib.mkForce cfg.ollama.modelsPath;
        StateDirectory = lib.mkForce "";
      };
    };

    # Ensure models directory exists
    systemd.tmpfiles.rules = lib.mkIf cfg.ollama.enable [
      "d ${cfg.ollama.modelsPath} 0755 ollama ollama -"
      "d ${cfg.ollama.modelsPath}/models 0755 ollama ollama -"
    ];

    # Add monitoring tools if enabled
    environment.systemPackages = lib.optionals cfg.monitoring.enable [
      pkgs.gpu-monitoring-tools
      pkgs.tesla-gpu-info
    ];

    # Allow unfree packages (NVIDIA drivers, CUDA)
    nixpkgs.config.allowUnfree = true;
  };
}