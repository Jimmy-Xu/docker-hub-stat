#!/bin/bash

#image name
REPO_NAME="mysql"
IMAGE_TAG="5.7.10"
IMAGE_NAME=${REPO_NAME}:${IMAGE_TAG}
MYSQL_ROOT_PASSWORD="aaa123aa"

#container and image name
CONTAINER_NAME="hub-mysql"
CONTAINER_HOSTNAME="mysql"
CONTAINER_PORT="3306"

#volume
LOCAL_DB_DIR=`pwd`/db
SRC_DATA_DIR=`pwd`/..

#port
#LOCAL_PORT="3306"

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
#ensure db dir exist
if [ ! -d ${LOCAL_DB_DIR} ];then
  mkdir -p ${LOCAL_DB_DIR}
fi

############################################################
#ensure old container not exist
docker ps -a | grep " ${CONTAINER_NAME}$"
if [ $? -eq 0 ];then
  echo "stop old ${CONTAINER_NAME}"
  docker rm -f ${CONTAINER_NAME}
fi

docker ps -a | grep " hub-phpmyadmin$"
if [ $? -eq 0 ];then
  echo "stop old hub-phpmyadmin"
  docker rm -f hub-phpmyadmin
fi

############################################################
#start new container
echo "start mysql"
docker run -d --name ${CONTAINER_NAME} --hostname=${CONTAINER_HOSTNAME} -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} -v ${LOCAL_DB_DIR}:/var/lib/mysql -v ${SRC_DATA_DIR}:/data/source ${REPO_NAME}:${IMAGE_TAG}

echo "start phpmyadmin"
docker run -d --name hub-phpmyadmin -e MYSQL_HOST=${CONTAINER_HOSTNAME}:${CONTAINER_PORT} --link ${CONTAINER_NAME}:mysql -p 8080:80 nazarpc/phpmyadmin

cat <<EOF
-------------------------------------------------
[test mysql cli]
  docker run -it --link ${CONTAINER_NAME}:mysql --rm mysql:5.7.10 sh -c 'exec mysql -h\${MYSQL_PORT_3306_TCP_ADDR} -P\${MYSQL_PORT_3306_TCP_PORT} -uroot -p\${MYSQL_ENV_MYSQL_ROOT_PASSWORD}'

[create database and table]
  docker exec -it ${CONTAINER_NAME} bash -c "mysql -u root -paaa123aa < /data/source/mysql/sql/create_table.sql"

[import csv to table]
  docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/search_repo.csv"
  docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/list_repo.csv"
  docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/list_tag.csv"

[show table structure]
  docker exec -it ${CONTAINER_NAME} bash -c "mysql -u root -paaa123aa --database docker -e 'show create table search_repo'"
  docker exec -it ${CONTAINER_NAME} bash -c "mysql -u root -paaa123aa --database docker -e 'show create table list_repo'"
  docker exec -it ${CONTAINER_NAME} bash -c "mysql -u root -paaa123aa --database docker -e 'show create table list_tag'"


[use phpMyAdmin]

  open http://<host_ip>:8080 in web browser, login with root:aaa123aa

EOF
