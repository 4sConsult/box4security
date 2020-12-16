#!/bin/bash
# Must be run as root.

CONTAINERS_WITH_HEALTHCHECK=(core4s elasticsearch nginx db spiderfoot logstash kibana web wazuh openvas)

# Define the time how long containers must stay healthy (after being healthy for the first time) to accept state.
SAFETY_TIME=300

stay_healthy() {
    
    i=0
    while [ $i -lt $SAFETY_TIME ]; do
        for name in "${CONTAINERS_WITH_HEALTHCHECK[@]}"
        do
            state=$(docker inspect -f '{{ .State.Health.Status }}' $name 2>/dev/null)
            if [[ "${state}" != "healthy" ]]; then
                echo "ERROR: $name went from healthy to $state."
                exit 1
            fi
        done
        sleep 1
        ((i++))
    done
}

for name in "${CONTAINERS_WITH_HEALTHCHECK[@]}"
do
    # first let all get healthy, then check every second if one got unhealthy!
    /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh $name
done
stay_healthy
echo "All containers staid healthy for $SAFETY_TIME seconds."
