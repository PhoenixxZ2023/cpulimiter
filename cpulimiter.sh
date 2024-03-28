bash
#!/bin/bash

# Definir o limite de CPU em porcentagem
CPULIMIT_PERCENT=50

# Definir o intervalo de verificação em segundos
INTERVAL=5

while true; do
    # Listar os processos que consomem mais CPU
    PROC=$(ps -eo pcpu,pid --sort=-pcpu | awk 'NR>1 {print $1,$2}')

    # Verificar se há processos consumindo mais do que o limite
    while read -r CPU PID; do
        if (( $(echo "$CPU > $CPULIMIT_PERCENT" | bc -l) )); then
            echo "CPU limit exceed by process $PID. Consuming $CPU %."
            echo "Stopping process $PID."
            
            # Parar o processo usando o comando "kill"
            kill $PID
            echo "Process $PID stopped."
        fi
    done <<< "$PROC"

    # Aguardar o intervalo definido antes de verificar novamente
    sleep $INTERVAL
done
