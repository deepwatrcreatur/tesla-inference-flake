{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.gpu-monitoring;
in
{
  options.services.gpu-monitoring = {
    enable = lib.mkEnableOption "GPU monitoring tools for Tesla GPUs";

    tools = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        gpu-monitoring-tools
        nvtop-tesla
        tesla-gpu-info
      ];
      description = "GPU monitoring packages to install";
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

    monitoringInterval = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Interval for GPU monitoring service";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install monitoring tools
    environment.systemPackages = cfg.tools;

    # Add shell aliases for all shells
    programs.bash.shellAliases = cfg.aliases;
    programs.zsh.shellAliases = cfg.aliases;
    programs.fish.shellAliases = cfg.aliases;

    # Optional systemd monitoring service
    systemd.services.gpu-monitor = lib.mkIf cfg.enableSystemdService {
      description = "GPU Monitoring Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.tesla-gpu-info}/bin/tesla-gpu-info";
        User = "nobody";
        Group = "nogroup";
      };
    };

    systemd.timers.gpu-monitor = lib.mkIf cfg.enableSystemdService {
      description = "GPU Monitoring Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.monitoringInterval;
        OnUnitActiveSec = cfg.monitoringInterval;
        Persistent = true;
      };
    };

    # Ensure users can access GPU devices
    users.groups.video = {};
  };
}