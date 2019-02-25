#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument   
#  --test-exec-uuid: A UUID representing a group of Cloudformation stacks for test execution
# (argument)       : Web server's VPC local IP
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
        '--bucket' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --bucket requires an argument -- $1" 1>&2
                exit 1
            fi
            BUCKET_NAME="$2"
            shift 2
            ;;            
        -*)
            echo "wrk: illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ -n "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                WEB_SERVER_LOCAL_IP="$1"
                break
            fi
            ;;
    esac
done

STACK_NAME="aws-wrk-athena-${TEST_EXECUTION_UUID}-1"
BUCKET_NAME="samplebucket-richardimaoka-sample-sample"

WRK_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:aws:cloudformation:stack-name,Values=${STACK_NAME}" "Name=instance-state-name,Values=running" "Name=tag:Name,Values=web-server-instance" --output text --query "Reservations[*].Instances[*].InstanceId")

aws ssm send-command \
  --instance-ids "${WRK_INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "aws-wrk-athena command to run wrk" \
  --parameters commands=["/home/ec2-user/aws-wrk-athena/aggregate-result.sh --bucket ${BUCKET_NAME} --test-exec-uuid ${TEST_EXECUTION_UUID}"] \
  --output text \
  --query "Command.CommandId"

