#!/usr/bin/python

import os
import sys
import json
import argparse
from prettytable import PrettyTable

g_result=[]
g_index=1
g_sort=False
g_format="table"
g_dir=""

##---------------------------------------------------------##
def show_data():
    global g_sort
    global g_index
    global g_result
    global g_format

    if g_sort:
        #sort
        sorted_list = sorted(g_result, key=lambda k: (k['star_count']), reverse=True)
    else:
        #no-sort
        sorted_list = g_result

    for item in sorted_list:
        item["index"] = g_index
        g_index = g_index + 1

    if g_format == "json":
        print json.dumps(sorted_list, indent=4)
    else:
        x = PrettyTable(["no","search_key","name","stars","official","automated","trusted","description"])
        x.align["no"] = "r"
        x.align["search_key"] = "l" # Left align
        x.align["name"] = "l"
        x.align["stars"] = "r"
        x.align["automated"] = "l"
        x.align["official"] = "l"
        x.align["trusted"] = "l"
        x.align["description"] = "l"
        x.padding_width = 1 # One space between column edges and contents (default)
        #x.header = False # hide title

        for i in sorted_list:
            x.add_row([
                        i["index"],
                        "; ".join(i["key"]),
                        i["name"],
                        i["star_count"],
                        "*" if i["is_official"] else "",
                        "*" if i["is_automated"] else "",
                        "*" if i["is_trusted"] else "",
                        i["description"]
                    ])
        print x

def parse_data(idx,f):
    global g_result
    #print "read data from file: {0}".format(f)
    with open(f) as data_file:
        data = json.load(data_file)
    tmp = f.split("/")
    search_name = tmp[len(tmp)-1]

    if "results" not in data:
         print "wrong data format in file: {0}".format(f)
    else:

        for item in data["results"]:
            item["name"] = item["name"].rstrip()
            item["description"] = item["description"].rstrip()
            #check if name is already is existed
            if any(d['name'] == item["name"] for d in g_result):
                #print "{0} existed".format(item["name"])
                found = (ii for ii in g_result if ii["name"] == item["name"]).next()
                found["key"].append(search_name)
            else:
                #print "{0} not existed".format(item["name"])
                #item["g_seq"] = idx
                item["search_name"] = search_name
                item["key"]=[]
                item["key"].append(search_name)
                # if len(item["name"].split("/"))>1:
                #     item["third-part"]="*"
                # else:
                #     item["third-part"]=""
                g_result.append(item)

def read_data():
    global g_dir
    IN_DIR = "./result/{0}/data/".format(g_dir)
    i = 1
    #print "\nlist dir under dir: {0}".format(IN_DIR)
    for lists in os.listdir(IN_DIR):
        path = os.path.join(IN_DIR, lists)
        if os.path.isdir(path):
            #print "\n{0}: list file under dir: {1}".format(idx,d)
            for lists in os.listdir(path):
                try:
                    f = os.path.join(path, lists)
                    if os.path.isfile(f):
                        parse_data(i,f)
                except:
                    continue
        i = i + 1

############ main #################

if len(sys.argv)<2:
    show_usage()

#start parse parameter
parser = argparse.ArgumentParser()
parser.add_argument("-d","--dir",action="store_true",required=True)
parser.add_argument("-s","--sort",action="store_true",default=False)
parser.add_argument("-f","--format",type=str,default="table",choices=["table","json"])
args = parser.parse_args()

#check sort
if args.sort:
    g_sort=args.sort
if args.format:
    g_format=args.format
if args.dir:
    g_dir=args.dir

read_data()
show_data()
