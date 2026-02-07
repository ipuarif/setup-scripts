#!/bin/bash
set -e

# --- User Input ---
read -p "Enter VPC ID to delete: " VPC_ID
read -p "Enter AWS Region : " REGION

echo "WARNING: This will permanently delete VPC $VPC_ID and all its resources (subnets, NAT gateways, IGWs, custom route tables, endpoints)."
read -p "Type 'yes' to continue: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# --- Step 1: Delete NAT Gateways and release Elastic IPs ---
echo "Deleting NAT Gateways..."
NATS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[].NatGatewayId" --output text --region $REGION)
for NAT in $NATS; do
    echo "Deleting NAT gateway $NAT..."
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION
    sleep 5  # wait for deletion to register

    # Release associated Elastic IP
    ALLOC=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT --query "NatGateways[0].NatGatewayAddresses[0].AllocationId" --output text --region $REGION)
    if [ "$ALLOC" != "None" ]; then
        echo "Releasing Elastic IP $ALLOC..."
        aws ec2 release-address --allocation-id $ALLOC --region $REGION
    fi
done

# --- Step 2: Delete VPC Endpoints ---
echo "Deleting VPC Endpoints..."
ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[].VpcEndpointId" --output text --region $REGION)
for EP in $ENDPOINTS; do
    echo "Deleting VPC endpoint $EP..."
    aws ec2 delete-vpc-endpoint --vpc-endpoint-id $EP --region $REGION
done

# --- Step 3: Delete all subnets ---
echo "Deleting subnets..."
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text --region $REGION)
for SUBNET in $SUBNETS; do
    echo "Deleting subnet $SUBNET..."
    aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION
done

# --- Step 4: Detach and delete Internet Gateways ---
echo "Deleting Internet Gateways..."
IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text --region $REGION)
for IGW in $IGWS; do
    echo "Detaching and deleting IGW $IGW..."
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION
done



# --- Step 6: Delete the VPC ---
echo "Deleting VPC $VPC_ID..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

echo "VPC $VPC_ID and all associated resources have been deleted safely!"
