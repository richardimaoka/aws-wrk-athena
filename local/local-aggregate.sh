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

BUCKET_NAME="samplebucket-richardimaoka-sample-sample"

mkdir -p froms3
aws s3 cp \
  --exclude "metadata.*" \
  --recursive \
  "s3://${BUCKET_NAME}/${TEST_EXECUTION_UUID}"/ \
  froms3/

mkdir -p aggregated
cat froms3/*.log >> "aggregated/${TEST_EXECUTION_UUID}.log"

aws s3 cp \
  "aggregated/${TEST_EXECUTION_UUID}.log" \
  "s3://${BUCKET_NAME}/aggregated/"
