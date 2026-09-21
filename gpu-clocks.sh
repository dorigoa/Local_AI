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
