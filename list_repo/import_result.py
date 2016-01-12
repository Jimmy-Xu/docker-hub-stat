#!/usr/bin/python

import time
import os
import sys
import json
import argparse

import dateutil.parser
from pymongo import MongoClient

g_result=[]

def read_repo(data_dir):
    global db

    IN_DIR = "list_result/{0}".format(data_dir)
    i = 0

    #connect to mongo
    client = MongoClient('localhost', 27017)
    db = client.docker

    #re-create list_repo
    db.drop_collection("list_repo")
    db.create_collection("list_repo")

    #ensure index(important)
    db.list_repo.create_index("name")
    db.list_repo.create_index("image_name")
    db.list_repo.create_index("user")
    db.list_repo.create_index("star_count")
    db.list_repo.create_index("pull_count")

    ##print "\nlist dir under dir: {0}".format(IN_DIR)
    #level 1(search key dir)
    for search_key in os.listdir(IN_DIR):
        key_path = os.path.join(IN_DIR, search_key)
        if os.path.isdir(key_path):
            ##print "\tlist file under dir: {0}".format(key_path)
            #level 2(result dir)
            for page_file in os.listdir(key_path):
                if page_file.endswith('.json'):
                #if page_file == "1.json":
                    i = i + 1
                    try:
                        #print "\t\t {0}:import data from file: {1}".format(i,page_file)
                        parse_and_import(i, IN_DIR, search_key, page_file)
                    except:
                        continue
            # if i>2:
            #     break

def parse_and_import(idx, base_dir, search_key, page_file):
    global g_result
    global db

    f="{0}/{1}/{2}".format(base_dir,search_key,page_file)
    print "\t\t\t {0}: read data from file: {1}".format(idx, f)
    with open(f) as data_file:
        data = json.load(data_file)

    if "results" not in data:
        print "wrong data format in file: {0}".format(f)
    else:
        #no dup, multiple insert
        cache_ary=[]
        for item in data["results"]:
            item["image_name"] = "{0}/{1}".format(str(item["user"]),str(item["name"]) )
            cache_ary.append(item)
        if cache_ary:
            db.list_repo.insert(cache_ary)

#### main #####
#start parse parameter
parser = argparse.ArgumentParser()
parser.add_argument("-d","--data_dir",type=str,required=True)
args = parser.parse_args()

#start
read_repo(args.data_dir)
