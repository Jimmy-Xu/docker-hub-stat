#!/bin/bash
# list repo by https://hub.docker.com/v2/repositories/${NAMESPACE}/?page_size=${PAGE_SIZE}&page=1

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
  echo -e "[ ${NAMESPACE} - ${NO} ]:${_COLOR}[ $1 ] $2 ${WHITE}"
}

function do_list(){
    _URL=$1
    _p=$( echo ${_URL} | awk -F"?" '{print $NF}' | awk -F"&" '
      {
        for(i=1;i<=NF;i++){
          split($i,ary,"=");
          if (ary[1]=="page"){
            print ary[2]
          }
        }
      }
      ')
    _OUT_FILE=${OUT_DIR}/${_p}.json

    NEED_CURL=true
    if [ -s ${_OUT_FILE} ];then
      jq . ${OUT_FILE} >/dev/null 2>&1
      if [ $? -eq 0 ];then
        show_message info "page ${_p} already pulled"
        NEED_CURL=false
      fi
    fi

    if [ ${NEED_CURL} == "true" ];then
      show_message log "_URL:     ${_URL}"
      show_message log "OUT_FILE: ${_OUT_FILE}"
      show_message log "page:    ${_p}"

      # query first page
      START_TIME=$(date "+%s")
      curl -sf ${_URL} > ${_OUT_FILE}
      END_TIME=$(date "+%s")
    fi

    jq . ${_OUT_FILE} >/dev/null 2>&1
    if [ $? -ne 0 ];then
      show_message error  ">: fetch page ${_p} failed, result not json format: ${_OUT_FILE}"
    else
      show_message succeed ">: fetch page ${_p} ok"
    fi
    show_message done ">>duration: $(( END_TIME - START_TIME )) seconds"

    #check next page
    next_url=$(cat ${_OUT_FILE} | jq .next | xargs -i echo {})
    if [[ "${next_url}" == "null" ]];then
      show_message done "end" | tee > ${OUT_DIR}/end
    else
      echo $next_url | grep ^https
      if [ $? -eq 0 ];then
        #get next page
        do_list ${next_url}
      else
        show_message error ">: wrong next url: ${next_url}"
      fi
    fi
}

##############################

NAMESPACE=$2
NO=$3
PAGE_SIZE=100
p=1

OUT_BASE="./list_result/$1"
OUT_DIR="${OUT_BASE}/${NAMESPACE}"
if [ ! -d ${OUT_DIR} ];then
  mkdir -p ${OUT_DIR}
else
  if [ -f ${OUT_DIR}/end ];then
    echo "already fetched, skip"
    exit 0
  else
    rm -rf ${OUT_DIR}/*
  fi
fi

#start
URL="https://hub.docker.com/v2/repositories/${NAMESPACE}/?page_size=${PAGE_SIZE}&page=1"
do_list $URL
