# Cloud Lab

Labs I worked through across the three major cloud providers. The weight is on AWS, where I built out the networking and access pieces that carry over to everything else: a VPC with its own subnets and routing, IAM with least-privilege roles, and a scaled, load-balanced compute tier. Azure and GCP get shorter write-ups covering resource organization and access control on each.

I keep the deeper cloud-identity work, hybrid directory sync and conditional access, in my [Azure AD lab](https://github.com/Duresa7/Hybrid-Azure-AD-Lab); this repository is about cloud infrastructure and access fundamentals.

> **A note on the values in here.** Account identifiers, resource names, IP ranges, and other specifics are placeholders. The architectures and the steps are real.

## What's in here

**AWS**
- [VPC networking](docs/aws/01-vpc.md) - subnets, route tables, gateways, and the security-group versus NACL split
- [IAM](docs/aws/02-iam.md) - users, roles, and least-privilege policy design
- [Compute and scaling](docs/aws/03-compute-scaling.md) - EC2 behind a load balancer with auto scaling

**Azure**
- [Resources and RBAC](docs/azure/01-resources-and-rbac.md) - resource groups, role assignments, and a resource lock

**GCP**
- [IAM](docs/gcp/01-iam.md) - roles and the resource hierarchy
