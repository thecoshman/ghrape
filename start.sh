#!/bin/bash

# Script orignally sourced from, but modified almost beyond recognition
# https://testdriven.io/blog/github-actions-docker/

USER=$GH_USER
REPO=$GH_REPO
PAT=$GH_PAT

echo "Starting runner for github.com/${USER}/${REPO}"
REGISTRAION_TOKEN=$(curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${PAT}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${USER}/${REPO}/actions/runners/registration-token" \
   | jq .token --raw-output)
echo "Retrieved runner registration token for github.com/${USER}/${REPO}"
./config.sh --unattended --disableupdate --replace \
  --url "https://github.com/${USER}/${REPO}" \
  --token "${REGISTRAION_TOKEN}"

cleanup() {
    echo "Removing runner..."
    REMOVAL_TOKEN=$(curl -L \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${USER}/${REPO}/actions/runners/remove-token" \
      | jq .token --raw-output)
    echo "Retrieved runner removal token for github.com/${USER}/${REPO}"
    ./config.sh remove --token ${REMOVAL_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
