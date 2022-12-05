#!/usr/local/bin/python3

import requests
import os
import subprocess
import json
import ovh
import time
import sys

########################################################################
#     VARS
########################################################################

# Prerequisites : Create api set of keys at https://www.ovh.com/auth/api/createToken

# Application name : pst_backup
# Application description : pst_backup
# Rights :
#   GET /email/exchange/*
#   POST /email/exchange/*

client = ovh.Client(
    endpoint='ovh-eu',               # Endpoint of API OVH Europe (List of available endpoints)
    application_key='',                       # Application Key
    application_secret='',    # Application Secret
    consumer_key='',          # Consumer Key
)
organization_name = ""
primary_email_address = ""
exchange_service = ""
pst_dir = '/var/services/homes/XX/pstsave/'
#pst_dir = 'D:/temp/pstbackuptest/'


########################################################################
#     1) Request PST file for account
########################################################################

try:
    print("1) Request PST file for account")
    result_req_pst_file = client.post(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/export')
    print(json.dumps(result_req_pst_file))
    print("1) Request PST file for account - Complete")
    time.sleep(30)
except:
    print("1) Force Delete pst request")
    result = client.delete(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/export')
    print("1) Force Delete pst request - Complete")
    time.sleep(30)
    print("1) Request PST file for account")
    result_req_pst_file = client.post(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/export')
    print(json.dumps(result_req_pst_file))
    print("1) Request PST file for account - Complete")
    time.sleep(30)


########################################################################
#     2) Wait for percentage 100
########################################################################

print("2) Wait for percentage 100")
while True:
    result_perc_check = client.get(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/export')
    print(result_perc_check)
    if int(result_perc_check['percentComplete']) != 100:
        print("2) Wait for percentage 100")
        time.sleep(10*60)
    else:
        print("2) Wait for percentage 100 - Complete")
        break


########################################################################
#     3) Generate export URL
########################################################################

print("3) Generate export URL")
result_gen_url = client.post(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/exportURL')
print(json.dumps(result_gen_url))
time.sleep(30)

print("3) Generate export URL - Complete")


########################################################################
#     4) Get export URL link
########################################################################

print("4) Get export URL link")
result_export_link = client.get(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/exportURL')
print(json.dumps(result_export_link))
print("4) Get export URL link - Complete")


########################################################################
#     5) Download the pst file
########################################################################

print("5) Download the pst file")
r = requests.get(result_export_link["url"])
with open(f'{pst_dir}{primary_email_address}.pst', 'wb') as f:
    f.write(r.content)
print("5) Download the pst file - Complete")

########################################################################
#     6) Delete pst request
########################################################################

print("6) Delete pst request")
result = client.delete(f'/email/exchange/{organization_name}/service/{exchange_service}/account/{primary_email_address}/export')
print("6) Delete pst request - Complete")
