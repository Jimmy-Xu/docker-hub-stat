#!/usr/bin/python

import os
import sys
import json
import dateutil.parser
import argparse
from prettytable import PrettyTable

g_result=[]
g_index=1
g_sort=False
g_format="table"

##---------------------------------------------------------##
def show_tag():
    global g_sort
    global g_index
    global g_result
    global g_format

    if g_sort:
        #sort
        sorted_list = sorted(g_result, key=lambda k: (k['repo_name'],k["last_updated"]))
    else:
        #no-sort
        sorted_list = g_result

    for item in sorted_list:
        item["index"] = g_index
        g_index = g_index + 1

    if g_format == "json":
        print json.dumps(sorted_list, indent=4)
    else:
        x = PrettyTable(["no","image","last_updated","tag","full_size","v2","repository","creator","last_updater","id","image_id"])
        x.align["no"] = "r"
        x.align["tag"] = "l" # Left align
        x.align["full_size"] = "r"
        x.align["image"] = "l"
        x.align["last_updated"] = "l"
        x.align["v2"] = "l"
        x.align["repository"] = "l"
        x.align["creator"] = "l"
        x.align["last_updater"] = "l"
        x.align["id"] = "l"
        x.padding_width = 1 # One space between column edges and contents (default)
        #x.header = False # hide title

        for i in sorted_list:
            x.add_row([
                        i["index"],
                        i["repo_name"],
                        "" if not i["last_updated"] else  dateutil.parser.parse(i["last_updated"]).strftime("%Y/%m/%d %H:%M:%S") ,
                        i["name"],
                        "{0} MB".format(i["full_size"]/1024/1024),
                        i["v2"],
                        i["repository"],
                        i["creator"],
                        i["last_updater"],
                        i["id"],
                        i["image_id"]
                    ])

        #new_table = x[0:6]
        print x.get_string(fields=["no","image","last_updated","tag","full_size","v2"])

def parse_tag(base_dir, user_dir, repo_dir, page_file):
    global g_result
    f="{0}/{1}/{2}/{3}".format(base_dir,user_dir,repo_dir,page_file)
    #print "read data from file: {0}".format(f)
    with open(f) as data_file:
        data = json.load(data_file)
    repo_name = repo_dir

    if "results" not in data:
        import pdb;pdb.set_trace()
        print "wrong data format in file: {0}".format(f)
    else:
        for item in data["results"]:
            item["repo_name"] = repo_name
            g_result.append(item)

def read_tag(flag):
    IN_DIR = "list_result"
    i = 1

    ##print "\nlist dir under dir: {0}".format(IN_DIR)
    #level 1(user dir)
    for user_dir in os.listdir(IN_DIR):
        if flag == "official":
            if user_dir != "library":
                continue
        elif flag == "custom":
            if user_dir == "library":
                continue
        user_path = os.path.join(IN_DIR, user_dir)
        if os.path.isdir(user_path):
            ##print "\tlist file under dir: {0}".format(user_path)
            #level 2(repo dir)
            for repo_dir in os.listdir(user_path):
                try:
                    page_path = os.path.join(user_path, repo_dir)
                    if os.path.isdir(page_path):
                        ##print "\t\tlist file under dir: {0}".format(page_path)
                        #level 3(page file)
                        for page_file in os.listdir(page_path):
                            try:
                                page_path = os.path.join(page_path, page_file)
                                if os.path.isfile(page_path):
                                    parse_tag(IN_DIR, user_dir, repo_dir, page_file)
                            except:
                                continue
                except:
                    continue
        i = i + 1

##---------------------------------------------------------##
def show_usage():
    print "usage: ./show_info.py [sort] [format]"
    print "<flag>: --official|--custom|--all"
    print "[sort]: --sort"
    print "[format] --format=table|json"
    os._exit(1)

############ main #################

if len(sys.argv)<2:
    show_usage()

#start parse parameter
parser = argparse.ArgumentParser()
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("--official",action="store_true")
group.add_argument("--custom",action="store_true")
group.add_argument("--all",action="store_true")
parser.add_argument("-s","--sort",action="store_true",default=False)
parser.add_argument("-f","--format",type=str,default="table",choices=["table","json"])
args = parser.parse_args()

#check sort
if args.sort:
    g_sort=args.sort
if args.format:
    g_format=args.format

if args.official:
    read_tag('official')
elif args.custom:
    read_tag('custom')
elif args.all:
    read_tag('all')
else:
   show_usage

show_tag()
