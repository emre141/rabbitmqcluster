#!/usr/bin/env bash

if [ "$1" == "create" ];then

    aws configure set region us-east-1
    export elb_external_arn=`terraform output elb_external_arn`
    export elb_internal_arn=`terraform output elb_internal_arn`


    protection_id_for_elb_external_arn=$(aws shield list-protections --query  "Protections[?ResourceArn == '$elb_external_arn']" | grep Id | awk '{print $2}' | tr -d \'\"\,)
    protection_id_for_elb_internal_arn=$(aws shield list-protections --query  "Protections[?ResourceArn == '$elb_internal_arn']" | grep Id | awk '{print $2}' | tr -d \'\"\,)


    if [[  -z "$protection_id_for_elb_external_arn" ]];then
        aws shield create-protection --name rabbitmq_elb_external_protection-$asg_instance_tag --resource-arn $elb_external_arn
    fi
    if [[  -z "$protection_id_for_elb_internal_arn" ]];then
        aws shield create-protection --name rabbitmq_elb_internal_protection-$asg_instance_tag --resource-arn $elb_internal_arn
    fi
    aws configure set region $AWS_REGION

elif [ "$1" == "delete" ];then

    elb_external_arn=$2
    elb_internal_arn=$3


    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set region us-east-1
    protection_id_for_elb_external_arn=$(aws shield list-protections --query  "Protections[?ResourceArn == '$elb_external_arn']" | grep Id | awk '{print $2}' | tr -d \'\"\,)
    protection_id_for_elb_internal_arn=$(aws shield list-protections --query  "Protections[?ResourceArn == '$elb_internal_arn']" | grep Id | awk '{print $2}' | tr -d \'\"\,)

    if [[ ! -z "$protection_id_for_elb_external_arn" ]];then
        aws shield delete-protection --protection-id $protection_id_for_elb_external_arn
    fi
    if [[ ! -z "$protection_id_for_elb_internal_arn" ]];then
        aws shield delete-protection --protection-id $protection_id_for_elb_internal_arn
    fi
fi