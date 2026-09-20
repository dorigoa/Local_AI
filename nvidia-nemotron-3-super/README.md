```
M=/nvme/huggingface/hub/models--unsloth-NVIDIA-Nemotron-3-Super-120B-A12B-GGUF/UD-Q4_K_XL/
```

```
CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=1,0 ./build/bin/llama-server --host 0.0.0.0 --port 8088 \
  -m "$M"/*-00001-of-*.gguf -ngl 99 \
  --n-cpu-moe 78 -ts 4,1 --fit off -fa on \
  -c 524288 -ctk q8_0 -ctv q8_0 \
  -np 1 -b 1024 -ub 512 -t 16 -tb 16 \
  --load-mode none --lazy-mode off \
  --jinja \
  --temp 0.2 --top-k 20 --min-p 0 --top-p 0.95 \
  --chat-template-file ~/nvidia-nemotron-3-super-120B.jinja \
  --spec-type draft-mtp
```

