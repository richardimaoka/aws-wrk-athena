#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

uuid=$(uuidgen)
echo "" > "result-${uuid}.log"

# Run wrk and append the result to result-${uuid}.log
./run-wrk.sh --web-framework nginx --test-case simple -t 4 -c 4 -d 15 
# Amazon Athena handles **single-line** JSON only due to 'org.openx.data.jsonserde.JsonSerDe'
#   https://docs.aws.amazon.com/athena/latest/ug/parsing-JSON.html
#   > Make sure that each JSON-encoded record is represented on a separate line.
# so using -c to put each test case results into a single line:
jq -c result.json >> "result-${uuid}.log"

# Possibly run other test cases too
./run-wrk.sh --web-framework nginx --test-case simple -t 8 -c 8 -d 15 
jq -c result.json >> "result-${uuid}.log"

# ./run-wrk.sh --web-framework nginx --test-case simple -t 16 -c 16 -d 15 
# jq -c result.json >> "result-${uuid}.log"

# ./run-wrk.sh --web-framework nginx --test-case complex -t 16 -c 16 -d 15 
# jq -c result.json >> "result-${uuid}.log"

# move the result file to S3
aws s3 mv "result-${uuid}.log" s3://samplebucket-richardimaoka-sample-sample/wrk-raw-results