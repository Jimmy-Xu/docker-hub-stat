#!/bin/bash

MAX_NPROC=100
DELAY_SEC=1
TMP="/tmp/get_tag"
FILE_SUCCESS="${TMP}/counter.success"
FILE_FAIL="${TMP}/counter.fail"

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
cd ${WORKDIR}
mkdir -p ${TMP}

function inc_job_result(){
  case $1 in
    success)
      read -u7 #fd7
      CNT_SUCESS=$(cat ${FILE_SUCCESS})
      CNT_SUCESS=$((CNT_SUCESS+1))
      echo ${CNT_SUCESS} >${FILE_SUCCESS}
      echo "[ inc_job_result : success:) ] [$2] ${CNT_SUCESS}/${TOTAL_TOFETCH}"
      echo >&7 #fd7
      ;;
    "not json"|fail)
      read -u8 #fd8
      CNT_FAIL=$(cat ${FILE_FAIL})
      CNT_FAIL=$((CNT_FAIL+1))
      echo ${CNT_FAIL} >${FILE_FAIL}
      echo "[ inc_job_result : $1:( ] [$2] ${CNT_FAIL}/${TOTAL_TOFETCH}"
      echo >&8 #fd8
      ;;
    *)
      echo "unknow job result"
      exit 1
  esac
}

############## main ##############
if [ ! -s etc/image_full.lst ];then
  echo "please create 'etc/image_full.lst' first"
  exit 1
fi


echo -n > etc/image_tofetch.lst
TOTAL_FULL=$(cat etc/image_full.lst|wc -l )
IDX=0
echo "---------------------------------------------"
echo "Scan result, generate new image_tofetch.lst"
echo "---------------------------------------------"
while read CURRENT_REPO
do
  IDX=$(( IDX + 1 ))
  if [ ! -s ${WORKDIR}/result/tags/${CURRENT_REPO}.json ];then
    #echo "[>${IDX}/${TOTAL_FULL}]${CURRENT_REPO} need fetch"
    echo ${CURRENT_REPO} >> etc/image_tofetch.lst
  else
    jq . ${WORKDIR}/result/tags/${CURRENT_REPO}.json >/dev/null 2>&1
    if [ $? -ne 0 ];then
      echo "[ ${IDX}/${TOTAL_FULL} ] '${CURRENT_REPO}' is not json, need re-fetch"
      echo ${CURRENT_REPO} >> etc/image_tofetch.lst
    else
      continue
    fi
  fi
done < etc/image_full.lst

START_TS=$(date +"%s")
START_TIME=$(date +"%F %T")

# prepare pipe(for control concurrent tasks)
mkdir -p /tmp/imagelayers
Pfifo="/tmp/imagelayers/$$.fifo"
mkfifo $Pfifo $Pfifo.success $Pfifo.fail
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
echo  >&7
#init fail counter
echo  >&8

echo -n 0 > ${FILE_SUCCESS}
echo -n 0 > ${FILE_FAIL}

# start fetch image tag from etc/image_tofetch.lst
JOB_TOTAL=0

TOTAL_TOFETCH=$(cat etc/image_tofetch.lst|wc -l )
SKIP=$(( TOTAL_FULL - TOTAL_TOFETCH ))
echo
echo "##############################################"
echo "total: ${TOTAL_FULL} skip: ${SKIP} tofetch: ${TOTAL_TOFETCH}"
echo "##############################################"
[ ${TOTAL_TOFETCH} -gt 0 ] && echo ">start batch get tag ..."
echo
while read CURRENT_REPO
do
  JOB_TOTAL=$((JOB_TOTAL+1))
  #fetch token from pipe(block here if there is no token in pipe)
  read -u6 #fd6
  {
    #exec job
    _NS=$(echo ${CURRENT_REPO} | awk -F"/" '{print $1}')
    _REPO=$(echo ${CURRENT_REPO} | awk -F"/" '{print $2}')
    RLT_PATH=${WORKDIR}/result/tags/${_NS}
    mkdir -p ${RLT_PATH}

    EXEC_CMD="curl -s http://127.0.0.1:8008/registry/images/${CURRENT_REPO}/tags -o ${RLT_PATH}/${_REPO}.json"
    echo "start job: [ ${CURRENT_REPO} ] ..."
    eval "${EXEC_CMD}" && {
      #echo "Job finished: [${CURRENT_REPO}]"
      #check json
      jq . ${RLT_PATH}/${_REPO}.json >/dev/null 2>&1
      if [ $? -eq 0 ];then
        inc_job_result "success" "${CURRENT_REPO}"
      else
        inc_job_result "not json" "${CURRENT_REPO}"
      fi
    } || {
      #echo "Job failed: [${CURRENT_REPO}]"
      inc_job_result "fail" "${CURRENT_REPO}"
    }

    #echo "delay '${DELAY_SEC}' seconds"
    sleep ${DELAY_SEC}
    #give back token to pipe
    echo >&6 #fd6
  }&
done < etc/image_tofetch.lst
#wait for all task finish
wait

# #read counter
JOB_SUCCESS=$(cat ${FILE_SUCCESS})
JOB_FAIL=$(cat ${FILE_FAIL})

#delete file descriptor
exec 6>&- #fd6
exec 7>&-
exec 8>&-
rm -f ${FILE_SUCCESS}
rm -f ${FILE_FAIL}

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
TOTAL_FULL     : ${TOTAL_FULL}
TOTAL_TOFETCH  : ${TOTAL_TOFETCH}
SKIP           : ${SKIP}

JOB_TOTAL      : ${JOB_TOTAL}
JOB_SUCCESS    : ${JOB_SUCCESS}
JOB_FAIL       : ${JOB_FAIL}
#######################################
EOF

echo "done!"
