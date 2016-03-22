get image tag and layer, stat layer
===========================


<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [run local imagelayers api server](#run-local-imagelayers-api-server)
	- [start imagelayers container](#start-imagelayers-container)
		- [build and run](#build-and-run)
		- [invoke imagelayers api](#invoke-imagelayers-api)
	- [fetch tag and layer data](#fetch-tag-and-layer-data)
		- [batch get tag](#batch-get-tag)
		- [batch get layers](#batch-get-layers)
	- [process result](#process-result)
		- [stat layer](#stat-layer)
		- [import result/stat/ to mysql](#import-resultstat-to-mysql)
- [use imagelayers.io](#use-imagelayersio)

<!-- /TOC -->

> https://github.com/CenturyLinkLabs/imagelayers


# run local imagelayers api server

## start imagelayers container

### build and run
```
//show usage
$ ./run.sh
  usage:
    ./run.sh <action>
  <action>:
    -------------------------------------------------------------
    start_container   # start imagelayer api server container
    -------------------------------------------------------------
    get_tag           # get image tag list
    -------------------------------------------------------------
    get_layer_latest  # get layer for image's latest tag(faster)
    get_layer_all     # get layer for image's all tag
    -------------------------------------------------------------
    stat_layer        # stat layer of images's tag(result/layers/)
    -------------------------------------------------------------


//start container
$ ./run.sh start_container

//check container
$ docker ps | grep "imagelayers$"
  CONTAINER ID    IMAGE                    COMMAND             CREATED         STATUS         PORTS                    NAMES
  06eb3da1af28    xjimmyshcn/imagelayers   "go run main.go"    11 hours ago    Up 11 hours    0.0.0.0:8008->8888/tcp   imagelayers
```

### invoke imagelayers api
```
//get tags
$ curl -s http://127.0.0.1:8008/registry/images/busybox/tags | jq .
  {
    "1": "bc744c4ab376115cc45c610d53f529dd2d4249ae6b35e5d6e7a96e58863545aa",
    "1-glibc": "2437be9826eb202d7107f00a29671fd248439b1025223d8c569b5dcbc05c0dbf",
    "1-musl": "785d7401a39d4f6d8663b8d84c787a4c136a3f9706220082c9cb9c9f7fb54c52",
    "1-ubuntu": "a6dbc8d6ddbb9e905518a9df65f414efce038de5f253a081b1205c6cea4bac17",
    "1-uclibc": "bc744c4ab376115cc45c610d53f529dd2d4249ae6b35e5d6e7a96e58863545aa",
    "1.21-ubuntu": "a6dbc8d6ddbb9e905518a9df65f414efce038de5f253a081b1205c6cea4bac17",
    "1.21.0-ubuntu": "a6dbc8d6ddbb9e905518a9df65f414efce038de5f253a081b1205c6cea4bac17",
    ...


//get layers
$ curl -s -XPOST -d '{"repos":[{"name":"busybox","tag":"1.24"}]}' http://127.0.0.1:8008/registry/analyze | jq .
  [
    {
      "repo": {
        "name": "busybox",
        "tag": "1.24",
        "size": 1112820,
        "count": 2
      },
      "layers": [
        {
          "id": "bc744c4ab376115cc45c610d53f529dd2d4249ae6b35e5d6e7a96e58863545aa",
          "parent": "56ed16bd6310cca65920c653a9bb22de6b235990dcaa1742ff839867aed730e5",
          "Comment": "",
          "created": "2016-03-18T18:22:48.810791943Z",
          ...

//count layers of a image tag
$ curl -s -XPOST -d '{" repos":[{"name":"busybox","tag":"1.24"}]}' http://127.0.0.1:8008/registry/analyze | jq ".[].repo.count, .[].layers[].id"

  2
  "bc744c4ab376115cc45c610d53f529dd2d4249ae6b35e5d6e7a96e58863545aa"
  "56ed16bd6310cca65920c653a9bb22de6b235990dcaa1742ff839867aed730e5"
```
## fetch tag and layer data

### batch get tag
```
//prepare image list `etc/image_full.lst`
$ head -n 10 etc/image_full.lst
  library/busybox
  library/ubuntu
  library/nginx
  library/swarm
  library/registry
  library/redis
  library/mysql
  library/mongo
  library/node
  library/postgres

//start batch get tag( each time run this command, it will skip the repo which was already getted )
$ ./run.sh get_tag

//view result `result/tags/`
$ tree result/tags/library | head -n 10
  result/tags/library
  ├── aerospike.json
  ├── alpine.json
  ├── arangodb.json
  ├── bonita.json
  ├── buildpack-deps.json
  ├── busybox.json
  ├── cassandra.json
  ├── celery.json
  ├── centos.json

```

### batch get layers

> this operation is based on `./run.sh get_tag`

```
//each time run this command, it will skip the tag which was already getted

//only get latest tag(faster)
$ ./run.sh get_layer_latest
or
// get all tags
$ ./run.sh get_layer_all
```

## process result

### stat layer
```
//return (<repo>, <tag>, <layer_count>, <layer_size>)
$ ./run.sh stat_layer | head -n 10
	library/nginx,latest,8,190512459,
	library/busybox,latest,2,1112820,
	library/redis,latest,17,177586452,
	library/postgres,latest,22,264567018,
	library/registry,latest,14,422909893,
	library/ruby,latest,18,725484111,
	library/java,latest,14,642897103,
	library/python,latest,13,689550652,
	library/node,latest,10,644302697,
	library/alpine,latest,1,4797951,


//result data
result/stat/stat_layer.csv
```

### import result/stat/ to mysql

> base on container `hub-mysql`, [how to run hub-mysql](doc/process_data.md#start-container-hub-mysql-and-hub-phpmyadmin)

```
$ docker exec -it hub-mysql bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/imagelayers/result/stat/stat_layer.csv"
    docker.stat_layer: Records: 2254  Deleted: 0  Skipped: 0  Warnings: 0
```

# use imagelayers.io

> invoke online imagelayers api

```
//get tags
$ curl -s https://imagelayers.io:8888/registry/images/busybox/tags | jq .

//get layers
$ curl -s -XPOST -d '{"repos":[{"name":"busybox","tag":"1.24"}]}' https://imagelayers.io:8888/registry/analyze | jq .
curl -s -XPOST -d '{" repos":[{"name":"library/ubuntu","tag":"trusty"}]}' https://imagelayers.io:8888/registry/analyze  
```
