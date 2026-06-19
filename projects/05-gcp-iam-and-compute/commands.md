# Command reference (gcloud)

The `gcloud` equivalent of the IAM and compute labs. Placeholders for project ID and accounts.

```bash
# Set the default zone (the step that tripped me up until I read why it is needed)
gcloud config set compute/zone us-central1-a

# Custom VPC, a subnet, and a firewall rule
gcloud compute networks create lab-vpc --subnet-mode=custom
gcloud compute networks subnets create lab-subnet \
  --network=lab-vpc --range=10.0.0.0/24 --region=us-central1
gcloud compute firewall-rules create allow-ssh \
  --network=lab-vpc --allow=tcp:22 --source-ranges=0.0.0.0/0

# A VM, then install a web server over SSH
gcloud compute instances create web-1 \
  --network=lab-vpc --subnet=lab-subnet --machine-type=e2-small
gcloud compute ssh web-1 --command="sudo apt-get update && sudo apt-get install -y nginx"

# IAM: grant a scoped role to a second account, then revoke it (the core lab)
gcloud projects add-iam-policy-binding <project-id> \
  --member="user:second-account@example.com" --role="roles/storage.objectViewer"
gcloud projects remove-iam-policy-binding <project-id> \
  --member="user:second-account@example.com" --role="roles/storage.objectViewer"

# Inspect who has what
gcloud projects get-iam-policy <project-id>
```

The grant/revoke pair is the lab I learned the most from: bind a **member** to a **role** at a **scope**, watch the second account gain access, then remove the binding and watch it lose it. The predefined `roles/storage.objectViewer` is least privilege in practice, far narrower than the basic Editor/Viewer roles.
