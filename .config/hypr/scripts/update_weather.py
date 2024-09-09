#!/bin/python3

import json
import os
import re
import time
from pathlib import Path

import requests

#
# --- Variablen
#
wttrcache = Path("/tmp/.wttr.cache")
ipcache = Path("/tmp/.ip.cache")
wttrurl = "http://de.wttr.in/"
ipurl = "http://ipinfo.io"
wttrformat = "?format=%l:%c:%C:%t:%f:%h:%w"
expiretime = 600
ifaceignore = ["virbr", "lo"]
localif = []
localip = []


#
# --- functions
#
def cacherefresh(file):
    if file.is_file():
        cachemtime = os.stat(file)[-2]
        ctime = int(time.time())
        if ctime - cachemtime > expiretime:
            return True
        else:
            return False
    else:
        return True


def saveweather(wttrdata):
    with open(wttrcache, "w") as filehandler:
        for line in wttrdata:
            filehandler.write("".join(line) + ":")


def getlocation():
    try:
        res = requests.get(ipurl)
    except:
        res = {
            "ip": "offline",
            "hostname": "AmpadaL027",
            "country": "DE",
            "city": "Köln",
        }
        data = json.loads(json.dumps(res))
        return data
    tdat = json.dumps(res.json())
    data = json.loads(tdat)
    return data


def getweather():
    if cacherefresh(ipcache):
        ipdata = getlocation()
    else:
        if ipcache.is_file():
            with open(ipcache) as filehandler:
                ipdata = json.load(filehandler)
        else:
            exit(1)
    city = ipdata["city"]
    if city == "Eschborn":
        city = "Köln"
    try:
        res = requests.get(wttrurl + city + wttrformat).text
    except:
        res = "off"
        # exit(1)
    return res


if cacherefresh(ipcache):
    ipdata = getlocation()
    with open(ipcache, "w") as filehandler:
        json.dump(ipdata, filehandler)

if cacherefresh(wttrcache):
    wttr = re.split(":", getweather())
    saveweather(wttr)
