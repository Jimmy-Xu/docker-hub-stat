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

def parse_tag(base_dir, user_dir, repo_dir, page_file):
    global g_result
    f="{0}/{1}/{2}/{3}".format(base_dir,user_dir,repo_dir,page_file)
    #print "read data from file: {0}".format(f)
    with open(f) as data_file:
        data = json.load(data_file)
    repo_name = repo_dir

    if "results" not in data:
        print "wrong data format in file: {0}".format(f)
    else:
        for item in data["results"]:
            item["repo_name"] = repo_name
            item["namespace"] = user_dir
            g_result.append(item)

def read_tag():
    IN_DIR = "list_result"
    i = 1

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
                                    parse_tag(IN_DIR, user_dir, repo_dir, page_file)
                            except:
                                continue
                except:
                    continue
        i = i + 1

def import_tag():
    global g_result

    if g_result:
        client = MongoClient('localhost', 27017)
        db = client.docker
        print "drop old data in tag collection"
        db.list_tag.drop()
        db.create_collection("list_tag")
        print "start_time:{0}".format(time.strftime('%Y-%m-%d %H:%M:%S'))
        db.list_tag.insert(g_result)
        print "end_time:{0}".format(time.strftime('%Y-%m-%d %H:%M:%S'))
    else:
        print "There is no data to import"

#### main #####
read_tag()
import_tag()
