#!/bin/bash

# Host do servidor remoto
HOST=$(hostname -I | awk '{print $1}')

# Função para ativar cpulimit em um processo
ativar_cpulimit() {
  echo "Digite o PID do processo que deseja limitar:"
  read pid
  if ! ps -p $pid > /dev/null; then
    echo "Processo com PID $pid não encontrado."
    return
  fi

  echo "Digite o limite percentual de uso da CPU para o processo (0-100):"
  read limite_cpu
  if [ $limite_cpu -lt 0 ] || [ $limite_cpu -gt 100 ]; then
    echo "O limite percentual deve estar entre 0 e 100."
    return
  fi

  ssh -t $HOST "echo sua_senha_sudo | sudo -S cpulimit --pid $pid --limit $limite_cpu" >/dev/null 2>&1 &
  echo "cpulimit ativado para o processo com PID $pid com limite de $limite_cpu%."
}

# Função para desativar cpulimit em um processo
desativar_cpulimit() {
  echo "Digite o PID do processo que deseja desativar o cpulimit:"
  read pid
  if ! ps -p $pid > /dev/null; then
    echo "Processo com PID $pid não encontrado."
    return
  fi

  ssh -t $HOST "echo sua_senha_sudo | sudo -S kill -15 $pid" >/dev/null 2>&1
  echo "cpulimit desativado para o processo com PID $pid."
}

# Função para identificar e parar processos que estão consumindo muita CPU
parar_processos_cpu_alta() {
  echo "Identificando processos com uso de CPU em 100%..."
  processos_100_cpu=$(ssh -t $HOST "ps aux --sort=-%cpu" | awk '$3 == 100 {print $2}')
  if [ -z "$processos_100_cpu" ]; then
    echo "Não foram encontrados processos com uso de CPU em 100%."
    return
  fi

  echo "Processos com uso de CPU em 100%:"
  echo "$processos_100_cpu"

  echo "Deseja encerrar esses processos automaticamente? (s/n)"
  read resposta
  if [ "$resposta" = "s" ]; then
    echo "Encerrando processos..."
    for pid in $processos_100_cpu; do
      ssh -t $HOST "echo sua_senha_sudo | sudo -S kill -9 $pid" >/dev/null 2>&1
    done
    echo "Processos encerrados."
  else
    echo "Operação cancelada."
  fi
}

# Função para conceder acesso aos diretórios /usr/bin e /
conceder_acesso() {
  ssh -t $HOST "echo sua_senha_sudo | sudo -S chmod -R 777 /usr/bin /" >/dev/null 2>&1
  echo "Acesso concedido aos diretórios /usr/bin e /."
}

# Loop principal do menu
while true; do
  echo "Menu CPU Limiter:"
  echo
  echo "1. Ativar cpulimit"
  echo "2. Desativar cpulimit"
  echo "3. Identificar e parar processos com alto uso de CPU"
  echo "4. Matar processos com uso de CPU em 100%"
  echo "5. Conceder acesso aos diretórios /usr/bin e /"
  echo "6. Sair"
  read -p "Escolha uma opção: " opcao
  case $opcao in
    1) ativar_cpulimit ;;
    2) desativar_cpulimit ;;
    3) parar_processos_cpu_alta ;;
    4) exit ;;
    5) conceder_acesso ;;
    6) exit ;;
    *) echo "Opção inválida. Tente novamente." ;;
  esac
done
