#!/bin/bash

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

OUTPUT_DIR=${WORKDIR}/process_result
[ ! -d ${OUTPUT_DIR} ] && mkdir -p ${OUTPUT_DIR}
OUTPUT_CSV=${OUTPUT_DIR}/list_tag.csv

echo "repo_name,tag,size" > ${OUTPUT_CSV}

for f in $(find  list_result -name "*.json")
do
  repo_name=$(echo $f | awk -F"/" '{printf "%s/%s", $(NF-2), $(NF-1)}')
  cat $f | jq ".results[].repo_name=\"${repo_name}\"" | jq .results | jq -r -c '.[] | {repo_name,name,full_size} | [.[]] | @csv' | tee -a ${OUTPUT_CSV}
done

echo "total lines in ${OUTPUT_CSV}: $(cat ${OUTPUT_CSV} | wc -l)"
echo "Done"
