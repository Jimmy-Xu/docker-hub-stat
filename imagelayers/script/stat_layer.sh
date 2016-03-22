#!/bin/bash

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
LAYER_DIR="result/layers"
cd ${WORKDIR}/${LAYER_DIR}

for i in $(find . -name "*.json" -type f)
do
  #echo $i
  LAYER_CNT=$(jq ".[].repo.count" $i 2>/dev/null)
  if [ $? -ne 0 ];then
    echo "$i is not json format,skip"
    continue
  else
    printf "%d/%s\n" ${LAYER_CNT} ${i/.json/} | awk -F"/" '{if($1!=0)printf "%s/%s,%s,%d\n", $3,$4, $5,$1 }'
  fi
done
