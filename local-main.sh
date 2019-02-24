#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

UUID=$(uuidgen)
for params in $(jq -c '.[]' local-parameters.sample.json)
do
    ./local-commands.sh \
        --test-exec-uuid "${UUID}" \
        --test-seq-num "$(echo ${params} | jq '.test_seq_num')"\
        --wrk-local-ip "$(echo ${params} | jq '.web_local_ip')" \
        --web-local-ip "$(echo ${params} | jq '.web_local_ip')" \
        --wrk-instance-type "$(echo ${params} | jq '.wrk_instance_type')" \
        --web-instance-type "$(echo ${params} | jq '.web_instance_type')" \
        --web-framework "$(echo ${params} | jq '.web_framework')"
done
