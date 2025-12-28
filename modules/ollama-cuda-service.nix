{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ollama-cuda;
in
{
  options.services.ollama-cuda = {
    enable = lib.mkEnableOption "Ollama service with CUDA acceleration for Tesla GPUs";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ollama-cuda-tesla;
      description = "Ollama package to use";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port to listen on";
    };

    modelsPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ollama";
      description = "Directory to store models";
    };

    environmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Environment variables for the service";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "ollama";
      description = "User account under which ollama runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "ollama";
      description = "Group account under which ollama runs";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.modelsPath;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.services.ollama-cuda = {
      description = "Ollama CUDA Service for Tesla GPUs";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = cfg.environmentVariables // {
        OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        OLLAMA_MODELS = cfg.modelsPath;
        HOME = cfg.modelsPath;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/ollama serve";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.modelsPath;
        StateDirectory = "ollama";
        StateDirectoryMode = "0755";
        Restart = "always";
        RestartSec = 3;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.modelsPath ];

        # GPU access
        SupplementaryGroups = [ "video" ];
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-modeset rw"
          "/dev/nvidiactl rw"
        ];
      };
    };

    # Ensure models directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.modelsPath} 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Open firewall port if needed
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.host != "127.0.0.1") [ cfg.port ];
  };
}