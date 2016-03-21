#!/bin/bash

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

echo "done!"
