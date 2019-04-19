import socket
import ssl, boto3
import re,sys,os,datetime
import dateutil

healthcheck_namespace = "RabbitMQ Health Check Metrics"

def ssl_expiry_date(domainname):
    ssl_date_fmt = r'%b %d %H:%M:%S %Y %Z'
    context = ssl.create_default_context()
    conn = context.wrap_socket(
        socket.socket(socket.AF_INET),
        server_hostname=domainname,
    )
    # 3 second timeout because Lambda has runtime limitations
    conn.settimeout(5.0)
    conn.connect((domainname, 8883))
    ssl_info = conn.getpeercert()
    return datetime.datetime.strptime(ssl_info['notAfter'], ssl_date_fmt).date()

def ssl_valid_time_remaining(domainname):
    """Number of days left."""
    expires = ssl_expiry_date(domainname)
    return expires - datetime.datetime.utcnow().date()

def sns_Alert(dName, eDays, sslStatus, sns_topic_arn):
    sslStat = dName + ' SSL certificate will be expired in ' + eDays +' days!! '
    snsSub = dName + ' SSL Certificate Expiry ' + sslStatus + ' alert'
    print sslStat
    print snsSub
    response = client.publish(
        TargetArn= sns_topic_arn,
        Message= sslStat,
        Subject= snsSub
    )


##### Main Section
def lambda_handler(event, context):
    sns_client = boto3.client('sns')
    cw_client = boto3.client('cloudwatch')
    ssl_expire_put_cw(event,cw_client,sns_client)

def ssl_expire_put_cw(event,cw,sns):
    sns_topic_arn = event["sns_topic_arn"]
    url_name = event["url_name"]
    service_name = event["service_name"]
    print sns_topic_arn
    f = [url_name]
    for dName in f:
        print(dName)
        expDate = ssl_valid_time_remaining(dName.strip())
        (a, b) = str(expDate).split(',')
        (c, d) = a.split(' ')
        print(a,b,c,d)
        print(int(c))
        # Critical alerts
        if int(c) < 15:
            sns_Alert(dName, str(c), 'Critical', sns_topic_arn)
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)
        # First critical alert on 20 th day
        elif int(c) == 20:
            sns_Alert(dName, str(c), 'Critical', sns_topic_arn)
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)
        #third warning alert on 30th day
        elif int(c) == 30:
            sns_Alert(dName, str(c), 'Warning' ,sns_topic_arn)
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)
        #second warning alert on 40th day
        elif int(c) == 40:
            sns_Alert(dName, str(c), 'Warning', sns_topic_arn)
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)
        #First warning alert on 50th day
        elif int(c) == 50:
            sns_Alert(dName, str(c), 'Warning', sns_topic_arn)
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)
        else:
            print('Everything Fine..')
            put_metric_to_cw(cw,"ServiceName", service_name, "SSLExpireDays", int(c), healthcheck_namespace)

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
