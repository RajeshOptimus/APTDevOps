#!/usr/bin/env bash
set -euo pipefail

# Usage: AWS_ACCOUNT_ID=<id> OWNER=<github-owner> REPO=<repo> ROLE_NAME=github-actions-terraform ./iam/create-role.sh
# Requires: AWS CLI v2 configured with credentials that can create roles and policies.

: "${AWS_ACCOUNT_ID?Need to set AWS_ACCOUNT_ID env var}"
: "${OWNER?Need to set OWNER env var}"
: "${REPO?Need to set REPO env var}"
: "${ROLE_NAME:=github-actions-terraform}"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Render trust policy with provided values
TRUST_FILE="$TMP_DIR/trust-policy.json"
cat > "$TRUST_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:${OWNER}/${REPO}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Create role
echo "Creating role ${ROLE_NAME} with trust policy..."
aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://"${TRUST_FILE}" || true

# Create policy for Terraform (managed policy)
POLICY_NAME="${ROLE_NAME}-policy"
POLICY_FILE="$TMP_DIR/terraform-policy.json"
cat > "$POLICY_FILE" <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "iam:CreateRole","iam:DeleteRole","iam:PassRole","iam:CreateInstanceProfile","iam:AddRoleToInstanceProfile",
        "iam:AttachRolePolicy","iam:DetachRolePolicy","iam:PutRolePolicy","iam:DeleteRolePolicy",
        "ssm:*",
        "logs:*",
        "cloudwatch:*",
        "route53:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create managed policy
echo "Creating managed policy ${POLICY_NAME}..."
CREATE_POLICY_OUTPUT=$(aws iam create-policy --policy-name "${POLICY_NAME}" --policy-document file://"${POLICY_FILE}" 2>/dev/null || true)
if [ -n "$CREATE_POLICY_OUTPUT" ]; then
  POLICY_ARN=$(echo "$CREATE_POLICY_OUTPUT" | jq -r '.Policy.Arn')
else
  # Policy may already exist; fetch ARN
  POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" --output text)
fi

if [ -z "$POLICY_ARN" ] || [ "$POLICY_ARN" = "None" ]; then
  echo "Failed to create or find policy ARN"
  exit 1
fi

echo "Attaching policy ${POLICY_ARN} to role ${ROLE_NAME}..."
aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "$POLICY_ARN"

echo "Role created/updated. Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Add the following secret to your GitHub repo: AWS_ROLE_TO_ASSUME=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Done."
