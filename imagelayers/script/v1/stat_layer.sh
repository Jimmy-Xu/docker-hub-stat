#!/bin/bash
## base on the result of get_layer.sh

WORKDIR=$(cd `dirname $0`; cd ../..; pwd)
INPUT_DIR="result/layers/v1"
OUTPUT_CSV="../csv/stat_layer_v1.csv"
cd ${WORKDIR}/${INPUT_DIR}
echo "repo,tag,layer_count,layer_size," > ${WORKDIR}/${OUTPUT_CSV}

for i in $(find . -name "*.json" -type f)
do
  #echo $i
  LAYER_CNT=$(jq ".[].repo.count, .[].repo.size" $i 2>/dev/null | tr '\n' ',' | sed -e 's/|$/\n/')
  if [ $? -ne 0 ];then
    echo "$i is not json format,skip"
    continue
  else
    printf "%s/%s\n" ${LAYER_CNT} ${i/.json/} | awk -F"/" '{if($1!="0,0,")printf "%s/%s,%s,%s\n", $3,$4, $5,$1 }' | tee -a ${WORKDIR}/${OUTPUT_CSV}
  fi
done
