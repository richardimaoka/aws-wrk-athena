#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

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

# Copy results files from S3 to the current directory
RESULT_S3_FILES=$(aws s3api list-objects \
  --bucket ${BUCKET_NAME} \
  --prefix "${TEST_EXECUTION_UUID}/result" \
  --query 'Contents[*].Key' \
  --output text
)

mkdir ${TEST_EXECUTION_UUID}

for key in $RESULT_S3_FILES
do
  aws s3 cp "s3://${BUCKET_NAME}/${key}" ${key}
done

# Aggregate the results into a single file
ls ${TEST_EXECUTION_UUID} | xargs cat > "result-aggregated-${TEST_EXECUTION_UUID}.log"

aws s3 cp "result-aggregated-${TEST_EXECUTION_UUID}.log" "s3://${BUCKET_NAME}/aggregated/result-aggregated-${TEST_EXECUTION_UUID}.log"