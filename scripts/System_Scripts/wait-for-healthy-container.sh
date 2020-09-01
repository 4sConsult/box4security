#!/bin/bash
container_name=$1
shift

RETURN_HEALTHY=0
RETURN_STARTING=1
RETURN_UNHEALTHY=2
RETURN_UNKNOWN=3
RETURN_ERROR=99

function usage() {
    echo "
    Usage: wait-for-healthy-container.sh <container name>
    "
    return
}

function get_health_state {
    state=$(docker inspect -f '{{ .State.Health.Status }}' ${container_name} 2>/dev/null)
    return_code=$?
    if [[ "${state}" == "healthy" ]]; then
        return ${RETURN_HEALTHY}
    elif [[ "${state}" == "unhealthy" ]]; then
        return ${RETURN_UNHEALTHY}
    elif [[ "${state}" == "starting" ]]; then
        return ${RETURN_STARTING}
    else
        # Return unknown also in case of error, because we can retry
        return ${RETURN_UNKNOWN}
    fi
}

function wait_for() {
    echo "Wait for container '$container_name' to be healthy.."
    i=0
    while true; do
        get_health_state
        state=$?
        if [ ${state} -eq 0 ]; then
            echo "Container '$container_name' is healthy after ${i} seconds."
            exit 0
        fi
        sleep 1
        ((i++))
    done
}

if [ -z ${container_name} ]; then
    usage
    exit 1
else
    wait_for
fi
