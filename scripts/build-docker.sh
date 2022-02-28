#!/usr/bin/env bash

# Change to root directory so that script can be run from any location
cd $(dirname $0)/..

docker build -t grocery-ordering-bot .