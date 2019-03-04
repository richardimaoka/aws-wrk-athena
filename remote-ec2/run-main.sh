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

# Copy the web server metadata to the current directory
echo "waiting for the metadata.${WEB_SERVER_LOCAL_IP}.json file to be ready in S3"
aws s3api wait object-exists \
  --bucket "${BUCKET_NAME}" \
  --key "${TEST_EXECUTION_UUID}/metadata.${WEB_SERVER_LOCAL_IP}.json"
aws s3 cp \
  "s3://${BUCKET_NAME}/${TEST_EXECUTION_UUID}/metadata.${WEB_SERVER_LOCAL_IP}.json" \
  "metadata.${WEB_SERVER_LOCAL_IP}.json"

# Produce the file to concat all the results on this EC2 instance
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instancedata-data-retrieval
# 169.254.169.254 is a special (loopback?) address for EC2 metadat
LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

#############################################################
# From here, you can execute whatever test scenarios you like
#############################################################
# Test scenario 1.
# Run wrk and append the result to "result-${LOCAL_IPV4}.log"
./run-wrk.sh --web-framework nginx --test-case simple -t 4 -c 4 -d 15 "http://${WEB_SERVER_LOCAL_IP}/"
# Amazon Athena handles **single-line** JSON only due to 'org.openx.data.jsonserde.JsonSerDe'
#   https://docs.aws.amazon.com/athena/latest/ug/parsing-JSON.html
#   > Make sure that each JSON-encoded record is represented on a separate line.
# so using -c to put each test case results into a single line:
jq -s '.[0] * .[1]' "metadata.${WEB_SERVER_LOCAL_IP}.json" result.json | jq -c "." > "result-${LOCAL_IPV4}.log"

# Test scenario 2.
# Possibly run other test cases too
./run-wrk.sh --web-framework nginx --test-case simple -t 8 -c 8 -d 15 "http://${WEB_SERVER_LOCAL_IP}/"
# Append the results
jq -s '.[0] * .[1]' "metadata.${WEB_SERVER_LOCAL_IP}.json" result.json | jq -c "." >> "result-${LOCAL_IPV4}.log"

# Test scenario 3.
# ./run-wrk.sh --web-framework nginx --test-case simple -t 16 -c 16 -d 15 "http://${WEB_SERVER_LOCAL_IP}/"
# jq -s '.[0] * .[1]' "metadata.${WEB_SERVER_LOCAL_IP}.json" result.json | jq -c "." >> "result-${LOCAL_IPV4}.log"

# Test scenario 4.
# ./run-wrk.sh --web-framework nginx --test-case complex -t 16 -c 16 -d 15 "http://${WEB_SERVER_LOCAL_IP}/"
# jq -s '.[0] * .[1]' "metadata.${WEB_SERVER_LOCAL_IP}.json" result.json | jq -c "." >> "result-${LOCAL_IPV4}.log"

# move the result file to S3
aws s3 cp \
  "result-${LOCAL_IPV4}.log" \
  "s3://${BUCKET_NAME}/${TEST_EXECUTION_UUID}/result-${LOCAL_IPV4}.log"