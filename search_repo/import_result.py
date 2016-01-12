#!/usr/bin/python

import time
import os
import sys
import json
import argparse

import dateutil.parser
from prettytable import PrettyTable
from pymongo import MongoClient

g_result=[]

def read_repo():
    global db

    IN_DIR = "search_result"
    i = 0

    #connect to mongo
    client = MongoClient('localhost', 27017)
    db = client.docker

    #re-create search_repo
    db.drop_collection("search_repo")
    db.create_collection("search_repo")

    #ensure index(important)
    db.search_repo.create_index("name")
    db.search_repo.create_index("star_count")
    db.search_repo.create_index("search_count")

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
        for item in data["results"]:
            item["name"] = str(item["name"])
            #check if name is already is existed
            found = db.search_repo.find_one(
                {
                    "name": item["name"]
                }
            )
            if found:
                found["search_key"].append(search_key)
                found["search_count"] = len(found["search_key"])
                found["search_key_str"] = "|".join(found["search_key"])
                #print "found image name '{0}' {1} times".format(item["name"], len(found["search_key"]))
                result = db.search_repo.update_one(
                    {
                        "name": item["name"]
                    },
                    {
                        '$set':{
                            "search_key": found["search_key"],
                            "search_count":found["search_count"],
                            "search_key_str":str(found["search_key_str"])
                        }
                    }
                )
                if not (result and result.raw_result['ok']):
                    print "update existed image info failed: {0}".format(item["name"])
                    continue
            else:
                item["search_key"] = []
                item["search_key"].append(search_key)
                item["search_key_str"] = "|".join(item["search_key"])
                item["search_count"] = 1
                db.search_repo.insert_one(item)

#### main #####
read_repo()
