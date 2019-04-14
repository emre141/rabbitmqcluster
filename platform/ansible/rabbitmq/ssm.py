import boto3
import botocore
import os

## Get SSM
session = boto3.Session(region_name='eu-central-1')
ssm = session.client('ssm')

result = ssm.get_parameter(Name='rabbitmq_cookie', WithDecryption=True)


#alphabetically ordered
print format(result['Parameter']['Value'])  #rabbitmq_cookie