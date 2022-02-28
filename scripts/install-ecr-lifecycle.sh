#!/usr/bin/env bash

# Change to root directory so that script can be run from any location
cd $(dirname $0)/..

aws ecr put-lifecycle-policy \
    --repository-name "serverless-grocery-shopping-bot-dev" \
    --lifecycle-policy-text "file://ecr-policy.json"