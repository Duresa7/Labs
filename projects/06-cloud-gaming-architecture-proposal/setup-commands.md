# Setup commands

What I would run to stand up the proposed server, matching the [design](README.md): an m5.large with a 100 GB gp3 volume, only the game port open, and the dedicated server installed with SteamCMD.

```bash
export AWS_DEFAULT_REGION=us-east-1

# Security group: open ONLY the game port (UDP 2344), nothing else
aws ec2 create-security-group --group-name arma3-sg \
  --description "Arma 3 dedicated server" --vpc-id <vpc-id>
aws ec2 authorize-security-group-ingress --group-id <sg-id> \
  --protocol udp --port 2344 --cidr 0.0.0.0/0

# The instance: m5.large, Windows Server, 100 GB gp3 root volume
aws ec2 run-instances --image-id <windows-server-ami> --instance-type m5.large \
  --security-group-ids <sg-id> --subnet-id <public-subnet-id> --associate-public-ip-address \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=arma3-server}]'
```

On the server, install the dedicated server with SteamCMD (Arma 3 Dedicated Server is Steam app id `233780`):

```bat
steamcmd +login anonymous +app_update 233780 validate +quit
```

Backups and cost control are part of the design, not an afterthought:

```bash
# Point-in-time backup of the game volume
aws ec2 create-snapshot --volume-id <vol-id> --description "arma3-server backup"

# Stop the instance when nobody is playing -- the single biggest cost lever,
# since the always-on m5.large is most of the monthly bill
aws ec2 stop-instances --instance-ids <id>
```

The `stop-instances` line is the one that matters most for the budget in the [proposal](README.md): on-demand pricing means a stopped instance is not billing compute, so scheduling it off overnight cuts the largest line item directly.
