#!/usr/bin/env bash
set -euo pipefail
if [ -z "${ALB_DNS-}" ]; then
  echo "ALB_DNS environment variable is required (export ALB_DNS=...)
Example: export ALB_DNS=$(terraform -chdir=terraform output -raw alb_dns)"
  exit 1
fi

echo "Testing /"
curl -sS "http://${ALB_DNS}/" | sed -n '1p'

echo "Testing /health"
curl -sS "http://${ALB_DNS}/health" | sed -n '1p'
