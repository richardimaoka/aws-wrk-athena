#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

TARGET_S3_FOLDER=$1

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
  "s3://samplebucket-richardimaoka-sample-sample/${TARGET_S3_FOLDER}/metadata.${LOCAL_IPV4}.json"