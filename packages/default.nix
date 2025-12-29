{ pkgs, lib }:

{
  # Tesla-optimized Ollama packages
  ollama-cuda-tesla = pkgs.ollama-cuda-tesla;
  ollama-cuda-tesla-p40 = pkgs.ollama-cuda-tesla-p40;
  ollama-cuda-tesla-pascal = pkgs.ollama-cuda-tesla-pascal;
  ollama-cuda-tesla-maxwell = pkgs.ollama-cuda-tesla-maxwell;

  # Tesla-optimized llama.cpp packages
  llama-cpp-tesla = pkgs.llama-cpp-tesla;
  llama-cpp-tesla-p40 = pkgs.llama-cpp-tesla-p40;
  llama-cpp-tesla-pascal = pkgs.llama-cpp-tesla-pascal;
  llama-cpp-tesla-maxwell = pkgs.llama-cpp-tesla-maxwell;

  # Tesla-optimized llama-cpp-python packages
  llama-cpp-python-tesla = pkgs.python3Packages.llama-cpp-python-tesla;
  llama-cpp-python-tesla-p40 = pkgs.python3Packages.llama-cpp-python-tesla-p40;
  llama-cpp-python-tesla-pascal = pkgs.python3Packages.llama-cpp-python-tesla-pascal;
  llama-cpp-python-tesla-maxwell = pkgs.python3Packages.llama-cpp-python-tesla-maxwell;

  # GPU monitoring tools
  gpu-monitoring-tools = pkgs.gpu-monitoring-tools;
  nvtop-tesla = pkgs.nvtop-tesla;
  tesla-gpu-info = pkgs.tesla-gpu-info;

  # Future packages can be added here:
  # tensorrt-tesla = pkgs.tensorrt-tesla;
  # vllm-tesla = pkgs.vllm-tesla;
}