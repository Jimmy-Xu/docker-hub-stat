FROM golang:1.5.3

ENV GOPATH /go

RUN mkdir -p $GOPATH/src/golang.org/x
RUN git clone https://github.com/golang/net.git $GOPATH/src/golang.org/x/net

RUN go get github.com/CenturyLinkLabs/imagelayers
RUN go get github.com/tools/godep
WORKDIR $GOPATH/src/github.com/CenturyLinkLabs/imagelayers
RUN NNET=`grep -n "" Godeps/Godeps.json  | grep "golang.org/x/net" | awk -F":" '{print $1}'` && [ ! -z $NNET ] && sed -i "$((NNET-1)),$((NNET+2))d" Godeps/Godeps.json
RUN godep restore
RUN go test ./...

EXPORT 8888
#ENTRYPOINT ["go run main.go"]
