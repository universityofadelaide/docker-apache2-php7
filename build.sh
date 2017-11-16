#!/bin/bash
NAMESPACE=$(git remote get-url origin | awk -F'[/:]' '{ print $2 }')
DIR=$(basename $(pwd))
BRANCH=$(basename $(git symbolic-ref HEAD 2>/dev/null))
TAG="${NAMESPACE}/${DIR/docker-/}"
if [ ${BRANCH} != 'master' ]; then
	TAG=${TAG}:${BRANCH}
fi
echo "Building with tag: ${TAG}"
docker build -t ${TAG} .
