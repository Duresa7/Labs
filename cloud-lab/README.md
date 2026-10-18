# Cloud Lab

Hands-on work across the three major cloud providers, written up as the projects I actually built rather than a tour of features. The weight is on AWS, where I built a custom VPC from an empty region up to a reachable web server, then worked through compute, storage, databases, and auto scaling on top of it. Azure and GCP cover the same fundamentals from each provider's angle: resource governance and access control. The last project is my own design proposal for hosting a game server in the cloud, costed out, because deciding *what* to build is as much the job as clicking it together.

I keep the deeper cloud-identity work (hybrid directory sync, conditional access) in my [Azure AD lab](https://github.com/Duresa7/Hybrid-Azure-AD-Lab); this repository is about cloud infrastructure, access, and cost.

## Projects

| Project | What it covers |
|---|---|
| [01 - AWS custom VPC and web server](projects/01-aws-custom-vpc-and-web-server/README.md) | Building a VPC, public and private subnets, routing, a security group, and an internet-reachable EC2 web server, end to end |
| [02 - AWS EC2, EBS, and RDS](projects/02-aws-ec2-ebs-and-rds/README.md) | Launching and resizing compute, attaching and snapshotting block storage, and standing up a managed database behind an app |
| [03 - AWS scaling and load balancing](projects/03-aws-scaling-and-load-balancing/README.md) | A load-balanced, self-healing compute pool that grows and shrinks with demand |
| [04 - Azure resource governance](projects/04-azure-resource-governance/README.md) | Resource groups, network security rules, storage access levels, and resource locks |
| [05 - GCP IAM and compute](projects/05-gcp-iam-and-compute/README.md) | Granting and revoking access across accounts, the resource hierarchy, and VM networking with gcloud |
| [06 - Cloud gaming architecture proposal](projects/06-cloud-gaming-architecture-proposal/README.md) | My own design and cost estimate for hosting a game server on AWS |
