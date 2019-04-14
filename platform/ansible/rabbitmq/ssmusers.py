import boto3
import botocore
import os
import json

## Get SSM
users = [('paramter1','paramter2'), ('paramter3', 'paramter4'), ('paramter5','paramter6')]
rabbitmqusers = {}
session = boto3.Session(region_name='<region_name>')
ssm = session.client('ssm')
index = 0
for ssmuser,ssmpass  in users:
    result = ssm.get_parameters(Names=[ssmpass,ssmuser], WithDecryption=True)
    username = result['Parameters'][1]['Value']
    password = result['Parameters'][0]['Value']
    rabbitmqusers[username] = password

print rabbitmqusers