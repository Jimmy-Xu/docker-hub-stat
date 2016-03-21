#!/bin/bash

MAX_NPROC=20
DELAY_SEC=1

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

function start_container(){
  IMAGE_NAME="xjimmyshcn/imagelayers"
  CONTAINER_NAME="imagelayers"

  echo
  echo "build image: ${IMAGE_NAME}"
  docker build -t ${IMAGE_NAME} .

  echo
  echo "run container: ${CONTAINER_NAME}"
  docker ps -a | grep ${CONTAINER_NAME} >/dev/null 2>&1
  if [ $? -ne 0 ];then
    docker run -d -p 8008:8888 --name ${CONTAINER_NAME} ${IMAGE_NAME} go run main.go
    if [ $? -eq 0 ];then
      echo "container ${CONTAINER_NAME} is running"
    fi
  else
    echo "container ${CONTAINER_NAME} has already running"
  fi
  echo "---------------------------------------------------------------------------------------------------------------------------------------------------"
  docker ps | grep imagelayer
  echo "---------------------------------------------------------------------------------------------------------------------------------------------------"
cat <<EOF

To use imagelayers api(example):

  //get image tag
  curl -s http://127.0.0.1:8008/registry/images/busybox/tags

  //get image layer
  curl -s -XPOST -d '{"repos":[{"name":"busybox","tag":"1.24"}]}' http://127.0.0.1:8008/registry/analyze

EOF

}

function inc_job_result(){
  #echo "[inc_job_result] inc $1 to ${Pfifo}.$1"
  case $1 in
    success)
      read -u7 CNT
      CNT=$((CNT+1))
      echo ${CNT} >&7
      ;;
    fail)
      read -u8 CNT
      CNT=$((CNT+1))
      echo ${CNT} >&8
      ;;
    *)
      echo "unknow job result"
      exit 1
  esac
}

function get_tag(){
  if [ ! -s etc/image.lst ];then
    echo "please create 'etc/image.lst' first"
    exit 1
  fi

  START_TS=$(date +"%s")
  START_TIME=$(date +"%F %T")

  # generate timestamp of log
  TS=$(date +"%Y%m%dT%H%M%S")

  # prepare pipe(for control concurrent tasks)
  mkdir -p /tmp/imagelayers
  Pfifo="/tmp/imagelayers/$$.fifo"
  mkfifo $Pfifo $Pfifo.counter $Pfifo.success $Pfifo.fail
  # fd4: counter
  exec 4<>$Pfifo.counter
  # fd6: limit concurrent
  exec 6<>$Pfifo #file descriptor(fd could be 0-9, except 0,1,2,5)
  # fd7: success counter
  exec 7<>$Pfifo.success
  # fd8: fail counter
  exec 8<>$Pfifo.fail
  rm -f $Pfifo $Pfifo.success $Pfifo.fail

  #init fd6, fd7, fd8
  for((i=1; i<=$MAX_NPROC; i++));
  do #write blank line as token
    echo
  done >&6 #fd6
  #init sucess counter
  echo 0 >&7
  #init fail counter
  echo 0 >&8
  TOTAL=$(cat etc/image.lst|wc -l )
  echo ${TOTAL} >&4

  # start exec task
  echo ">start batch get tag"
  JOB_TOTAL=0
  while read CURRENT_REPO
  do
    JOB_TOTAL=$((JOB_TOTAL+1))
    #fetch token from pipe(block here if there is no token in pipe)
    read -u6 #fd6
    #update fd4: counter
    read -u4 COUNTER
    COUNTER=$((COUNTER-1))
    echo ${COUNTER} >&4

    {
      #exec job
      _NS=$(echo ${CURRENT_REPO} | awk -F"/" '{print $1}')
      _REPO=$(echo ${CURRENT_REPO} | awk -F"/" '{print $2}')
      RLT_PATH=${WORKDIR}/result/tags/${_NS}
      mkdir -p ${RLT_PATH}

      if [ ! -s ${RLT_PATH}/${_REPO}.json ];then
        EXEC_CMD="curl -s http://127.0.0.1:8008/registry/images/${CURRENT_REPO}/tags -o ${RLT_PATH}/${_REPO}.json"
        echo "[${COUNTER}]: start fetch '${CURRENT_REPO}'"
        eval "${EXEC_CMD}" && {
          echo "Job finished: [${CURRENT_REPO}]"
          inc_job_result "success"
        } || {
          echo "Job failed: [${CURRENT_REPO}]"
          inc_job_result "fail"
        }
        #echo "delay '${DELAY_SEC}' seconds"
        sleep ${DELAY_SEC}
      else
        echo "[${COUNTER}]: '${CURRENT_REPO}' already fetched"
      fi
      #give back token to pipe
      echo >&6 #fd6
    }&
  done < etc/image.lst
  #wait for all task finish
  wait

  # #read counter
  read -u7 JOB_SUCCESS
  read -u8 JOB_FAIL

  #delete file descriptor
  exec 6>&- #fd6
  exec 7>&-
  exec 8>&-

END_TS=$(date +"%s")
END_TIME=$(date +"%F %T")
cat <<EOF
############### Summary ###############
MAX_NPROC : ${MAX_NPROC}
DELAY_SEC : ${DELAY_SEC}
---------------------------------------
START_TIME: ${START_TIME}
END_TIME  : ${END_TIME}
DURATION  : $((END_TS - START_TS)) (seconds)
---------------------------------------
JOB_TOTAL(HOSTS) : ${JOB_TOTAL}
  SUCCESS : ${JOB_SUCCESS}
  FAIL    : ${JOB_FAIL}
#######################################
EOF

}

function get_layer(){
  echo "get layer"
}

function show_usage(){
  cat <<EOF

usage:
  ./run.sh <action>

<action>:
  start_container   #start imagelayer api server container
  get_tag           #get image tag list
  get_layer         #get image layer

EOF
}

echo "done!"

case $1 in
  start_container)
    start_container
    ;;
  get_tag)
    get_tag
    ;;
  get_layer)
    get_layer
    ;;
  *)
    show_usage
    ;;
esac
