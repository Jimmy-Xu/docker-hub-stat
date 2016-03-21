# run local imagelayers api server

## start imagelayers container
```
./run.sh
```

## invoke imagelayers api
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
$ curl -s -XPOST -d '{"repos":[{"name":"busybox","tag":"1.24"}]}' http://127.0.0.1:8008/registry/analyze
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
```

# imagelayers.io

> invoke online imagelayers

```
//get tags
$ curl -s https://imagelayers.io:8888/registry/images/busybox/tags | jq .

//get layers
$ curl -s -XPOST -d '{"repos":[{"name":"busybox","tag":"1.24"}]}' https://imagelayers.io:8888/registry/analyze
```
