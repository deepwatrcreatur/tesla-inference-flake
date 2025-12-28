{ pkgs, lib }:

{
  # Tesla-optimized Ollama packages
  ollama-cuda-tesla = pkgs.ollama-cuda-tesla;
  ollama-cuda-tesla-p40 = pkgs.ollama-cuda-tesla-p40;
  ollama-cuda-tesla-pascal = pkgs.ollama-cuda-tesla-pascal;
  ollama-cuda-tesla-maxwell = pkgs.ollama-cuda-tesla-maxwell;

  # GPU monitoring tools
  gpu-monitoring-tools = pkgs.gpu-monitoring-tools;
  nvtop-tesla = pkgs.nvtop-tesla;
  tesla-gpu-info = pkgs.tesla-gpu-info;

  # Future packages can be added here:
  # llama-cpp-cuda-tesla = pkgs.llama-cpp-cuda-tesla;
  # tensorrt-tesla = pkgs.tensorrt-tesla;
}