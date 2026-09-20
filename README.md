# Generale
## Fissare clock GPU   
Eseguire lo script allo scopo di impedire un throttling dei GPU clocks:
```
source gpu-clocks.sh
```
## Buildare llama.cpp con CUDA
```
mkdir -p ~/src && cd ~/src
git clone --depth 1 https://github.com/ggml-org/llama.cpp llama.cpp-cuda
cd llama.cpp-cuda
cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_COMPILER=/usr/local/cuda-13.1/bin/nvcc
cmake --build build --config Release -j 16 --target llama-server llama-bench
./build/bin/llama-server --list-devices
```
## Controllo utilizzo memoria su Nvidia
```
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv
```
