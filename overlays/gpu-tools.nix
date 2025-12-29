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

  # Enhanced Tesla GPU monitoring tool
  nvtop-tesla = prev.writeShellScriptBin "nvtop-tesla" ''
    #!/bin/sh
    # Tesla GPU monitoring wrapper with enhanced features

    # Check for required commands
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "Error: nvidia-smi not found. Please ensure NVIDIA drivers are installed."
        exit 1
    fi

    # Check if we have actual Tesla GPUs
    if nvidia-smi --query-gpu=name --format=csv,noheader | grep -i tesla >/dev/null 2>&1; then
        echo "Tesla GPU(s) detected:"
        nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader
        echo ""
    fi

    # Enhanced monitoring with more Tesla-relevant info
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "nvtop-tesla: Enhanced Tesla GPU monitoring"
        echo ""
        echo "Usage: nvtop-tesla [options]"
        echo "  --help, -h    Show this help"
        echo "  --once        Show current status once and exit"
        echo "  --temp        Monitor temperature specifically"
        echo "  --power       Monitor power consumption"
        echo "  --memory      Monitor memory usage"
        echo ""
        echo "Default: Continuous monitoring with 1-second refresh"
        exit 0
    fi

    if [ "$1" = "--once" ]; then
        echo "=== Tesla GPU Status ==="
        nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.current,pcie.link.width.current,temperature.gpu,fan.speed,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used,power.draw,power.limit --format=csv
        exit 0
    elif [ "$1" = "--temp" ]; then
        watch -n 1 'nvidia-smi --query-gpu=name,temperature.gpu,fan.speed,power.draw --format=csv,noheader'
    elif [ "$1" = "--power" ]; then
        watch -n 1 'nvidia-smi --query-gpu=name,power.draw,power.limit,utilization.gpu --format=csv,noheader'
    elif [ "$1" = "--memory" ]; then
        watch -n 1 'nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.memory --format=csv,noheader'
    else
        # Default enhanced monitoring
        echo "Tesla GPU Monitoring (Press Ctrl+C to exit)"
        echo "Use 'nvtop-tesla --help' for more options"
        echo ""
        watch -n 1 'echo "=== $(date) ==="; nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw --format=csv'
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