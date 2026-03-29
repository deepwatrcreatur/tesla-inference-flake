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

      modelsDirMode = lib.mkOption {
        type = lib.types.str;
        default = "0770";
        example = "0777";
        description = ''
          File mode used for cfg.ollama.modelsPath and its models/ subdirectory in
          systemd.tmpfiles rules. On shared storage (virtiofs, NFS) you may need
          a more permissive mode like 0777.
        '';
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
    # Note: nixpkgs overlays should be applied by the flake that uses this module.
    # This module expects the tesla-inference overlays to already be available.
    # See the example templates for how to properly apply overlays.

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

    # Ensure parent and models directory exist and have correct ownership.
    # The mode for the Ollama-owned directories is configurable via
    # cfg.ollama.modelsDirMode to better support shared storage backends.
    systemd.tmpfiles.rules = lib.mkIf cfg.ollama.enable [
      "d ${builtins.dirOf cfg.ollama.modelsPath} 0755 root root -"
      "Z ${cfg.ollama.modelsPath} ${cfg.ollama.modelsDirMode} ollama ollama -"
      "Z ${cfg.ollama.modelsPath}/models ${cfg.ollama.modelsDirMode} ollama ollama -"
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