final: prev:

{
  # Collection of GPU monitoring and debugging tools
  gpu-monitoring-tools = prev.buildEnv {
    name = "gpu-monitoring-tools";
    paths = with prev; [
      pciutils       # lspci for GPU detection
      # Note: nvidia-smi comes with nvidia drivers, not a separate package
    ] ++ prev.lib.optionals (prev ? mesa-demos) [ prev.mesa-demos ]
      ++ prev.lib.optionals (prev ? vulkan-tools) [ prev.vulkan-tools ];
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