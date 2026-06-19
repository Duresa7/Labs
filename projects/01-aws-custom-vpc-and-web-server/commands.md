# Command reference (AWS CLI)

I built this lab in the AWS console, but here is the equivalent AWS CLI, which is how I would script the same VPC so it is repeatable instead of click-by-click. Resource IDs are placeholders you fill from each command's output; addresses match the [walkthrough](README.md).

```bash
export AWS_DEFAULT_REGION=us-east-1

# 1. VPC with DNS hostnames
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lab-vpc}]'
aws ec2 modify-vpc-attribute --vpc-id <vpc-id> --enable-dns-hostnames

# 2. Public and private subnets in different AZs
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab-subnet-public}]'
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab-subnet-private}]'

# 3. Internet gateway, attached to the VPC
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>

# 4. Public route table: default route to the IGW, associate the public subnet
aws ec2 create-route-table --vpc-id <vpc-id>
aws ec2 create-route --route-table-id <rtb-id> \
  --destination-cidr-block 0.0.0.0/0 --gateway-id <igw-id>
aws ec2 associate-route-table --route-table-id <rtb-id> --subnet-id <public-subnet-id>
aws ec2 modify-subnet-attribute --subnet-id <public-subnet-id> --map-public-ip-on-launch

# 5. Security group: allow inbound web from anywhere
aws ec2 create-security-group --group-name Web-Security-Group \
  --description "Enable web access" --vpc-id <vpc-id>
aws ec2 authorize-security-group-ingress --group-id <sg-id> \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# 6. Launch the web server into the public subnet with a boot script
aws ec2 run-instances --image-id <amazon-linux-2023-ami-id> --instance-type t2.micro \
  --subnet-id <public-subnet-id> --security-group-ids <sg-id> \
  --associate-public-ip-address --user-data file://user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Web Server}]'
```

The single line that makes the subnet "public" is step 4's `create-route` to the internet gateway; without it, the same instance is unreachable no matter what the security group allows.
