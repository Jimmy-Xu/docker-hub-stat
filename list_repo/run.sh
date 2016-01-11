#!/bin/bash
# list repo by namespace with list_repo.sh

WORKER_CNT=50
SRC_BASE="../search_repo/process_result"

function show_usage(){
  cat <<EOF

usage: ./run.sh <dir_name>
<dir_name>: sub_dir under ./result
eg: ./run.sh 20160109

-----------------------
[available]:
EOF
  ls ${SRC_BASE}
  exit 1
}

#check parameter
if [ $# -ne 1 ];then
  echo "parameter error!"
  show_usage
fi

#check input parameter
SRC_DIR="${SRC_BASE}/$1/"
USER_LIST="${SRC_DIR}/user.txt"
if [ ! -d ${SRC_DIR} ];then
  echo "${SRC_DIR} not found!"
  show_usage
else
  if [ ! -s ${USER_LIST} ];then
    echo "${USER_LIST} is not exist or is empty"
    show_usage
  fi
fi

#start
total=$(cat ${USER_LIST}|wc -l)
OUT_BASE="./list_result/$1"
while read NAMESPACE
do
  echo "==== [ ${total} ] ${NAMESPACE} ===="
  p_cnt=$(ps -ef |grep "list_repo.sh" | grep -v grep | wc -l)
  while [ ${p_cnt} -ge ${WORKER_CNT} ]
  do
    sleep 5
    p_cnt=$(ps -ef |grep "list_repo.sh" | grep -v grep | wc -l)
  done

  OUT_DIR="${OUT_BASE}/${NAMESPACE}"
  if [ ! -f ${OUT_DIR}/end ];then
    #not fetched
    ./list_repo.sh $1 ${NAMESPACE} ${total} &
    #sleep 1
  fi
  total=$((total-1))
done < ${USER_LIST}
echo "All Done"
