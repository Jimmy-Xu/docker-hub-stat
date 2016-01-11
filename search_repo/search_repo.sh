#!/bin/bash
# search by : curl -s https://index.docker.io/v1/search?q={search_name}}&n=100&page={page}
# get one page each time

###### global #####
PAGE_SIZE=100
PAGE=$1
FLAG=$2
NO=$3

WHITE='\033[0m'
YELLOW='\033[0;33m'
RED='\033[0;31;40m'
GREEN='\033[0;32;40m'
BLUE='\033[1;34m'

###### function ######
function show_usage(){
  cat <<EOF
  usage: ./search.sh <page> <flag>
  <page>: >=1
  eg: ./search.sh 1 00
EOF
  exit 1
}

function show_message(){
  case $1 in
    succeed|ok)  _COLOR=${GREEN};;
    info|done)   _COLOR=${BLUE};;
    warn)        _COLOR=${YELLOW};;
    error|fail)  _COLOR=${RED};;
    log)         _COLOR=${WHITE};;
    *)           _COLOR=${WHITE};;
  esac
  echo -e "[ ${FLAG} - ${NO} ]:${_COLOR}[ $1 ] $2 ${WHITE}"
}

function search_single_PAGE(){
  _PAGE=$1
  _FLAG=$2
  _OUT_DIR="./search_result/${_FLAG}"

  #clean dir
  rm ${_OUT_DIR}/${_PAGE}.* >/dev/null 2>&1

  #parameter
  _OUT_JSON=${_OUT_DIR}/${_PAGE}.json
  _OUT_TXT=${_OUT_DIR}/${_PAGE}.txt
  _URL="https://index.docker.io/v1/search?q=${_FLAG}&n=${PAGE_SIZE}&page=${_PAGE}"

  show_message log  "_URL: curl -s ${_URL} | python -mjson.tool"
  show_message log "_OUT_JSON: ${_OUT_JSON}"
  show_message log "_OUT_TXT: ${_OUT_TXT}"

  #get single page
  curl -s ${_URL} > ${_OUT_JSON}
  if [ $? -ne 0 ];then
    show_message error ">: ${_URL} error"
    #check file size
    if [ ! -s ${_OUT_JSON} ];then
      rm -rf ${_OUT_JSON} >/dev/null 2>&1
    else
      mv ${_OUT_JSON} ${_OUT_JSON}.err
    fi
  else
    #check json format
    jq . ${_OUT_JSON} >/dev/null 2>&1
    if [ $? -ne 0 ];then
      show_message error ">: ${_OUT_JSON} is not json format"
      rm -rf ${_OUT_JSON}
    else
      # convert ${_OUT_JSON} to ${_OUT_TXT}
      jq ".results[].name" ${_OUT_JSON} | xargs -i echo {} > ${_OUT_TXT}
      if [ ! -s ${_OUT_TXT} ];then
        if [ -f ${_OUT_TXT} ];then
          show_message warn ">:  ${_OUT_TXT} is empty"
        else
          show_message fail ">: ${_OUT_TXT} is not exist"
        fi
      else
        show_message succeed ">: generate ${_OUT_TXT} done"
      fi
    fi
  fi
}

####################################
if [ $# -lt 2 ];then
  echo ">missing parameter"
  show_usage
fi

#check $PAGE: should be number
expr $PAGE + 0 >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo ">page should be number"
  show_usage
fi

#ensure dir
OUT_DIR="./search_result/${FLAG}"
mkdir -p ${OUT_DIR}

#start
BEGIN_TIME=$(date "+%s")
search_single_PAGE ${PAGE} ${FLAG}
END_TIME=$(date "+%s")

show_message done "'./search.sh ${PAGE} ${FLAG}' Done. duration: $(( END_TIME - BEGIN_TIME )) seconds"
echo "-----------------------------------------------------"
