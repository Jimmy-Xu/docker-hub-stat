#!/bin/bash

#image name
NAMESPACE="xjimmyshcn"
REPO_NAME="mongo"
IMAGE_TAG="3.2"
IMAGE_NAME=${NAMESPACE}/${REPO_NAME}:${IMAGE_TAG}

#container and image name
CONTAINER_NAME="hub-mongo"

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
docker ps -a | grep " ${CONTAINER_NAME}$"
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

[import]
to import search_repo result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/search_repo;./import_result.py"

to import list_repo result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/list_repo;./import_result.py --data_dir=20160111"

to import list_tag result:
  docker exec -it ${CONTAINER_NAME} bash -c "cd /data/source/list_tag;./import_result.py"

[export]
  docker exec -it ${CONTAINER_NAME} bash -c "mongoexport --host 127.0.0.1 --db docker --collection search_repo --fields name,_namespace,_repo_name,is_official,is_trusted,star_count,is_automated --type=csv > /data/source/csv/search_repo.csv"
  docker exec -it ${CONTAINER_NAME} bash -c "mongoexport --host 127.0.0.1 --db docker --collection list_repo --fields _image_name,namespace,name,star_count,pull_count,is_automated,status,last_updated --type=csv > /data/source/csv/list_repo-full.csv"
  docker exec -it ${CONTAINER_NAME} bash -c "mongoexport --host 127.0.0.1 --db docker --collection list_tag --fields _image_name,_namespace,_repo_name,name,full_size,v2 --type=csv > /data/source/csv/list_tag.csv"

[state]
  docker exec -it ${CONTAINER_NAME} bash -c "mongoexport --host 127.0.0.1 --db docker --collection list_repo --fields _image_name,namespace,name,star_count,pull_count,is_automated,status --query '{star_count:{\$gt:0}}' --type=csv > /data/source/csv/list_repo-main.csv"
  docker exec -it ${CONTAINER_NAME} bash
    mongo 127.0.0.1:27017/docker --quiet --eval "DBQuery.shellBatchSize=1000;print('id,count');db.list_repo.aggregate([{'\$group' : {_id:'\$star_count', count:{\$sum:1}}}]).forEach(function(item){print(item._id+','+item.count)})" > data/source/list_repo-stat.csv
    mongo 127.0.0.1:27017/docker --quiet --eval "DBQuery.shellBatchSize=1000;print('id,count');db.list_repo.aggregate([{'\$group' : {_id:'\$namespace', min_last_updated:{\$min:'\$last_updated'}}}]).forEach(function(item){print(item._id+','+item.min_last_updated)})" > data/source/list_repo-namespace.csv
    mongo 127.0.0.1:27017/docker --quiet --eval "DBQuery.shellBatchSize=1000;print('id,count');db.list_repo.aggregate([{'\$group' : {_id:'\$_image_name', min_last_updated:{\$min:'\$last_updated'}}}]).forEach(function(item){print(item._id+','+item.min_last_updated)})" > data/source/list_repo-image_name.csv

[start mongo web ui]
  docker run -it --rm --link ${CONTAINER_NAME}:mongo -p 8000:8081 knickers/mongo-express
  or
  docker run -d -p 8000:80 --link ${CONTAINER_NAME}:db --name rockmongo webts/rockmongo

EOF
