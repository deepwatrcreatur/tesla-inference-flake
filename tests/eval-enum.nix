{ pkgs, self }:

let
  inherit (pkgs) lib;
  module = self.nixosModules.tesla-inference;
  
  gpuEnum = [ "K20" "K40" "K80" "M40" "M60" "P40" "P100" ];

  evalForGpu = gpu:
    let
      eval = lib.evalModules {
        modules = [
          module
          {
            options = {
              assertions = lib.mkOption {
                type = lib.types.listOf lib.types.attrs;
                default = [ ];
              };
              hardware.graphics.enable = lib.mkOption { type = lib.types.bool; default = false; };
              services.xserver.videoDrivers = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
              boot.kernelParams = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
              boot.kernelPackages = lib.mkOption {
                type = lib.types.attrs;
                default = {
                  nvidiaPackages = {
                    stable = pkgs.hello;
                    production = pkgs.hello // { version = "580.123"; };
                  };
                };
              };
              hardware.nvidia.modesetting.enable = lib.mkOption { type = lib.types.bool; default = false; };
              hardware.nvidia.open = lib.mkOption { type = lib.types.bool; default = false; };
              hardware.nvidia.nvidiaSettings = lib.mkOption { type = lib.types.bool; default = false; };
              hardware.nvidia.package = lib.mkOption { type = lib.types.package; default = pkgs.hello; };
              services.ollama.enable = lib.mkOption { type = lib.types.bool; default = false; };
              services.ollama.package = lib.mkOption { type = lib.types.package; default = pkgs.hello; };
              services.ollama.host = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; };
              services.ollama.port = lib.mkOption { type = lib.types.port; default = 11434; };
              services.ollama.environmentVariables = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
              networking.firewall.allowedTCPPorts = lib.mkOption { type = lib.types.listOf lib.types.port; default = [ ]; };
              systemd.services.ollama.environment.HOME = lib.mkOption { type = lib.types.str; default = ""; };
              systemd.services.ollama.serviceConfig = lib.mkOption { type = lib.types.attrs; default = { }; };
              systemd.tmpfiles.rules = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
              environment.systemPackages = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
              programs.bash.shellAliases = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
              programs.zsh.shellAliases = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
              programs.fish.shellAliases = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
              systemd.services.gpu-monitor = lib.mkOption { type = lib.types.attrs; default = { }; };
              systemd.timers.gpu-monitor = lib.mkOption { type = lib.types.attrs; default = { }; };
              users.groups.video = lib.mkOption { type = lib.types.attrs; default = { }; };
              nixpkgs.config.allowUnfree = lib.mkOption { type = lib.types.bool; default = false; };
            };

            config = {
              _module.args.pkgs = pkgs;
              tesla-inference = {
                enable = true;
                inherit gpu;
                ollama.enable = true;
              };
            };
          }
        ];
      };
    in
      eval.config;

in
  lib.genAttrs gpuEnum (gpu: evalForGpu gpu)
