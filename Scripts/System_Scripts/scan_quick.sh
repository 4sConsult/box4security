#!/bin/bash
nmap -sS 192.168.0.0/24 -F -oX - | curl http://localhost:5045 --data-binary @-
