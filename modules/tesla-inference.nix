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

      package = lib.mkOption {
        type = lib.types.package;
        default =
          let
            packageMap = {
              "P40" = pkgs.ollama-cuda-tesla-p40;
              "P100" = pkgs.ollama-cuda-tesla-pascal;
              "M40" = pkgs.ollama-cuda-tesla-maxwell;
              "M60" = pkgs.ollama-cuda-tesla-maxwell;
            };
          in
          packageMap.${cfg.gpu} or pkgs.ollama-cuda-tesla;
        defaultText = lib.literalMD ''
          GPU-specific package selected based on `gpu`:
          - `P40` → `pkgs.ollama-cuda-tesla-p40`
          - `P100` → `pkgs.ollama-cuda-tesla-pascal`
          - `M40`/`M60` → `pkgs.ollama-cuda-tesla-maxwell`
          - K-series → `pkgs.ollama-cuda-tesla`
        '';
        description = ''
          Ollama package to use. Defaults to a GPU-optimized variant based on the `gpu` setting:
          - P40: `ollama-cuda-tesla-p40`
          - P100: `ollama-cuda-tesla-pascal`
          - M40/M60: `ollama-cuda-tesla-maxwell`
          - K-series (default): `ollama-cuda-tesla`
        '';
      };

      modelsPath = lib.mkOption {
        type = lib.types.str;
        default = "/models/ollama";
        description = "Path where Ollama models are stored";
      };

      modelsDirMode = lib.mkOption {
        type = lib.types.strMatching "^[0-7]{3,4}$";
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

      tools = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gpu-monitoring-tools
          nvtop-tesla
          tesla-gpu-info
        ];
        defaultText = lib.literalExpression "with pkgs; [ gpu-monitoring-tools nvtop-tesla tesla-gpu-info ]";
        description = "GPU monitoring packages to install. Note: the default packages require the flake's overlays to be applied.";
      };

      aliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          gpuinfo = "tesla-gpu-info";
          gputop = "nvtop";
          gpumem = "nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits";
          gpuwatch = "watch -n 1 nvidia-smi";
          gputemp = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
        };
        description = "Shell aliases for GPU monitoring commands";
      };

      enableSystemdService = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable systemd service for periodic GPU monitoring";
      };

      monitoringCommand = lib.mkOption {
        type = lib.types.str;
        default = "${pkgs.tesla-gpu-info}/bin/tesla-gpu-info";
        description = "Command to run for periodic GPU monitoring";
      };

      monitoringInterval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Interval for GPU monitoring service";
      };
    };

    optimizations = {
      enableKernelParams = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Apply recommended kernel parameters for Tesla GPUs.";
      };

      kernelParams = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "nvidia.NVRM=0" ];
        description = "List of kernel parameters to apply when optimizations.enableKernelParams is true.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Note: nixpkgs overlays should be applied by the flake that uses this module.
    # This module expects the tesla-inference overlays to already be available.
    # See the example templates for how to properly apply overlays.

    # Enable hardware acceleration
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    boot.kernelParams = lib.optionals cfg.optimizations.enableKernelParams cfg.optimizations.kernelParams;

    hardware.nvidia = {
      modesetting.enable = true;
      open = false; # Tesla GPUs need proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Configure Ollama service if enabled
    services.ollama = lib.mkIf cfg.ollama.enable {
      enable = true;
      package = cfg.ollama.package;
      host = cfg.ollama.host;
      port = cfg.ollama.port;
      environmentVariables = cfg.ollama.environmentVariables // {
        OLLAMA_HOST = "${cfg.ollama.host}:${toString cfg.ollama.port}";
        OLLAMA_MODELS = "${cfg.ollama.modelsPath}/models";
      };
    };

    # Open firewall port if needed (check IPv4, IPv6, and hostname loopback forms)
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.ollama.enable && !(lib.elem cfg.ollama.host [ "127.0.0.1" "::1" "localhost" ])) [ cfg.ollama.port ];

    # Model storage configuration
    systemd.services.ollama = lib.mkIf cfg.ollama.enable {
      environment.HOME = lib.mkForce cfg.ollama.modelsPath;
      serviceConfig = {
        ReadWritePaths = lib.mkForce [ cfg.ollama.modelsPath ];
        WorkingDirectory = lib.mkForce cfg.ollama.modelsPath;
        StateDirectory = lib.mkForce "";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;

        # GPU access
        SupplementaryGroups = [ "video" ];
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/nvidia* rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-modeset rw"
        ];
      };
    };

    # Ensure parent and models directory exist and have correct ownership.
    # The mode for the Ollama-owned directories is configurable via
    # cfg.ollama.modelsDirMode to better support shared storage backends.
    systemd.tmpfiles.rules = lib.mkIf cfg.ollama.enable [
      "d ${builtins.dirOf cfg.ollama.modelsPath} 0755 root root -"
      "d ${cfg.ollama.modelsPath} ${cfg.ollama.modelsDirMode} ollama ollama -"
      "d ${cfg.ollama.modelsPath}/models ${cfg.ollama.modelsDirMode} ollama ollama -"
    ];

    # Add monitoring tools if enabled
    environment.systemPackages = lib.optionals cfg.monitoring.enable cfg.monitoring.tools;

    # Add shell aliases if monitoring is enabled
    programs.bash.shellAliases = lib.mkIf cfg.monitoring.enable cfg.monitoring.aliases;
    programs.zsh.shellAliases = lib.mkIf cfg.monitoring.enable cfg.monitoring.aliases;
    programs.fish.shellAliases = lib.mkIf cfg.monitoring.enable cfg.monitoring.aliases;

    # Optional systemd monitoring service
    systemd.services.gpu-monitor = lib.mkIf (cfg.monitoring.enable && cfg.monitoring.enableSystemdService) {
      description = "GPU Monitoring Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cfg.monitoring.monitoringCommand;
        # Use nobody for unprivileged run, but grant video group access for GPU metrics
        User = "nobody";
        Group = "video";
        # Grant GPU device access
        DeviceAllow = [
          "/dev/nvidia* r"
          "/dev/nvidiactl r"
          "/dev/nvidia-uvm r"
        ];
      };
    };

    systemd.timers.gpu-monitor = lib.mkIf (cfg.monitoring.enable && cfg.monitoring.enableSystemdService) {
      description = "GPU Monitoring Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.monitoring.monitoringInterval;
        OnUnitActiveSec = cfg.monitoring.monitoringInterval;
        Persistent = true;
      };
    };

    # Ensure video group exists for GPU access
    users.groups.video = {};

    # Allow unfree packages (NVIDIA drivers, CUDA)
    nixpkgs.config.allowUnfree = true;
  };
}