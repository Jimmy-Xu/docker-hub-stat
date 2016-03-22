#!/bin/bash
set -e

##############################################################################################################################
# https://raw.githubusercontent.com/docker/docker/6bf8844f1179108b9fabd271a655bf9eaaf1ee8c/contrib/download-frozen-image-v2.sh
###############################################################################################################################

if ! command -v curl &> /dev/null; then
	echo >&2 'error: "curl" not found!'
	exit 1
fi

usage() {
	echo "usage: $0 image[:tag][@digest] ..."
	echo "       $0 hello-world:latest@sha256:8be990ef2aeb16dbcb9271ddfe2610fa6658d13f6dfb8bc72074cc1ca36966a7"
  echo "       $0 ubuntu:latest alpine:latest ubuntu:14.04 alpine:3.3"
	[ -z "$1" ] || exit "$1"
}

if [ $# -eq 0 ];then
  usage 1 >&2
fi

declare -A dic_token

#same repo use the same token
while [ $# -gt 0 ]; do
	imageTag="$1"
	shift
	image="${imageTag%%[:@]*}"
	imageTag="${imageTag#*:}"
	digest="${imageTag##*@}"
	tag="${imageTag%%@*}"

	# add prefix library if passed official image
	if [[ "$image" != *"/"* ]]; then
		image="library/$image"
	fi

  # fetch token in cache
  token=${dic_token[$image]}
  if [ -z $token ];then
    #fetch new token
  	token="$(curl -sSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$image:pull" | jq --raw-output .token)"
    dic_token[$image]=$token
  # else
  #   echo -n "[*]"
  fi

	manifestJson="$(curl -sSL -H "Authorization: Bearer $token" "https://registry-1.docker.io/v2/$image/manifests/$digest")"
	if [ "${manifestJson:0:1}" != '{' ]; then
		echo >&2 "error: /v2/$image/manifests/$digest returned something unexpected:"
		echo >&2 "  $manifestJson"
		exit 1
	fi

	layersFs=$(echo "$manifestJson" | jq --raw-output '.fsLayers | .[] | .blobSum')

	IFS=$'\n'
	# bash v4 on Windows CI requires CRLF separator
	if [ "$(go env GOHOSTOS)" = 'windows' ]; then
		major=$(echo ${BASH_VERSION%%[^0.9]} | cut -d. -f1)
		if [ "$major" -ge 4 ]; then
			IFS=$'\r\n'
		fi
	fi
	layers=( ${layersFs} )
	unset IFS

	history=$(echo "$manifestJson" | jq '.history | [.[] | .v1Compatibility]')
	imageId=$(echo "$history" | jq --raw-output .[0] | jq --raw-output .id)

	echo "${image},${tag},${#layers[@]}"
done
