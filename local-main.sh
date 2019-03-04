#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

UUID=$(uuidgen)

# Create the Cloudformation VPC-only stack from the local template `cloudformation-vpc.yaml`
VPC_STACK_NAME="aws-wrk-athena-${UUID}"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"
aws cloudformation create-stack \
  --stack-name "${VPC_STACK_NAME}" \
  --template-body file://cloudformation-vpc.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

echo "Waiting until the Cloudformation stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name "${VPC_STACK_NAME}"

for params in $(jq -c '.[]' local-parameters.json)
do
    ./local-commands.sh \
        --test-exec-uuid "${UUID}" \
        --test-seq-num "$(echo ${params} | jq '.test_seq_num')"\
        --wrk-local-ip "$(echo ${params} | jq '.wrk_local_ip')" \
        --web-local-ip "$(echo ${params} | jq '.web_local_ip')" \
        --wrk-instance-type "$(echo ${params} | jq '.wrk_instance_type')" \
        --web-instance-type "$(echo ${params} | jq '.web_instance_type')" \
        --web-framework "$(echo ${params} | jq '.web_framework')" &
done
wait


