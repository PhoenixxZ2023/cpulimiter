#!/bin/bash

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

  cpulimit --pid $pid --limit $limite_cpu >/dev/null 2>&1 &
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

  kill -15 $pid >/dev/null 2>&1
  echo "cpulimit desativado para o processo com PID $pid."
}

# Função para identificar e parar processos que estão consumindo muita CPU
parar_processos_cpu_alta() {
  echo "Digite o limite percentual de uso da CPU para identificar os processos (0-100):"
  read limite_cpu
  if [ $limite_cpu -lt 0 ] || [ $limite_cpu -gt 100 ]; then
    echo "O limite percentual deve estar entre 0 e 100."
    return
  fi

  processos_alta_cpu=$(ps aux --sort=-%cpu | awk -v lim=$limite_cpu '$3 >= lim {print $2}')
  if [ -z "$processos_alta_cpu" ]; then
    echo "Não foram encontrados processos com uso de CPU acima de $limite_cpu%."
    return
  fi

  echo "Processos com uso de CPU acima de $limite_cpu%:"
  echo "$processos_alta_cpu"

  processos_parar=$(echo "$processos_alta_cpu" | grep -E "processo1|processo2|processo3") # Adicione aqui os nomes dos processos que deseja parar

  if [ -z "$processos_parar" ]; then
    echo "Não há processos específicos para parar."
    return
  fi

  echo "Deseja encerrar esses processos? (s/n)"
  read resposta
  if [ "$resposta" = "s" ]; then
    echo "Encerrando processos..."
    kill -15 $processos_parar >/dev/null 2>&1
    echo "Processos encerrados."
  else
    echo "Operação cancelada."
  fi
}

# Loop principal do menu
while true; do
  echo "Menu:"
  echo "1. Ativar cpulimit"
  echo "2. Desativar cpulimit"
  echo "3. Identificar e parar processos com alto uso de CPU"
  echo "4. Sair"
  read -p "Escolha uma opção: " opcao
  case $opcao in
    1) ativar_cpulimit ;;
    2) desativar_cpulimit ;;
    3) parar_processos_cpu_alta ;;
    4) exit ;;
    *) echo "Opção inválida. Tente novamente." ;;
  esac
done
