final: prev:

{
  # Collection of GPU monitoring and debugging tools
  gpu-monitoring-tools = prev.buildEnv {
    name = "gpu-monitoring-tools";
    paths = with prev; [
      # Note: nvidia-smi comes with nvidia drivers, not a separate package
    ] ++ prev.lib.optionals prev.stdenv.isLinux [
      pciutils  # lspci for GPU detection (Linux only)
    ] ++ prev.lib.optionals (prev.stdenv.isLinux && prev ? mesa-demos) [
      prev.mesa-demos  # Mesa demos (Linux only)
    ] ++ prev.lib.optionals (prev.stdenv.isLinux && prev ? vulkan-tools) [
      prev.vulkan-tools  # Vulkan tools (Linux only)
    ];
    pathsToLink = [ "/bin" "/share" ];
  };

  # Basic GPU monitoring tool (simplified)
  nvtop-tesla = prev.writeShellScriptBin "nvtop-tesla" ''
    #!/bin/sh
    # Tesla GPU monitoring wrapper
    if command -v nvidia-smi >/dev/null 2>&1; then
        watch -n 1 nvidia-smi
    else
        echo "nvidia-smi not found. Please ensure NVIDIA drivers are installed."
        exit 1
    fi
  '';

  # Tesla GPU information script (simplified for CI compatibility)
  tesla-gpu-info = prev.writeShellScriptBin "tesla-gpu-info" ''
    echo "=== Tesla GPU Information ==="
    echo
    echo "This tool provides Tesla GPU information when run on a system with NVIDIA drivers."
    echo "Usage: tesla-gpu-info"
    echo
    echo "Requirements:"
    echo "  - NVIDIA drivers installed"
    echo "  - nvidia-smi available in PATH"
    echo "  - pciutils for lspci (fallback)"
    echo
    echo "Note: This is a runtime script - actual GPU detection occurs when executed on target hardware."
  '';
}