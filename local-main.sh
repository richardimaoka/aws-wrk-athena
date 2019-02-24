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

UUID=$(uuidgen)
./local-commands.sh \
    --test-exec-uuid "${UUID}" \
    --test-seq-num 1\
    --wrk-local-ip "10.0.1.1" \
    --web-local-ip "10.0.0.1" \
    --wrk-instance-type "m5.xlarge" \
    --web-instance-type "m5.xlarge" \
    --web-framework "nginx"    
