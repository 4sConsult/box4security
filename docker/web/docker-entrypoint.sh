#!/bin/sh

python main.py db upgrade head
python main.py run -h 0.0.0.0
