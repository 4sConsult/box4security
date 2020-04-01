#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.


# Start des Services
echo "Restarting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
