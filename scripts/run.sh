#!/usr/bin/env bash

# Change to root directory so that script can be run from any location
cd $(dirname $0)/..

robot -d output --variablefile ./env.robot.yml robot/shop.robot