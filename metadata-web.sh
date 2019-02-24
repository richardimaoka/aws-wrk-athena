#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#   Cloudformation related parameters:
#    --test-exec-uuid A UUID representing a group of Cloudformation stacks for test execution
#    --bucket         An S3 bucket name where the results are stored
for OPT in "$@"
do
    case "$OPT" in
        '--bucket' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --bucket requires an argument -- $1" 1>&2
                exit 1
            fi
            BUCKET_NAME="$2"
            shift 2
            ;;
        '--test-exec-uuid' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --test-exec-uuid requires an argument -- $1" 1>&2
                exit 1
            fi
            TEST_EXECUTION_UUID="$2"
            shift 2
            ;;
        -*)
            echo "wrk: illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;

    esac
done

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instancedata-data-retrieval
# 169.254.169.254 is a special (loopback?) address for EC2 metadat

AMI_ID=$(curl http://169.254.169.254/latest/meta-data/ami-id 2> /dev/null)
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)
INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type 2> /dev/null)
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname 2> /dev/null)
LOCAL_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname 2> /dev/null)
LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4 2> /dev/null)
PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname 2> /dev/null)
PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4 2> /dev/null)

echo "{ \
  \"metadata.web_server.ami_id\":          \"$AMI_ID\", \
  \"metadata.web_server.instance_id\":     \"$INSTANCE_ID\", \
  \"metadata.web_server.instance_type\":   \"$INSTANCE_TYPE\", \
  \"metadata.web_server.hostname\":        \"$HOSTNAME\", \
  \"metadata.web_server.local_hostname\":  \"$LOCAL_HOSTNAME\", \
  \"metadata.web_server.local_ipv4\":      \"$LOCAL_IPV4\", \
  \"metadata.web_server.public_hostname\": \"$PUBLIC_HOSTNAME\", \
  \"metadata.web_server.public_ipv4\":     \"$PUBLIC_IPV4\" \
}" > "metadata.${LOCAL_IPV4}.json"

# On Amazon Linux, AWS CLI is already installed
# Note that an instance profiler setup is needed to execute AWS CLI on EC2
aws s3 mv \
  "metadata.${LOCAL_IPV4}.json" \
  "s3://${BUCKET_NAME}/${TEST_EXECUTION_UUID}/metadata.${LOCAL_IPV4}.json"