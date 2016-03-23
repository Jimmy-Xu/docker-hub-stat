#!/bin/bash
## base on the result of get_layer.sh

WORKDIR=$(cd `dirname $0`; cd ../..; pwd)
INPUT_DIR="result/layers/v2"
OUTPUT_DIR="result/stat/v2"
cd ${INPUT_DIR}
mkdir -p ${WORKDIR}/${OUTPUT_DIR}
echo "repo,tag,layer_count" > ${WORKDIR}/${OUTPUT_DIR}/stat_layer.csv

for f in $(find . -name "*.json" -type f)
do
  _NS=$(echo $f | awk -F"[./]" '{print $3}')
  _REPO=$(echo $f | awk -F"[./]" '{print $4}')
  _TAG=$(echo $f | awk -F"[./]" '{print $5}')
  layersFs=$(jq --raw-output '.fsLayers | .[] | .blobSum' $f 2>/dev/null )
  if [ "${layersFs}" == "" ];then
    echo "${WORKDIR}/${INPUT_DIR}/$f is invlaid,skip"
    continue
  fi
  layers=( ${layersFs} ) #convert to array
  echo "${_NS}/${_REPO},${_TAG},${#layers[@]}" >> ${WORKDIR}/${OUTPUT_DIR}/stat_layer.csv
done

echo "done"
