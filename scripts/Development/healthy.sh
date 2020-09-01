#!/bin/bash
# Must be run as root.


# Define the time how long containers must stay healthy (after being healthy for the first time) to accept state.
SAFETY_TIME=15

stay_healthy() {
    /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh $1
    i=0
    while [ $i -lt $SAFETY_TIME ]; do
        state=$(docker inspect -f '{{ .State.Health.Status }}' $1 2>/dev/null)
        if [[ "${state}" != "healthy" ]]; then
            echo "ERROR: $name went from healthy to $state."
        fi
        sleep 1
        ((i++))
    done
}

curl -sX GET --unix-socket /var/run/docker.sock http://docker/containers/json > /tmp/containers.json
readarray -t containers < <(cat /tmp/containers.json | jq -r '.[].Names[0]' | sed 's/\///g')
for name in "${containers[@]}"
do
   (stay_healthy $name) &
done
echo "All containers staid healthy for $SAFETY_TIME seconds."
