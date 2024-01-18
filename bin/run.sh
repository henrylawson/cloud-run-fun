#!/bin/bash
set -euo pipefail

cd ./src
gcloud \
  builds \
  submit \
  --region australia-southeast1 \
  --tag australia-southeast1-docker.pkg.dev/hgl-env-a/containers/cloud-run-fun:latest