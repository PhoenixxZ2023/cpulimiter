#!/bin/bash

# Define o limite de CPU em porcentagem
CPULIMIT_PERCENT=50

# Define o intervalo de verificação em segundos
INTERVAL=5

# Define o número de verificações consecutivas antes de matar um processo
CONSECUTIVE_CHECKS=3
declare -A PROC_CHECKS

# Função para ativar/desativar o cpulimit
toggle_cpulimit() {
    if [[ "$CPULIMIT_PID" == "" ]]; then
        read -p "Digite o PID do processo para aplicar o cpulimit: " CPULIMIT_PID
        read -p "Digite a porcentagem de limite de CPU para o processo: " CPULIMIT_PERCENTAGE
        cpulimit -p $CPULIMIT_PID -l $CPULIMIT_PERCENTAGE &
        echo "cpulimit aplicado ao PID $CPULIMIT_PID com limite de $CPULIMIT_PERCENTAGE%."
    else
        kill $CPULIMIT_PID
        CPULIMIT_PID=""
        echo "cpulimit desativado."
    fi
}

# Menu principal
while true; do
    echo "Menu:"
    echo "1. Ativar/Desativar cpulimit"
    echo "2. Sair"
    read -p "Escolha uma opção: " choice

    case $choice in
        1)
            toggle_cpulimit
            ;;
        2)
            echo "Saindo do menu."
            break
            ;;
        *)
            echo "Opção inválida."
            ;;
    esac
done

# Loop de verificação de CPU
while true; do
    # Listar os processos que consomem mais CPU
    PROC=$(ps -eo pcpu,pid --sort=-pcpu | awk 'NR>1 {print $1,$2}')

    # Verificar se há processos consumindo mais do que o limite
    while read -r CPU PID; do
        if (( $(echo "$CPU > $CPULIMIT_PERCENT" | bc -l) )); then
            # Incrementar o contador para o processo
            PROC_CHECKS[$PID]=$(( ${PROC_CHECKS[$PID]} + 1 ))
            if (( ${PROC_CHECKS[$PID]} >= $CONSECUTIVE_CHECKS )); then
                echo "Limite de CPU excedido pelo processo $PID. Consumindo $CPU %."
                echo "Parando o processo $PID."
                kill $PID
                echo "Processo $PID parado."
                # Resetar o contador para o processo
                PROC_CHECKS[$PID]=0
            fi
        else
            # Resetar o contador se o processo estiver abaixo do limite
            PROC_CHECKS[$PID]=0
        fi
    done <<< "$PROC"

    # Aguardar o intervalo definido antes de verificar novamente
    sleep $INTERVAL
done
