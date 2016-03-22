#!/bin/bash

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

#-----------------------------
function get_tag(){
  ./script/get_tag.sh
}

function get_layer(){
  ./script/get_layer.sh $1
}

function stat_layer_v1(){
  ./script/stat_layer_v1.sh
}

#-----------------------------
function stat_layer_v2(){
  ./script/stat_layer_v2.sh
}


function show_usage(){
  cat <<EOF

usage:
  ./run.sh <action>

<action>:
  -----------------------------------------------------------------------------------
  start_container   # start imagelayer api server container
  -----------------------------------------------------------------------------------
  get_tag           # get image tag list
  -----------------------------------------------------------------------------------
  get_layer_latest  # get layer for image's latest tag(faster)
  get_layer_all     # get layer for image's all tag
  stat_layer_v1     # stat layer of image's tag(result/layers/)
  -----------------------------------------------------------------------------------
  stat_layer_v2     # stat layer of image's tag(script/download-frozen-image-v2.sh)
  -----------------------------------------------------------------------------------
EOF
}

############## main ##############
which jq >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo "please install jq first"
  exit 1
fi

case $1 in
  start_container)
    start_container
    ;;
  get_tag)
    get_tag
    ;;
  get_layer_all)
    get_layer "all"
    ;;
  get_layer_latest)
    get_layer "latest"
    ;;
  stat_layer_v1)
    stat_layer_v1
    ;;
  stat_layer_v2)
    stat_layer_v2
    ;;
  *)
    show_usage
    ;;
esac
