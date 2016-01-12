#!/bin/bash

#image name
NAMESPACE="xjimmyshcn"
REPO_NAME="mongo"
IMAGE_TAG="3.2"
IMAGE_NAME=${NAMESPACE}/${REPO_NAME}:${IMAGE_TAG}

#container and image name
CONTAINER_NAME="mongo"

#volume
LOCAL_DB_DIR=`pwd`/db
SRC_DATA_DIR=`pwd`/..

#port
LOCAL_PORT="27017"

############################################################
#ensure image exist
docker images ${IMAGE_NAME} | grep " ${IMAGE_TAG} "
if [ $? -ne 0 ];then
  docker pull ${IMAGE_NAME}
  if [ $? -ne 0 ];then
    echo "pull docker image ${IMAGE_NAME} failed, please try again"
    exit 1
  fi
fi

############################################################
#build image
docker build -t ${IMAGE_NAME} .

############################################################
#ensure old container not exist
docker ps -a | grep " mongo$"
if [ $? -eq 0 ];then
  docker rm -f ${CONTAINER_NAME}
fi

############################################################
#ensure db dir exist
if [ ! -d ${LOCAL_DB_DIR} ];then
  mkdir -p ${LOCAL_DB_DIR}
fi

############################################################
#start new container
docker run --name ${CONTAINER_NAME} -d -p ${LOCAL_PORT}:27017 -v ${LOCAL_DB_DIR}:/data/db/ -v ${SRC_DATA_DIR}:/data/source ${IMAGE_NAME}

cat <<EOF

-------------------------------------------
to enter container:
  docker exec -it ${CONTAINER_NAME} /bin/bash

to import search_repo result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/search_repo;./import_result.py"

to import list_repo result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/list_repo;./import_result.py --data_dir=20160111"

to import list_tag result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/list_tag;./import_result.py"

EOF
