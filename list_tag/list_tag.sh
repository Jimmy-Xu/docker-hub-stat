#!/bin/bash
#get tag of repos by https://registry.hub.docker.com/v2/repositories/${_REPO}/tags/?page=${_PAGE}&page_size=${PAGE_SIZE}
#fetch single page once

REPO=$1
PAGE=$2
PAGE_SIZE=$3
RLT_BASE="list_result"

#color
WHITE='\033[0m'
YELLOW='\033[0;33m'
RED='\033[0;31;40m'
GREEN='\033[0;32;40m'
BLUE='\033[1;34m'

function show_message(){
  case $1 in
    succeed|ok)  _COLOR=${GREEN};;
    info|done)   _COLOR=${BLUE};;
    warn)        _COLOR=${YELLOW};;
    error|fail)  _COLOR=${RED};;
    log)         _COLOR=${WHITE};;
    *)           _COLOR=${WHITE};;
  esac
  echo -e "[ ${REPO} - ${PAGE} ]${_COLOR}[ $1 ] $2 ${WHITE}"
}

function do_list(){
  _REPO=$1
  _PAGE=$2
  _RLT_DIR="${RLT_BASE}/${REPO}"
  _RLT_FILE=${_RLT_DIR}/${_PAGE}.json
  _URL="https://registry.hub.docker.com/v2/repositories/${_REPO}/tags/?page=${_PAGE}&page_size=${PAGE_SIZE}"

  mkdir -p ${_RLT_DIR}

  NEED_CURL="true"
  if [ -s ${_RLT_FILE} ];then
    jq . ${_RLT_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ];then
      NEED_CURL="false"
    fi
  fi

  show_message log "NEED_CURL: ${NEED_CURL}"
  if [ "${NEED_CURL}" == "true" ];then
    show_message log "URL: ${_URL}"
    show_message log "RLT_FILE: ${_RLT_FILE}"
    #start curl
    curl -s -S "${_URL}"  > ${_RLT_FILE}
    #check curl
    if [ $? -ne 0 ];then
      show_message error " => curl "
    fi
    #check json format
    jq . ${_RLT_FILE} >/dev/null 2>&1
    if [ $? -ne 0 ];then
      show_message error " => failed: not invalid json format: ${_RLT_DIR}/$i.json"
      exit 1
    else
      show_message succeed " => succeed"
    fi
  fi
}

function show_usage(){
  cat <<EOF
usage: ./list.sh <REPO> <PAGE> [PAGE_SIZE]
  <REPO> :      format: namespace/repo_name
  <PAGE> :      >=1 default 1
  <PAGE_SIZE> : >=1 default 100
eg:
  ./list.sh library/ubuntu 1 100
EOF
  exit 1
}


##### main #####
if [ $# -lt 1 ];then
  show_usage
fi

if [ "${PAGE}" == "" ];then
  PAGE=1
fi

if [ "${PAGE_SIZE}" == "" ];then
  PAGE_SIZE=100
fi

#start
BEGIN_TIME=$(date "+%s")
do_list "${REPO}" "${PAGE}"
END_TIME=$(date "+%s")

show_message ok "duration: $((END_TIME - BEGIN_TIME)) seconds"
