import data to mongo, then export to csv
-----------------------------

### start container: hub-mongo

    $ cd mongo
    $ docker build -t xjimmyshcn/mongo:3.2 .
    $ ./run.sh

### imort data

    #to import search_repo result:
    $ docker exec -it hub-mongo bash -c "cd /data/source/search_repo;./import_result.py"

    #to import list_repo result:
    $ docker exec -it hub-mongo bash -c "cd /data/source/list_repo;./import_result.py --data_dir=20160111"

    #to import list_tag result:
    $ docker exec -it hub-mongo bash -c "cd /data/source/list_tag;./import_result.py"


### export mongo to csv

    #export search_repo collection to search_repo.csv
    $ docker exec -it hub-mongo bash -c "mongoexport --host 127.0.0.1 --db docker --collection search_repo --fields name,_namespace,_repo_name,is_official,is_trusted,star_count,is_automated --type=csv > /data/source/csv/search_repo.csv"

    #export list_repo collection to list_repo.csv
    $ docker exec -it hub-mongo bash -c "mongoexport --host 127.0.0.1 --db docker --collection list_repo --fields _image_name,namespace,name,star_count,pull_count,is_automated,status,last_updated --type=csv > /data/source/csv/list_repo.csv"

    #export list_tag collection to list_tag.csv
    $ docker exec -it hub-mongo bash -c "mongoexport --host 127.0.0.1 --db docker --collection list_tag --fields _image_name,_namespace,_repo_name,name,full_size,v2 --type=csv > /data/source/csv/list_tag.csv"


import csv to mysql
-----------------------------

### start container: hub-mysql and hub-phpmyadmin

    $ cd mysql
    $ ./run.sh

    #test mysql cli
    $ docker run -it --link ${CONTAINER_NAME}:mysql --rm mysql:5.7.10 sh -c 'exec mysql -h\${MYSQL_PORT_3306_TCP_ADDR} -P\${MYSQL_PORT_3306_TCP_PORT} -uroot -p\${MYSQL_ENV_MYSQL_ROOT_PASSWORD}'

### create database and tables

  #create database
  $ docker exec -it ${CONTAINER_NAME} bash -c "mysql -u root -paaa123aa < /data/source/mysql/sql/create_table.sql"

### import csv to table

  $ docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/search_repo.csv"

  $ docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/list_repo.csv"

  $ docker exec -it ${CONTAINER_NAME} bash -c "mysqlimport --ignore-lines=1 --fields-terminated-by=, --local -u root -paaa123aa docker /data/source/csv/list_tag.csv"
