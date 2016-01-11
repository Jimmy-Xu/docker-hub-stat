#!/bin/bash

WORKER_CNT=50
PAGE_SIZE=100
RLT_BASE="list_result"
CFG_DIR="etc"
mkdir -p ${CFG_DIR}

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
  echo -e "${_COLOR}[ $1 ] $2 ${WHITE}"
}

function get_official_images(){
  _URL=$1
  _OUT_DIR=${CFG_DIR}/official
  _RLT_FILE=${CFG_DIR}/official.txt
  mkdir -p ${_OUT_DIR}
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
  _OUT_FILE=${_OUT_DIR}/${_p}.json
  NEED_CURL="true"

  #check old result
  show_message log "check: ${_OUT_FILE}"
  if [ -s ${_OUT_FILE} ];then
    #check json format
    jq . ${_OUT_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ];then
      NEED_CURL="false"
    fi
  fi

  show_message info "NEED_CURL: ${NEED_CURL}"
  if [ "${NEED_CURL}" == "true" ];then
    show_message log "start execute: curl -s ${_URL} "
    curl -s ${_URL} > ${_OUT_FILE}
    #check curl result
    if [ $? -ne 0 ];then
      show_message error "get official-images failed: [${_URL}]"
      exit 1
    fi
  else
    show_message info "page ${_p} of official-images already fetched, skip"
  fi

  #check json format
  jq . ${_OUT_FILE} >/dev/null 2>&1
  if [ $? -ne 0 ];then
    show_message error "json format error: [${_OUT_FILE}]"
    exit 1
  else
    show_message info "page ${_p} of official-images is ok"
  fi
  #check next url
  next_url=$(cat ${_OUT_FILE} | jq .next | xargs -i echo {})
  if [[ "${next_url}" == "null" ]];then
    #final page, process the result
    if [ -f ${_RLT_FILE} ];then
      rm -rf ${_RLT_FILE}
    fi
    for f in ${_OUT_DIR}/*.json
    do
      show_message info "process official-images: $f"
      jq ".results[].name" $f | xargs -i echo library/{} >> ${_RLT_FILE}
    done
    if [ ! -s ${_RLT_FILE} ];then
      show_message error "generate ${_RLT_FILE} failed"
      exit 1
    fi
    show_message succeed "generate official-images list to ${_RLT_FILE}"
  else
    echo $next_url | grep ^https >/dev/null 2>&1
    if [ $? -eq 0 ];then
      #get next page
      get_official_images ${next_url}
    else
      show_message error "> wrong next url: ${next_url}"
      exit 1
    fi
  fi
}

function get_tag() {
  CFG_FILE=${CFG_DIR}/$1.txt
  if [ ! -s ${CFG_FILE} ];then
    show_message error "${CFG_FILE} not found"
    exit 1
  fi
  total=$(cat ${CFG_FILE} |wc -l)
  show_message log "Total images in $1: $total"
  show_message log "==============================================="
  while read REPO
  do
    RLT_DIR="${RLT_BASE}/${REPO}"
    mkdir -p ${RLT_DIR}
    show_message info "--------------- $total: ${REPO} ---------------"

    if [ "${GET_FIRST_PAGE}" == "true" ];then
      show_message info "get first page"
      start_page=1
      num_pages=1
    else
      show_message info "get rest page"
      if [ ! -s ${RLT_DIR}/1.json ];then
        show_message "> failed: ${RLT_DIR}/1.json not found, skip"
        continue
      fi
      start_page=2
      _count=$(jq .count ${RLT_DIR}/1.json)
      num_pages=$(( (_count + PAGE_SIZE - 1) / PAGE_SIZE ))
    fi
    show_message info ">page range: ${start_page} -> ${num_pages}"
    #loop
    for p in $(seq ${start_page} ${num_pages})
    do
      if [ -s ${RLT_DIR}/${p}.json ];then
        jq . ${RLT_DIR}/${p}.json >/dev/null 2>&1
        if [ $? -eq 0 ];then
          show_message "page ${p} already fetched, skip"
          continue
        fi
      fi
      p_cnt=$(ps -ef |grep "list_tag.sh" | grep -v grep | wc -l)
      while [ ${p_cnt} -ge ${WORKER_CNT} ]
      do
        sleep 5
        p_cnt=$(ps -ef |grep "list_tag.sh" | grep -v grep | wc -l)
      done
      show_message log "start execute: ./list.sh ${REPO} ${p}"
      ./list_tag.sh ${REPO} ${p} &
      sleep 1
    done
    total=$((total - 1))
  done < ${CFG_FILE}
}

function show_usage(){
  cat <<EOF
usage: ./run.sh <flag> <option>
<flag>:
  1 official
  2 custom
<option>:
  1 first page
  2 rest_page
eg:
  ./run.sh 1 1 # get 'first page' of 'official' repo tag
  ./run.sh 1 2 # get 'rest page' of 'custom repo' tag
  ./run.sh 2 1 # get 'first page' of 'official' repo tag
  ./run.sh 2 2 # get 'rest page' of 'custom' repo tag
EOF
  exit 1
}


##### main #####
if [ $# -ne 2 ];then
  show_usage
fi

BEGIN=$(date "+%F %T")
#prepare image list
case $1 in
  1)
    IMG_TYPE="official"
    #get official images
    URL="https://hub.docker.com/v2/repositories/library/?page=1&page_size=${PAGE_SIZE}"
    get_official_images ${URL}
    case $2 in
      1) GET_FIRST_PAGE="true";;
      2) GET_FIRST_PAGE="false";;
      *) show_usage;;
    esac
    ;;
  2)
    IMG_TYPE="custom"
    case $2 in
      1) GET_FIRST_PAGE="true";;
      2) GET_FIRST_PAGE="false";;
      *) show_usage;;
    esac
    ;;
  *)
    show_usage
    ;;
esac
get_tag ${IMG_TYPE}
END=$(date "+%F %T")

echo "==================================="
echo "BEGIN: ${BEGIN}"
echo "END: ${END}"
echo "==================================="
