#!/bin/bash
set -e

cd "$(dirname "$0")"

rm -rf ${PWD}/python

docker run --rm -v "${PWD}:/var/task" public.ecr.aws/sam/build-python3.13 \
  pip install -r requirements.txt -t python