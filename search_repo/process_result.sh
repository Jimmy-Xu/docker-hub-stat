#!/bin/bash

echo "-------------------------------------"
WORK_DIR="process_result/$(date '+%Y%m%d')"
mkdir -p ${WORK_DIR}
if [ ! -d ${WORK_DIR} ];then
  echo "${WORK_DIR} not found!"
  exit 1
fi

echo "output dir: ${WORK_DIR}"

REPO_FILE="${WORK_DIR}/repo.txt"
echo "-------------------------------------"
echo "1.generate repo list to ${REPO_FILE}"
BEGIN_TIME=$(date "+%s")
echo "cat result"
find search_result/* -name "*.txt" | xargs cat > ${WORK_DIR}/repo.tmp
echo "merge result"
sort -u ${WORK_DIR}/repo.tmp > ${REPO_FILE}
END_TIME=$(date "+%s")
if [ -s ${REPO_FILE} ];then
  echo "duration: $((END_TIME - BEGIN_TIME)) "
  echo "lines: $(cat ${REPO_FILE} | wc -l)"
  GZIP="-9" tar czvf ${WORK_DIR}/repo.tgz ${REPO_FILE}
else
  echo "failed, ${REPO_FILE} is empty or not exist"
  exit 1
fi


USER_FILE="${WORK_DIR}/user.txt"
echo "-------------------------------------"
echo "2.generate user list to ${USER_FILE}"
BEGIN_TIME=$(date "+%s")
cat ${REPO_FILE} | awk -F"/" '{print $1}' | sort -u | sort -u > ${USER_FILE}
END_TIME=$(date "+%s")
if [ -s ${USER_FILE} ];then
  echo "duration: $((END_TIME - BEGIN_TIME)) "
  echo "lines: $(cat ${USER_FILE} | wc -l)"
  GZIP="-9" tar czvf ${WORK_DIR}/user.tgz ${USER_FILE}
else
  echo "failed, ${USER_FILE} is empty or not exist"
  exit 1
fi

echo "Done"
