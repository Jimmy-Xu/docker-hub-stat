FROM mongo:3.2.3
MAINTAINER Jimmy Xu <xjimmyshcn@gmail.com>

ADD etc/apt/sources.list.wheezy /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y python python-pip
RUN pip install pymongo python-dateutil prettytable

VOLUME /data/db
VOLUME /data/source

EXPOSE 27017
