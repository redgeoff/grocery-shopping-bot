#!/usr/bin/env bash

# Change to root directory so that script can be run from any location
cd $(dirname $0)/..

# The following doesn't play nice with `--shm-size=1g`:
#   -v $PWD/output/user-data:/opt/robotframework/temp/output/user-data:Z \

# -v $PWD/output:/opt/robotframework/reports:Z \
docker run --rm \
    --name grocery-shopping-bot \
    --shm-size=1g \
    grocery-ordering-bot