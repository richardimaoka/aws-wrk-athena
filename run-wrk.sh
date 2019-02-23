#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

#In the ISO 8601 format of '2018-10-21T15:59:45+09:00'
current_time=$(date -Iseconds)

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  -c, --connections <N>  Connections to keep open
#  -d, --duration    <T>  Duration of test        
#  -t, --threads     <N>  Number of threads to use 
for OPT in "$@"
do
    case "$OPT" in
        '-c'|'--connections' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -c or --connections requires an argument -- $1" 1>&2
                exit 1
            fi
            connections="$2"
            shift 2
            ;;
        '-d'|'--duration' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -d or --duration requires an argument -- $1" 1>&2
                exit 1
            fi
            duration="$2"
            shift 2
            ;;
        '-t'|'--threads' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -t or --threads requires an argument -- $1" 1>&2
                exit 1
            fi
            threads="$2"
            shift 2
            ;;
        -*)
            echo "wrk: illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ -n "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                TARGET_URL="$1"
                break
            fi
            ;;
    esac
done


# Produce wrk_parameters.json
echo "{ \
  \"parameters.execution_time\":   \"$current_time\", \
  \"parameters.connections\":      $connections, \
  \"parameters.duration_seconds\": $duration, \
  \"parameters.num_threads\":      $threads \
}" > wrk_parameters.json

# Run wrk and produce wrk_results.json
WRK_CMD="wrk -t ${threads} -c ${connections} -d ${duration} -s wrk_json.lua ${TARGET_URL}"
echo "running:"
echo "${WRK_CMD}"
${WRK_CMD}

# Produce metadata.json
./metadata.sh


jq -s '.[0] * .[1]' result_metadata.json result_intermediate.json > result.json


