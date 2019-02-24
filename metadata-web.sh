#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instancedata-data-retrieval
# 169.254.169.254 is a special (loopback?) address for EC2 metadat

AMI_ID=$(curl http://169.254.169.254/latest/meta-data/ami-id)
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type)
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
LOCAL_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

echo "{ \
  \"metadata.web_server.ami_id\":          \"$AMI_ID\", \
  \"metadata.web_server.instance_id\":     \"$INSTANCE_ID\", \
  \"metadata.web_server.instance_type\":   \"$INSTANCE_TYPE\", \
  \"metadata.web_server.hostname\":        \"$HOSTNAME\", \
  \"metadata.web_server.local_hostname\":  \"$LOCAL_HOSTNAME\", \
  \"metadata.web_server.local_ipv4\":      \"$LOCAL_IPV4\", \
  \"metadata.web_server.public_hostname\": \"$PUBLIC_HOSTNAME\", \
  \"metadata.web_server.public_ipv4\":     \"$PUBLIC_IPV4\" \
}" > metadata.json