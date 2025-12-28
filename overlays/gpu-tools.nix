final: prev:

{
  # Collection of GPU monitoring and debugging tools
  gpu-monitoring-tools = prev.buildEnv {
    name = "gpu-monitoring-tools";
    paths = with prev; [
      nvtop          # GPU process monitor
      nvidia-smi     # NVIDIA system management interface (included with driver)
      pciutils       # lspci for GPU detection
      glxinfo        # OpenGL information (if X11 available)
      vulkan-tools   # Vulkan GPU debugging
    ];
    pathsToLink = [ "/bin" "/share" ];
  };

  # Enhanced nvtop with Tesla GPU optimizations
  nvtop-tesla = prev.nvtop.overrideAttrs (old: {
    # Add Tesla-specific monitoring capabilities
    postInstall = (old.postInstall or "") + ''
      # Add Tesla GPU database for better device naming
      mkdir -p $out/share/nvtop/
      cat > $out/share/nvtop/tesla-devices.conf << 'EOF'
      # Tesla GPU device mappings for better display names
      # This helps nvtop show friendlier names for Tesla cards
      0x1022 = "Tesla K20"
      0x1028 = "Tesla K40"
      0x102A = "Tesla K40"
      0x1024 = "Tesla K80"
      0x17F0 = "Tesla M40"
      0x17F1 = "Tesla M40 24GB"
      0x1B38 = "Tesla P40"
      0x15F0 = "Tesla P100"
      EOF
    '';
  });

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