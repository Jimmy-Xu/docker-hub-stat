#!/bin/bash

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
LAYER_DIR="result/layers"
OUTPUT="result/stat"
cd ${WORKDIR}/${LAYER_DIR}
mkdir -p ${WORKDIR}/${OUTPUT}
echo "repo,tag,layer_count,layer_size," > ${WORKDIR}/${OUTPUT}/stat_layer.csv

for i in $(find . -name "*.json" -type f)
do
  #echo $i
  LAYER_CNT=$(jq ".[].repo.count, .[].repo.size" $i 2>/dev/null | tr '\n' ',' | sed -e 's/|$/\n/')
  if [ $? -ne 0 ];then
    echo "$i is not json format,skip"
    continue
  else
    printf "%s/%s\n" ${LAYER_CNT} ${i/.json/} | awk -F"/" '{if($1!="0,0,")printf "%s/%s,%s,%s\n", $3,$4, $5,$1 }' | tee -a ${WORKDIR}/${OUTPUT}/stat_layer.csv
  fi
done
