#!/bin/bash

/usr/local/bin/act_runner register --ephemeral --instance ${GITEA_INSTANCE_URL} --token ${GITEA_RUNNER_REGISTRATION_TOKEN} --labels ubuntu-latest:host --no-interactive
exec /usr/local/bin/act_runner daemon --once