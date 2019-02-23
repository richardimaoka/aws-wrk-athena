#!/bin/bash

WEB_SERVER_LOCAL_IP="10.0.0.212"
STACK_NAME="aws-cloudformation-wrk-1"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# Create the Cloudformation stack from the local template `cloudformation.yaml`
SSH_LOCATION="$(curl ifconfig.co)/32"
aws cloudformation create-stack \
  --stack-name "${STACK_NAME}" \
  --template-body file://cloudformation.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=EC2InstanceType,ParameterValue=m5.2xlarge \
               ParameterKey=IPAddressWebServer,ParameterValue="${WEB_SERVER_LOCAL_IP}" \
               ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"
# This produces output like below:  
# {
#   "StackId": "arn:aws:cloudformation:ap-northeast-1:795483015259:stack/aws-cloudformation-wrk.10.0.0.212/e02c0f30-35d9-11e9-943d-0aa3c9b7e68c"
# }

echo "Waiting until the Cloudformation stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

# Get list of EC2 instance IDs
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=${STACK_NAME}" "Name=instance-state-name,Values=running" --output text --query "Reservations[*].Instances[*].InstanceId")
# The above result is flattened array in multi-line output 
#   i-0b852411111111111
#   i-0b852422222222222
#   i-0b852433333333333
# Turn the multi-line result into a single line
INSTANCE_IDS=$(echo "$INSTANCE_IDS" | paste -sd " ")

# Make sure all the EC2 instances in the Cloudformation stack are up and running
echo "Waiting until the following EC2 instances are OK: $INSTANCE_IDS"
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_IDS"

# Get list of EC2 instance IDs
WRK_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=${STACK_NAME}" "Name=instance-state-name,Values=running" "Name=tag:Name,Values=wrk-instance" --output text --query "Reservations[*].Instances[*].InstanceId")

echo "Runnig a remote command to crate a result file and copy it from EC2 to S3"
aws ssm send-command \
  --instance-ids "$WRK_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["/home/ec2-user/aws-cloudformation-wrk/run-wrk.sh -d 30 -c 4 -t 4 http://${WEB_SERVER_LOCAL_IP}"]  

# Go to the following page and check the command status:
# https://console.aws.amazon.com/ec2/v2/home?#Commands:sort=CommandId