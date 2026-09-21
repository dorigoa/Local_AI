# Qwen3.8-Flash-Next 177B Q4 sul PC con uso di ssd e memoria

## Scaricare
Controllare il valore di `$HF_HUB_CACHE`; deve puntare ad una storage area capiente (più di 120GB liberi).
```
for i in {1..4}; do hf download hf://unsloth/Qwen3.8-Flash-Next-GGUF/UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-0000$i-of-00004.gguf; done`
```
## Runnare
Usare il chat template in questo repository per usare il modello con Claude Code (è una versione patchata del chat template ufficiale).
```
#M=$HF_HUB_CACHE/models--unsloth--Qwen3.8-Flash-Next-GGUF/snapshots/38bb39ee97821de2c9009abb7e93950eec396e66/UD-Q4_K_XL
M=$(dirname $(find $HF_HUB_CACHE/models--unsloth--Qwen3.8-Flash-Next-GGUF/ -iname *.gguf|grep 00001))
cd ~/src/llama.cpp-cuda
CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=1,0 ./build/bin/llama-server --host 0.0.0.0 --port 8088 \
	-m "$M"/*-00001-of-*.gguf -ngl 99 \
	--n-cpu-moe 35 -ts 4,1 --fit off -fa on \
	-c 131072 -ctk q8_0 -ctv q8_0 \
	-np 1 -b 1024 -ub 512 -t 16 -tb 16 \
	--load-mode none --lazy-mode off \
	--jinja --temp 0.2 --top-k 20 --min-p 0 --top-p 0.95 \
	--chat-template-file ~/qwen3.8-flash-next-177b-chat-template.jinja
```
I parametri `-ngl 99 --n-cpu-moe 35 -ts 4,1 --fit off -fa on -c 131072 -ctk q8_0 -ctv q8_0` sono stati regolati dopo varie iterazioni per funzionare correttamente sul mio PC, AMD Ryzen 9 5950X 16-Core, 96GB RAM DDR4, Nvidia 4060 Ti 16GB + Nvidia 5060 Ti 16GB.

Non si può aumentare il contesto in quanto l'uso della RAM e VRAM sono già al limite.

Se c'e' un cuda out of memory bisogna spostare su RAM più esperti: aumentare il valore di `--n-cpu-moe` e riprovare.

`--lazy-mode off` migliora le prestazioni di un 1-2% perché carica di più in RAM/VARM invece che fare stream da SSD. Se avessi un NVMe molto veloce potrei usare `--lazy-mode off` e osservare le differenze.
