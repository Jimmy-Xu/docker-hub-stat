#!/bin/bash
# search repo by name with search_repo.sh

###### global #####
WORKER_CNT=50

###### function ######
function show_usage(){
  cat <<EOF
  ./run.sh [option]
  [option]:
    1 fetch first page
    2 fetch rest page
EOF
  exit 1
}

function show_message(){
  echo "[ ${FLAG} ]: $1"
}

function search_all_page(){
  GET_FIRST_PAGE=$1
  show_message "== GET_FIRST_PAGE: ${GET_FIRST_PAGE} =="
  total_namespace=$((36*36+1))
  for i in 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z
  do
    for j in 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z
    do
      total_namespace=$((total_namespace - 1))
      FLAG=$i$j
      show_message "=============== ${total_namespace} ==============="
      #prepare dir
      OUT_DIR="./search_result/${FLAG}"
      mkdir -p $OUT_DIR

      if [ "${GET_FIRST_PAGE}" == "true" ];then
        echo "get first page"
        start_page=1
        num_pages=1
      else
        echo "get rest page"
        if [ ! -s ${OUT_DIR}/1.json ];then
          show_message "> failed: ${OUT_DIR}/1.json not found, skip"
          continue
        fi
        start_page=2
        num_pages=$(jq .num_pages ${OUT_DIR}/1.json)
      fi
      show_message ">page range: ${start_page} -> ${num_pages}"

      #loop
      echo "-------------------------------------------"
      for p in $(seq ${start_page} ${num_pages})
      do
        if [[ -s ${OUT_DIR}/${p}.json ]] && [[ -s ${OUT_DIR}/${p}.txt ]] ;then
          show_message "page ${p} already fetched, skip"
          continue
        fi
        p_cnt=$(ps -ef |grep "search_repo.sh" | grep -v grep | wc -l)
        while [ ${p_cnt} -ge ${WORKER_CNT} ]
        do
          sleep 5
          p_cnt=$(ps -ef |grep "search_repo.sh" | grep -v grep | wc -l)
        done
        ./search_repo.sh ${p} ${FLAG} ${total_namespace} &
        sleep 1
      done
      #for p in
    done
    #for j in
  done
  #for i in
}


########### main ###########

#check parameter
if [ $# -ne 1 ];then
  show_usage
fi

if [ $1 -eq 1 ];then
  GET_FIRST_PAGE=true
elif [ $1 -eq 2 ];then
  GET_FIRST_PAGE=false
else
  show_usage
fi
#start
BEGIN_TIME=$(date "+%F %T")
search_all_page ${GET_FIRST_PAGE}
END_TIME=$(date "+%F %T")

echo "BEGIN_TIME: ${BEGIN_TIME}"
echo "END_TIME  : ${END_TIME}"
echo "./run.sh Done."
