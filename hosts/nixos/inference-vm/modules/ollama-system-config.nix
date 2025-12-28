{ config, lib, pkgs, ... }:

{
  # Install CUDA Ollama as system package
  environment.systemPackages = [
    # Create a wrapper script for CUDA Ollama
    (pkgs.writeShellScriptBin "ollama" ''
      cd /home/deepwatrcreatur/ollama-flake
      exec nix run .#cuda "$@"
    '')
    # Add open-webui for web interface
    pkgs.open-webui
    # Add oterm for terminal interface
    pkgs.oterm
  ];

  # CUDA Ollama service
  systemd.services.ollama-cuda = {
    description = "Ollama GPU-accelerated inference service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = "ollama";
      Group = "ollama";
      ExecStart = "/home/deepwatrcreatur/ollama-flake/run-service.sh";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "OLLAMA_HOST=0.0.0.0:11434"
        "OLLAMA_MODELS=/var/lib/ollama/models"
      ];
    };

    preStart = ''
      mkdir -p /var/lib/ollama/models
      chown ollama:ollama /var/lib/ollama/models
    '';
  };

  # Open WebUI service
  systemd.services.open-webui = {
    description = "Open WebUI for Ollama";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "ollama-cuda.service" ];
    requires = [ "ollama-cuda.service" ];

    serviceConfig = {
      Type = "simple";
      User = "webui";
      Group = "webui";
      ExecStart = "${pkgs.open-webui}/bin/open-webui serve --host 0.0.0.0 --port 8080";
      Restart = "always";
      RestartSec = "10";
      Environment = [
        "OLLAMA_BASE_URL=http://localhost:11434"
        "WEBUI_SECRET_KEY=tesla-p40-inference"
        "DATA_DIR=/var/lib/webui"
      ];
    };

    preStart = ''
      mkdir -p /var/lib/webui
      chown webui:webui /var/lib/webui
    '';
  };

  # System users
  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    home = "/var/lib/ollama";
    createHome = true;
  };

  users.users.webui = {
    isSystemUser = true;
    group = "webui";
    home = "/var/lib/webui";
    createHome = true;
  };

  users.groups.ollama = {};
  users.groups.webui = {};

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [ 11434 8080 ];

  # Allow unfree packages for open-webui
  nixpkgs.config.allowUnfree = true;
}