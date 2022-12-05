#!/usr/local/bin/python3
import requests
import os
import subprocess

# Config panel -> Task Scheduler -> Execution details via mails

OAUTH_TOKEN = ""
BACKUP_PATH = "/volume1/homes/mempoule/gitsave"
API_URL = f"https://api.github.com/user/repos?type=all&per_page=100"
GITUSER = "mempoule"
GIT = "/volume1/@appstore/Git/bin/git"


def get_repos():
    response = requests.get(API_URL, headers={'Authorization': f"token {OAUTH_TOKEN}"})
    for repo in response.json():
        print(repo['name'])
        try:
            os.mkdir(f"{BACKUP_PATH}/{repo['name']}")
            subprocess.run(["git", "clone", repo['ssh_url'], f"{BACKUP_PATH}/{repo['name']}"])
        except FileExistsError:
            os.chdir(f"{BACKUP_PATH}/{repo['name']}")
            subprocess.run(["git", "pull"])


get_repos()
