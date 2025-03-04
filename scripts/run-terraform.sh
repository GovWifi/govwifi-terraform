#!/bin/bash

set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TERRAFORM_DIR="${SCRIPT_DIR}/../govwifi/${DEPLOY_ENV}"

cd "${TERRAFORM_DIR}"
TFE_PARALLELISM=128
terraform "$@"
