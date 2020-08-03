#!/bin/bash

trap 'echo interrupted; exit' INT

useproxy="noproxy"

function usage() {
  echo "$0 -k activation-key [-h] -s latest|unstable [ -p proxy ]"
}  

while getopts "hs:k:p:" arg; do
  case $arg in
    h)
      usage
      exit 0
      ;;
    s)
      scenario=$OPTARG
      case "$scenario" in
        "latest"|"unstable") 
          echo choosen scenario: $scenario
          ;;
        *) 
          echo scenario $scenario not known
          usage
          exit0
          ;;
      esac
      ;;      
    k)
      activation_key=$OPTARG
      ;;
    p)
      proxy=$OPTARG
      useproxy="proxy"
      ;;
  esac
done

if [ -z "$activation_key" ]; then
  echo ERROR: no activation key defined
  usage
  exit 1
fi

if [ -z "$scenario" ]; then
  echo INFO: no scenario defined using \'latest\'
  scenario="latest"
fi

DATE=$(date +%Y-%m-%d-%H-%M)
mkdir -p ./logs

env_param="OR_ACTIVATION_KEY=$activation_key OR_INSTALLER_VERSION=$scenario OR_DEBUG=2"
if [ -n "$proxy" ]; then
  env_param="$env_param HTTP_PROXY=$proxy HTTPS_PROXY=$proxy"
fi

_ret=0
echo writing results to log file logs/results-$DATE.txt
for os in centos7 oracle7 rhel7; do
  echo install $scenario on $os >> logs/integration-$os-$scenario-$useproxy-$DATE.log
  BASE_OS=$os vagrant destroy -f
  eval $env_param BASE_OS=$os vagrant up >> logs/integration-$os-$scenario-$useproxy-$DATE.log
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo SUCCESS $os-$installer-$DATE | tee -a logs/results-$DATE.txt
  else 
    _ret=1
    echo FAILED $os-$installer-$DATE | tee -a logs/results-$DATE.txt
  fi
done
exit $_ret
