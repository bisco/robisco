#!/bin/bash

export HUBOT_SLACK_TOKEN=$(cat slack_token)
export HUBOT_SLACK_TEAM=nbisco
export HUBOT_SLACK_BOTNAME=robisco

./bin/hubot -a slack
