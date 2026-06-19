# AWS - Compute and scaling

This lab put a compute tier behind a load balancer and let it grow and shrink on its own. The point was to stop thinking about "a server" and start thinking about a pool of interchangeable instances that traffic is spread across, which is the shift that makes a cloud deployment resilient instead of just hosted.

## The shape

- **EC2 instances** in the private subnet from the [VPC lab](01-vpc.md), running the application, with no public addresses of their own.
- A **launch template** that defines how a new instance comes up, AMI, instance type, security group, and the user-data that configures it on boot, so every instance in the pool is identical.
- An **Application Load Balancer** in the public subnet, taking inbound traffic and distributing it across the instances. It is the only thing facing the internet; the instances behind it are not directly reachable.
- A **target group** with health checks, so the load balancer stops sending traffic to an instance that fails its check and resumes when it recovers.
- An **Auto Scaling group** tying it together, with a minimum, maximum, and desired count, and a scaling policy that adds instances when a metric (CPU, say) crosses a threshold and removes them when demand falls.

## What it demonstrated

Two properties fall out of this design that a single server cannot have:

- **It self-heals.** When I terminated an instance to test it, the Auto Scaling group noticed the count was below desired and launched a replacement from the launch template, and the load balancer's health check kept traffic off the dead one in the meantime. No manual step.
- **It scales with load instead of with guesses.** Rather than sizing one box for peak demand and paying for it at idle, the pool grows under load and shrinks after, so capacity tracks the actual traffic.

The load balancer also becomes the natural place to terminate TLS and the single front door to harden, which keeps the instances behind it simpler. It is the cloud version of the same idea as my edge layer at home: one controlled entry point, everything real behind it.
