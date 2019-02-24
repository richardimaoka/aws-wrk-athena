#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#   Cloudformation related parameters:
#    --test-exec-uuid    A UUID representing a group of Cloudformation stacks for test execution
#    --test-seq-num      A sequence number within the test group represented by the UUID
#    --wrk-local-ip      VPC-Local IP address for the wrk EC2 instance
#    --web-local-ip      VPC-Local IP address for the web server EC2 instance
#    --wrk-instance-type EC2 instance type for wrk
#    --web-instance-type EC2 instance type for the web server
#    --web-framework     web framework name to test

for OPT in "$@"
do
    case "$OPT" in
        '--test-exec-uuid' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --test-exec-uuid requires an argument -- $1" 1>&2
                exit 1
            fi
            TEST_EXECUTION_UUID="$2"
            shift 2
            ;;
        '--test-seq-num' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --test-seq-num requires an argument -- $1" 1>&2
                exit 1
            fi
            TEST_SEQ_NUM="$2"
            shift 2
            ;;
        '--wrk-local-ip' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --wrk-local-ip requires an argument -- $1" 1>&2
                exit 1
            fi
            WRK_LOCAL_IP="$2"
            shift 2
            ;;
        '--web-local-ip' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --web-local-ip requires an argument -- $1" 1>&2
                exit 1
            fi
            WEB_SERVER_LOCAL_IP="$2"
            shift 2
            ;;
        '--wrk-instance-type' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --wrk-instance-type requires an argument -- $1" 1>&2
                exit 1
            fi
            WRK_INSTANCE_TYPE="$2"
            shift 2
            ;;
        '--web-instance-type' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --web-instance-type requires an argument -- $1" 1>&2
                exit 1
            fi
            WEB_INSTANCE_TYPE="$2"
            shift 2
            ;;
        '--web-framework' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --web-framework requires an argument -- $1" 1>&2
                exit 1
            fi
            WEB_FRAMEWORK="$2"
            shift 2
            ;;
        -*)
            echo "wrk: illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;

    esac
done

STACK_NAME="aws-wrk-athena-${TEST_EXECUTION_UUID}-${TEST_SEQ_NUM}"
SSH_LOCATION="$(curl ifconfig.co 2> /dev/null)/32"

# Create the Cloudformation stack from the local template `cloudformation.yaml`
aws cloudformation create-stack \
  --stack-name "${STACK_NAME}" \
  --template-body file://cloudformation.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=EC2InstanceTypeWrk,ParameterValue=${WRK_INSTANCE_TYPE} \
               ParameterKey=EC2InstanceTypeWebServer,ParameterValue=${WEB_INSTANCE_TYPE} \
               ParameterKey=IPAddressWrk,ParameterValue="${WRK_LOCAL_IP}" \
               ParameterKey=IPAddressWebServer,ParameterValue="${WEB_SERVER_LOCAL_IP}" \
               ParameterKey=SSHLocation,ParameterValue="${SSH_LOCATION}"

echo "Waiting until the Cloudformation stack is CREATE_COMPLETE"
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

# Make sure the web EC2 instance is up and running
WEB_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=${STACK_NAME}" "Name=instance-state-name,Values=running" "Name=tag:Name,Values=web-server-instance" --output text --query "Reservations[*].Instances[*].InstanceId")
echo "Waiting until the following web-server EC2 instance is OK: ${WEB_INSTANCE_ID}"
aws ec2 wait instance-status-ok --instance-ids ${WEB_INSTANCE_ID}

echo "Runnig a remote command to save web-server EC2 metadata to S3 from ${WEB_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${WEB_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["/home/ec2-user/aws-wrk-athena/metadata-web.sh ${TEST_EXECUTION_UUID}"]

# Make sure the web EC2 instance is up and running
WRK_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=${STACK_NAME}" "Name=instance-state-name,Values=running" "Name=tag:Name,Values=wrk-instance" --output text --query "Reservations[*].Instances[*].InstanceId")
echo "Waiting until the following wrk EC2 instance is OK: ${WRK_INSTANCE_ID}"
aws ec2 wait instance-status-ok --instance-ids ${WRK_INSTANCE_ID}

echo "Runnig a remote command to crate a result file and copy it from EC2 to S3 on ${WRK_INSTANCE_ID}"
aws ssm send-command \
  --instance-ids "${WRK_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["/home/ec2-user/aws-wrk-athena/run-main.sh --test-exec-uuid ${TEST_EXECUTION_UUID} ${WEB_SERVER_LOCAL_IP}"]

# Go to the following page and check the command status:
# https://console.aws.amazon.com/ec2/v2/home?#Commands:sort=CommandId
