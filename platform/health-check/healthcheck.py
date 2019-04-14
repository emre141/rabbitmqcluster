import boto3
import datetime
import dateutil
import json
from botocore.vendored import requests


healthcheck_namespace = "RabbitMQ Health Check Metrics"

def lambda_handler(event, context):
    cw_client = boto3.client('cloudwatch')
    ssm_client = boto3.client('ssm')
    health_check_function(event,cw_client,ssm_client)
    rabbitmq_api_metric(event,cw_client,ssm_client)

def get_ssm_parameters(event,ssm):
    return ssm.get_parameters( Names=['rabbitmq_username','rabbitmq_password'], WithDecryption=True)


def rabbitmq_api_metric(event,cw,ssm,trial=1):
    url_name = event["url_name"]
    service_name = event["service_name"]  # RabbitMQ-Team7/Team8, comes from cw event target
    credentials = get_ssm_parameters(event,ssm)
    username = credentials['Parameters'][1]['Value']
    password = credentials['Parameters'][0]['Value']
    apiendpoint = ['cluster-name','nodes']
    for endpoint in apiendpoint:
        try:
            response = requests.get("https://"+ url_name + "/api/" + endpoint, auth=requests.auth.HTTPBasicAuth(username, password), timeout=5)
            print("Response status code:" + str(response.status_code))
            try:
                if endpoint == "cluster-name":
                    cluster_name = response.json()['name']
                else:
                    cluster_node_count = len(response.json())
                    put_metric_to_cw(cw,"ServiceName", service_name, "ClusterNodeCount", cluster_node_count, healthcheck_namespace)
            except json.decoder.JSONDecodeError as e:
                print("Json decode error: " + str(e))
        except requests.exceptions.Timeout as e:
            if trial <=3:
                print("Response Timeout Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
                return rabbitmq_api_metric(event,cw,ssm,trial=trial+1)
        except requests.exceptions.ConnectionError as e:
            if trial <=3:
                print("Response Connection Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
                return rabbitmq_api_metric(event,cw,ssm,trial=trial+1)
        except requests.exceptions.RequestException as e:
            if trial <=3:
                print("Request Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
                return rabbitmq_api_metric(event,cw,ssm, trial=trial+1)
    print("Cluster Name:" + str(cluster_name))
    put_metric_to_cw(cw,"ServiceName", service_name, "ClusterNodeCount", cluster_node_count, healthcheck_namespace)


def health_check_function(event,cw,ssm,trial=1):
    url_name = event["url_name"]
    service_name = event["service_name"]  #  RabbitMQ-Team7/Team8, comes from cw event target
    datapoint_for_health_status = 0 # coming from aliveness endpoint
    credentials = get_ssm_parameters(event,ssm)
    username = credentials['Parameters'][1]['Value']
    password = credentials['Parameters'][0]['Value']

    try:
        response = requests.get("https://"+ url_name + "/api/aliveness-test/%2F", auth=requests.auth.HTTPBasicAuth(username, password))
        print("Response status code :" + str(response.status_code))

        try:
            data = response.json()
            status = data["status"]
            if status == "ok":
                print('HealthCheck --> 200. Service is UP')
                datapoint_for_health_status = 1

        except (json.decoder.JSONDecodeError, KeyError):
            print("INFO: JSON cannot be decoded")


        #print ("Health status: " + str(datapoint_for_health_status))

        #Sending healthCheck to health check metric space
        #put_metric_to_cw(cw,"ServiceName",service_name,"HealthCheck",datapoint_for_health_status,healthcheck_namespace)

    except requests.exceptions.Timeout as e:
        if trial <=3:
            print("Response Timeout Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
            return health_check_function(event,cw,ssm,trial=trial+1)
    except requests.exceptions.BaseHTTPError as e:
        if trial <= 3:
            print("Response HTTP Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
            return health_check_function(event, cw, ssm, trial=trial + 1)
        #Sending healthCheck to health check metric space
    except requests.exceptions.ConnectionError as e:
        if trial <= 3:
            print("Response Connection Error: " + str(e) + ', trial' + str(trial) + 'Reason' + str(e))
            return health_check_function(event, cw, ssm, trial=trial + 1)

    print ("Health status: " + str(datapoint_for_health_status))
    put_metric_to_cw(cw,"ServiceName",service_name,"HealthCheck",datapoint_for_health_status,healthcheck_namespace)


def put_metric_to_cw(cw,dimension_name,dimension_value,metric_name,metric_value,namespace):
    cw.put_metric_data(
        Namespace=namespace,
        MetricData=[{
            'MetricName': metric_name,
            'Dimensions': [{
                'Name': dimension_name,
                'Value': dimension_value
            }],
            'Timestamp': datetime.datetime.now(dateutil.tz.tzlocal()),
            'Value': metric_value
        }]
    )