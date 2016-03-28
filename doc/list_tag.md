list all tag of repo
=================================================

repo list
-------------------------------------------------
- etc/official.txt
- etc/custome.txt

list tag
-------------------------------------------------

### get first page
```
./run.sh 1 1
./run.sh 2 1
```

### get rest page
```
./run.sh 2 1
./run.sh 2 2
```

view result
-------------------------------------------------

```
./show_result.py --official
./show_result.py --official --sort
./show_result.py --official --sort --format=table
```
