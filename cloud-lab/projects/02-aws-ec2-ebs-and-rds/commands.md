# Command reference (AWS CLI)

The CLI equivalent of the three labs (compute lifecycle, block storage, managed database). Console in the lab; this is how I would script it.

## EC2: launch, resize, stop-protection

```bash
aws ec2 run-instances --image-id <ami> --instance-type t2.micro --subnet-id <subnet-id>

# Resize requires a stop (the lesson that "elastic" is not "live")
aws ec2 stop-instances  --instance-ids <id>
aws ec2 modify-instance-attribute --instance-id <id> --instance-type "{\"Value\":\"t2.small\"}"
aws ec2 start-instances --instance-ids <id>

# Stop protection, the guardrail against the wrong instance in a list
aws ec2 modify-instance-attribute --instance-id <id> --disable-api-stop
```

## EBS: create, attach, format, snapshot, restore

```bash
aws ec2 create-volume --availability-zone us-east-1a --size 8 --volume-type gp3
aws ec2 attach-volume --volume-id <vol-id> --instance-id <id> --device /dev/sdf

# On the instance: turn raw blocks into a usable file system
sudo mkfs -t xfs /dev/xvdf
sudo mkdir /data && sudo mount /dev/xvdf /data

# Snapshot, then restore into a new volume
aws ec2 create-snapshot --volume-id <vol-id> --description "lab snapshot"
aws ec2 create-volume --snapshot-id <snap-id> --availability-zone us-east-1a
```

## RDS: subnet group, then the DB instance

```bash
# A subnet group spanning two AZs is what lets RDS place a standby for failover
aws rds create-db-subnet-group --db-subnet-group-name lab-db-subnets \
  --db-subnet-group-description "lab db subnets" --subnet-ids <subnet-a> <subnet-b>

aws rds create-db-instance --db-instance-identifier lab-db --engine mysql \
  --db-instance-class db.t3.micro --allocated-storage 20 \
  --db-subnet-group-name lab-db-subnets --vpc-security-group-ids <db-sg-id> \
  --master-username admin --manage-master-user-password \
  --no-publicly-accessible
```

`--no-publicly-accessible` plus a security group scoped to the app tier is the database-should-never-be-on-a-public-path rule from the [walkthrough](README.md).
