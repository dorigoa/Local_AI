# Qwen3.8-Flash-Next 177B Q4 sul PC con uso di ssd e memoria

## Scaricare

`for i in {1..9}; do hf download hf://AtomicChat/Qwen3.8-Flash-Next-GGUF/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64-0000$i-of-00033.gguf; done; for i in {10..33}; do hf download hf://AtomicChat/Qwen3.8-Flash-Next-GGUF/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64-000$i-of-00033.gguf; done;`

## Fissare clock GPU   
Eseguire lo script:
```
	#!/usr/bin/env bash
	# gpu-clocks.sh — impedisce alle GPU NVIDIA di scalare i clock sotto carico intermittente
	# Uso:  sudo ~/gpu-clocks.sh [min_sm_MHz]   (default 2000)
	#       sudo ~/gpu-clocks.sh reset          (ripristina la gestione automatica)
	set -u
	[ "$(id -u)" -eq 0 ] || { echo "errore: va eseguito con sudo" >&2; exit 1; }
	command -v nvidia-smi >/dev/null 2>&1 || { echo "errore: nvidia-smi non trovato" >&2; exit 1; }
	
	if [ "${1:-}" = "reset" ]; then
	  nvidia-smi -rgc; nvidia-smi -rmc
	  exit 0
	fi
	
	MIN_SM=${1:-2000}
	nvidia-smi -pm 1 || echo "avviso: persistence mode non attivato" >&2
	
	nvidia-smi --query-gpu=index,name,clocks.max.sm,clocks.max.mem --format=csv,noheader,nounits |
	while IFS=',' read -r idx name maxsm maxmem; do
	  idx=${idx// /}; name=${name# }; maxsm=${maxsm// /}; maxmem=${maxmem// /}
	  echo "== GPU $idx ($name): SM ${MIN_SM}-${maxsm} MHz, memoria ${maxmem} MHz"
	  nvidia-smi -i "$idx" -lgc "${MIN_SM},${maxsm}" || echo "   avviso: blocco SM non riuscito" >&2
	  nvidia-smi -i "$idx" -lmc "${maxmem},${maxmem}" || echo "   avviso: blocco memoria non supportato" >&2
	done
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
## Runnare
Usare il chat template in questo repository per usare il modello con Claude Code (è una versione parcata del chat template ufficiale).
```
	M=$HF_HUB_CACHE/models--AtomicChat--Qwen3.8-Flash-Next-GGUF/snapshots/142262902a46f7daed19c79d0771534c8106ad59/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64
	cd ~/src/llama.cpp-cuda
	CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=1,0 ./build/bin/llama-server --host 0.0.0.0 --port 8088 -m "$M"/*-00001-of-*.gguf -ngl 99 --n-cpu-moe 28 -ts 3,1 --fit off -fa on -c 131072 -ctk q8_0 -ctv q8_0 -np 1 -b 1024 -ub 512 -t 16 -tb 16 --load-mode none --lazy-mode off --jinja --temp 0.2 --top-k 20 --min-p 0 --top-p 0.95 --chat-template-file ~/qwen3.8-flash-next-177b-chat-template.jinja
```

Se c'e' un cuda out of memory bisogna spostare su RAM più esperti: aumentare il valore di `--n-cpu-moe` e riprovare.

`--lazy-mode off` migliora le prestazioni di un 1-2% perché carica di più in RAM/VARM invece che fare stream da SSD. Se avessi un NVMe molto veloce potrei usare `--lazy-mode off` e osservare le differenze.
