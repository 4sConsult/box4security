#!/bin/bash
if if [ $1 == "up" ]
then
    # perform commands to set the service up
    # Stop and remove old container
    /usr/local/bin/docker-compose -f /home/amadmin/box4s/docker/box4security.yml down -v
    /usr/local/bin/docker-compose -f /home/amadmin/box4s/docker/box4security.yml rm -v
    /usr/local/bin/docker-compose -f /home/amadmin/box4s/docker/box4security.yml up --no-color --no-build --remove-orphans
elif [ $1 == "down" ]
then
    # perform commands to set the service down
    /usr/local/bin/docker-compose -f /home/amadmin/box4s/docker/box4security.yml down -v
else
    echo "You have to submit up/down as the first parameter to the BOX4s service script."
    exit 1
fi
