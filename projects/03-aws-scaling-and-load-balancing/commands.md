# Command reference (AWS CLI)

The CLI equivalent of the load-balanced, self-healing pool. Placeholders for IDs/ARNs.

```bash
# 1. Golden image from the configured web server
aws ec2 create-image --instance-id <id> --name "web-golden"

# 2. Launch template (how every pool instance comes up)
aws ec2 create-launch-template --launch-template-name web-lt \
  --launch-template-data '{"ImageId":"<ami>","InstanceType":"t2.micro","SecurityGroupIds":["<sg-id>"]}'

# 3. Target group with a health check, then the load balancer and listener
aws elbv2 create-target-group --name web-tg --protocol HTTP --port 80 \
  --vpc-id <vpc-id> --health-check-path /
aws elbv2 create-load-balancer --name web-alb --subnets <pub-a> <pub-b> --security-groups <sg-id>
aws elbv2 create-listener --load-balancer-arn <alb-arn> --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=<tg-arn>

# 4. Auto Scaling group: min / desired / max, behind the target group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name web-asg \
  --launch-template LaunchTemplateName=web-lt --min-size 2 --max-size 6 --desired-capacity 2 \
  --target-group-arns <tg-arn> --vpc-zone-identifier "<priv-a>,<priv-b>"

# 5. Scale on CPU (the policy that adds/removes instances with load)
aws autoscaling put-scaling-policy --auto-scaling-group-name web-asg \
  --policy-name cpu-target --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":60.0}'
```

The self-healing test from the [walkthrough](README.md) is just terminating an instance and watching the group rebuild it:

```bash
aws ec2 terminate-instances --instance-ids <id>
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web-asg \
  --query 'AutoScalingGroups[0].Instances'
```
