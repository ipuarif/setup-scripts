#!/bin/bash

read -p "Enter a name for your VPC: " VPC_NAME

# Validate empty input
while [[ -z "$VPC_NAME" ]]; do
  read -p "VPC name cannot be empty. Enter a name for your VPC: " VPC_NAME
done

VPC_CIDR="10.3.0.0/16"
REGION="us-east-2"




echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --query 'Vpc.VpcId' \
    --output text \
    --region $REGION)


aws ec2 create-tags \
    --resources $VPC_ID \
    --tags Key=Name,Value="$VPC_NAME" \
    --region $REGION

echo "VPC created: $VPC_ID"


NUM_PUBLIC=3
NUM_PRIVATE=6

function generate_subnet_cidr() {
    local BASE_NET="10.3"
    local INDEX=$1
    echo "${BASE_NET}.${INDEX}.0/24"
}




for i in $(seq 1 $NUM_PUBLIC); do
    CIDR=$(generate_subnet_cidr $i)
    aws ec2 create-subnet \
        --vpc-id $VPC_ID \
        --cidr-block $CIDR \
        --availability-zone "${REGION}a" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet$i}]" \
        --region $REGION
    echo "Public Subnet $i created: $CIDR"
done



START=$((NUM_PUBLIC + 1))
END=$((NUM_PUBLIC + NUM_PRIVATE))

for i in $(seq $START $END); do
    CIDR=$(generate_subnet_cidr $i)
    aws ec2 create-subnet \
        --vpc-id $VPC_ID \
        --cidr-block $CIDR \
        --availability-zone "${REGION}b" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnet$((i-NUM_PUBLIC))}]" \
        --region $REGION
    echo "Private Subnet $((i-NUM_PUBLIC)) created: $CIDR"
done

echo "All subnets created successfully!"
