#!/usr/bin/env bash
set -euo pipefail

# One-shot cleanup for resources created by this project
# Usage:
# AWS_REGION=ap-south-1 NAME_PREFIX=devops-assignment ./scripts/cleanup.sh

: "${AWS_REGION:=ap-south-1}"
: "${NAME_PREFIX:=devops-assignment}"

echo "AWS_REGION=${AWS_REGION}"
echo "NAME_PREFIX=${NAME_PREFIX}"

echo "This script will irreversibly delete resources matching prefix: ${NAME_PREFIX} in region ${AWS_REGION}."
read -p "Type 'yes' to proceed: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborting."
  exit 1
fi

which aws >/dev/null 2>&1 || { echo "aws CLI not found in PATH"; exit 1; }

# Helper to join lines to array
mapfile_from_cmd() {
  # prints lines as bash array via mapfile
  mapfile -t ARR < <(eval "$1")
}

# 1) Find ASGs matching prefix
ASG_NAMES=$(aws autoscaling describe-auto-scaling-groups --region "$AWS_REGION" --query "AutoScalingGroups[?contains(AutoScalingGroupName, \\`${NAME_PREFIX}\\`)].AutoScalingGroupName" --output text) || ASG_NAMES=""
if [ -z "$ASG_NAMES" ]; then
  echo "No Auto Scaling Groups found with prefix ${NAME_PREFIX}"
else
  echo "Found ASGs:"
  echo "$ASG_NAMES"
  for ASG in $ASG_NAMES; do
    echo "Scaling ASG $ASG to 0..."
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG" --min-size 0 --max-size 0 --desired-capacity 0 --region "$AWS_REGION"
  done

  # wait for instances to terminate
  for ASG in $ASG_NAMES; do
    echo "Waiting for ASG $ASG to have zero instances..."
    for i in {1..60}; do
      COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --region "$AWS_REGION" --query 'AutoScalingGroups[0].Instances | length(@)' --output text)
      if [ "$COUNT" = "0" ]; then
        echo "ASG $ASG has zero instances"
        break
      fi
      echo "  still $COUNT instances, waiting..."
      sleep 5
    done
  done

  # delete ASGs
  for ASG in $ASG_NAMES; do
    echo "Deleting ASG $ASG (force-delete)..."
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$ASG" --force-delete --region "$AWS_REGION" || true
  done
fi

# 2) Delete Target Groups with prefix
TG_ARNS=$(aws elbv2 describe-target-groups --region "$AWS_REGION" --query "TargetGroups[?contains(TargetGroupName, \\`${NAME_PREFIX}\\`)].TargetGroupArn" --output text) || TG_ARNS=""
if [ -n "$TG_ARNS" ]; then
  for TG in $TG_ARNS; do
    echo "Deleting target group $TG"
    aws elbv2 delete-target-group --target-group-arn "$TG" --region "$AWS_REGION" || true
  done
else
  echo "No target groups found with prefix ${NAME_PREFIX}"
fi

# 3) Delete Load Balancers with prefix
LB_ARNS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?contains(LoadBalancerName, \\`${NAME_PREFIX}\\`)].LoadBalancerArn" --output text) || LB_ARNS=""
if [ -n "$LB_ARNS" ]; then
  for LB in $LB_ARNS; do
    echo "Deleting load balancer $LB"
    aws elbv2 delete-load-balancer --load-balancer-arn "$LB" --region "$AWS_REGION" || true
  done
else
  echo "No load balancers found with prefix ${NAME_PREFIX}"
fi

# 4) Delete Launch Templates
LT_IDS=$(aws ec2 describe-launch-templates --region "$AWS_REGION" --query "LaunchTemplates[?contains(LaunchTemplateName, \\`${NAME_PREFIX}\\`)].LaunchTemplateId" --output text) || LT_IDS=""
if [ -n "$LT_IDS" ]; then
  for LT in $LT_IDS; do
    echo "Deleting launch template $LT"
    aws ec2 delete-launch-template --launch-template-id "$LT" --region "$AWS_REGION" || true
  done
else
  echo "No launch templates found with prefix ${NAME_PREFIX}"
fi

# 5) Delete NAT Gateways and release EIPs
NAT_IDS=$(aws ec2 describe-nat-gateways --region "$AWS_REGION" --query "NatGateways[?contains(Tags[?Key=='Name'].Value | [0], \\`${NAME_PREFIX}\\`)].NatGatewayId" --output text) || NAT_IDS=""
if [ -n "$NAT_IDS" ]; then
  for NAT in $NAT_IDS; do
    echo "Deleting NAT gateway $NAT"
    aws ec2 delete-nat-gateway --nat-gateway-id "$NAT" --region "$AWS_REGION" || true
  done
else
  echo "No NAT gateways found with prefix ${NAME_PREFIX}"
fi

# Release EIPs tagged with name prefix
EIP_ALLOCS=$(aws ec2 describe-addresses --region "$AWS_REGION" --filters "Name=tag:Name,Values=${NAME_PREFIX}-nat-eip*" --query "Addresses[].AllocationId" --output text) || EIP_ALLOCS=""
if [ -n "$EIP_ALLOCS" ]; then
  for A in $EIP_ALLOCS; do
    echo "Releasing EIP allocation $A"
    aws ec2 release-address --allocation-id "$A" --region "$AWS_REGION" || true
  done
else
  echo "No EIP allocations found with prefix ${NAME_PREFIX}-nat-eip"
fi

echo "Cleanup finished. Note: some resources (ALB/TG) may take time to be fully deleted by AWS."