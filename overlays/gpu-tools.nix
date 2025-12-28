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

  # Tesla GPU information script
  tesla-gpu-info = prev.writeShellScriptBin "tesla-gpu-info" ''
    #!/bin/sh
    set -e

    echo "=== Tesla GPU Information ==="
    echo

    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA GPUs detected:"
        nvidia-smi --query-gpu=index,name,compute_cap,memory.total,driver_version --format=csv,noheader,nounits
        echo

        echo "CUDA Compute Capabilities:"
        nvidia-smi --query-gpu=index,name,compute_cap --format=csv,noheader | while IFS=, read idx name compute; do
            compute=$(echo $compute | tr -d ' ')
            case $compute in
                3.5) echo "  GPU $idx ($name): Compute $compute (Kepler - K20, K40)";;
                3.7) echo "  GPU $idx ($name): Compute $compute (Kepler - K80)";;
                5.2) echo "  GPU $idx ($name): Compute $compute (Maxwell - M40, M60)";;
                6.0) echo "  GPU $idx ($name): Compute $compute (Pascal - P100)";;
                6.1) echo "  GPU $idx ($name): Compute $compute (Pascal - P40)";;
                *) echo "  GPU $idx ($name): Compute $compute (Unknown/Modern)";;
            esac
        done
    else
        echo "nvidia-smi not found. Falling back to lspci..."
        lspci | grep -i nvidia | grep -i tesla || echo "No Tesla GPUs found via lspci"
    fi

    echo
    echo "=== System Information ==="
    echo "CUDA Version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)"
    echo "Driver Version: $(cat /proc/driver/nvidia/version 2>/dev/null | head -1 || echo 'Not available')"
  '';
}