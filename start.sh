#!/bin/bash

function usage() {
    echo "usage: ./start.sh (slack|debug)" 
    echo "slack -> kick hubot with slack adapter"
    echo "debug -> kick hubot without adapter"
}


if [ $# -ne 1 ]; then
    usage;
    exit
fi


export HUBOT_SLACK_TOKEN=$(cat slack_token)
export HUBOT_SLACK_TEAM=nbisco
export HUBOT_SLACK_BOTNAME=robisco

# Redmine Configurations
if [ -e "redmine_ssl_url" ]; then
    export HUBOT_REDMINE_SSL=$(cat redmine_ssl_url)
fi
export HUBOT_REDMINE_BASE_URL=$(cat redmine_url)
export HUBOT_REDMINE_TOKEN=$(cat redmine_token)
export HUBOT_REDMINE_IGNORED_USERS=""

if [ $1 = "slack" ]; then
    ./bin/hubot -a slack
else
    ./bin/hubot
fi
