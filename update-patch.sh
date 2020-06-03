#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q)

# Making sure to be logged in with the correct account
sudo docker login registry.gitlab.com -u deployment -p B-H-Sg97y3otYdRAjFkQ

# Get the current images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull


###################
# Changes here

###################

echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service
