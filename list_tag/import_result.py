#!/usr/bin/python

import time
import os
import sys
import json
import argparse

import dateutil.parser
from pymongo import MongoClient

global db

def parse_and_import(base_dir, user_dir, repo_dir, page_file):
    global db
    f="{0}/{1}/{2}/{3}".format(base_dir,user_dir,repo_dir,page_file)
    #print "read data from file: {0}".format(f)
    with open(f) as data_file:
        data = json.load(data_file)
    repo_name = repo_dir

    if "results" not in data:
        print "wrong data format in file: {0}".format(f)
    else:
        cache_ary=[]
        for item in data["results"]:
            item["_repo_name"] = repo_name
            item["_namespace"] = user_dir
            item["_image_name"] = "{0}/{1}".format(item["_namespace"],item["_repo_name"])
            cache_ary.append(item)
        if cache_ary:
            print "insert {0} image tags into db".format(len(cache_ary))
            result = db.list_tag.insert(cache_ary)

def read_tag():
    global db
    IN_DIR = "list_result"
    i = 1

    #connect to mongo
    client = MongoClient('localhost', 27017)
    db = client.docker

    #re-create list_tag
    db.drop_collection("list_tag")
    db.create_collection("list_tag")

    #ensure index(important)
    db.list_tag.create_index("_namespace")
    db.list_tag.create_index("_repo_name")
    db.list_tag.create_index("name")

    ##print "\nlist dir under dir: {0}".format(IN_DIR)
    #level 1(user dir)
    for user_dir in os.listdir(IN_DIR):
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
                                    parse_and_import(IN_DIR, user_dir, repo_dir, page_file)
                            except:
                                continue
                except:
                    continue
            # if i>1:
            #     break
        i = i + 1

#### main #####
print "start_time:{0}".format(time.strftime('%Y-%m-%d %H:%M:%S'))
read_tag()
print "end_time:{0}".format(time.strftime('%Y-%m-%d %H:%M:%S'))
