#!/bin/python3

import json
import re
import sys
from pathlib import Path

import netifaces as ni

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
def loadweather():
    if wttrcache.is_file():
        with open(wttrcache, "r") as rf:
            return rf.readline()
    else:
        return ""


def is_iface_up(iface):
    addr = ni.ifaddresses(iface)
    return ni.AF_INET in addr


def get_iface_addr(iface):
    return ni.ifaddresses(iface)[ni.AF_INET][0]["addr"]


#
# --- main
#
if len(sys.argv) > 1:
    if len(sys.argv) < 3:
        match sys.argv[1]:
            case "ip" | "-ip" | "--ip":
                if ipcache.is_file():
                    with open(ipcache) as filehandler:
                        ipdata = json.load(filehandler)
                else:
                    exit(1)
                wanip = ipdata["ip"]
                for iface in ni.interfaces():
                    if any(x in iface for x in ifaceignore):
                        continue
                    if is_iface_up(iface):
                        ifaddr = get_iface_addr(iface)
                        localif.append(iface)
                        localip.append(ifaddr)
                output = '{"text": "WAN:\t'
                output += f"{wanip}"
                for x in range(len(localif)):
                    output += f"\r{localif[x]}:\t{localip[x]}"
                output += '"}'
                print(repr(output).replace("'", ""))
                exit(0)
            case "location" | "-location" | "--location":
                if ipcache.is_file():
                    with open(ipcache) as filehandler:
                        ipdata = json.load(filehandler)
                else:
                    exit(1)
                country = ipdata["country"]
                city = ipdata["city"]
                if city == "Eschborn":
                    city = "Köln"
                print(f"{country}, {city}")
                exit(0)
            case "waybar" | "-waybar" | "--waybar":
                wttr = re.split(":", loadweather())
                wttrlen = len(wttr)
                if wttrlen < 4:
                    waybar = (
                        '{"text": "offline"'
                        ', "alt": "", "tooltip": "Service Offline"'
                        "}"
                    )
                else:
                    waybar = (
                        '{"text": '
                        f'"{wttr[3]}"'
                        ', "alt": ""'
                        ', "tooltip": '
                        f'"{wttr[0]}\t{wttr[2]}\r'
                        f"\t{wttr[3]} ({wttr[4]})\r"
                        f'\t{wttr[5]} {wttr[6]}"'
                        "}"
                    )
                print(repr(waybar).replace("'", ""))
                exit(0)
            case "weather" | "-weather" | "--weather":
                wttr = re.split(":", loadweather())
                wttrlen = len(wttr)
                if wttrlen < 4:
                    print("Service Offline")
                else:
                    print(f"{wttr[1]}{wttr[2]} {wttr[3]}")
                exit(0)
            case _:
                print("ups")
                exit(1)
    else:
        print("to many params")
        exit(2)
else:
    print("no param")
