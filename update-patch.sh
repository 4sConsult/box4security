#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull


# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service
