CUDA_VISIBLE_DEVICES=0 ./llama.cpp/main -c 8192 -n -1 -t 48 -ngl 31 -m models/wizardcoder-python-34b-v1.0.Q6_K.gguf --color -c 4096 --temp 0 --repeat_penalty 1.1 -n -1 -f new_prompt-temp-short.txt
#-c 2048 -n 2048 --rope-scale 2