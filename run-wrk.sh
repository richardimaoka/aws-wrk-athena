#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

#In the ISO 8601 format of '2018-10-21T15:59:45+09:00'
current_time=$(date -Iseconds)

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  --web-framework   <S>  Name of the web framework to test
#  --test-case       <S>  Test case name
#  -c, --connections <N>  Connections to keep open
#  -d, --duration    <T>  Duration of test        
#  -t, --threads     <N>  Number of threads to use 
for OPT in "$@"
do
    case "$OPT" in
        '--web-framework' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --web-framework requires an argument -- $1" 1>&2
                exit 1
            fi
            web_framework="$2"
            shift 2
            ;;
        '--test-case' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option --test-case requires an argument -- $1" 1>&2
                exit 1
            fi
            test_case="$2"
            shift 2
            ;;
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
  \"parameters.web_framework\":    \"$web_framework\", \
  \"parameters.test_cast\":        \"$test_Case\", \
  \"parameters.execution_time\":   \"$current_time\", \
  \"parameters.connections\":      $connections, \
  \"parameters.duration_seconds\": $duration, \
  \"parameters.num_threads\":      $threads \
}" > wrk_parameters.json

# Run wrk and produce wrk_results.json
# Mounting the current directory to wrk container's WORKDIR = '/data'
WRK_CMD="docker run -v $(pwd):/data williamyeh/wrk -t ${threads} -c ${connections} -d ${duration}  -s wrk_json.lua ${TARGET_URL}"
echo "running:"
echo "${WRK_CMD}"
${WRK_CMD}

# Produce metadata.json
./metadata-wrk.sh

jq -s '.[0] * .[1] * .[2]' wrk_results.json wrk_parameters.json metadata.json > result.json
