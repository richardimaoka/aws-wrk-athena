#!/bin/bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

UUID=$(uuidgen)
for in $(jq -c '.[]' local-parameters.sample.json)
do
    ./local-commands.sh \
        --test-exec-uuid "${UUID}" \
        --test-seq-num "$(jq '.test_seq_num')"\
        --wrk-local-ip "$(jq '.web_local_ip')" \
        --web-local-ip "$(jq '.web_local_ip')" \
        --wrk-instance-type "$(jq '.wrk_instance_type')" \
        --web-instance-type "$(jq '.web_instance_type')" \
        --web-framework "$(jq '.web_framework')"
done
