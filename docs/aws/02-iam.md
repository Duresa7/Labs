# AWS - IAM

IAM is where most cloud mistakes actually happen, an over-permissive policy is how a single compromised key turns into a full account takeover. The lab work was about building access the right way around: start from nothing and grant only what a given identity needs.

## The pieces

- **Users** are long-lived identities for a person. I gave them no inline permissions directly.
- **Groups** carry the policies; users inherit them by membership. Managing access at the group level keeps it auditable, you look at the group to know what a class of user can do.
- **Roles** are the important one. A role is a set of permissions that an entity assumes temporarily, with credentials that expire. An EC2 instance that needs to read from S3 gets a role, not a stored access key, so there is no long-lived secret sitting on the box to steal.
- **Policies** are the JSON documents that say what is allowed, attached to groups or roles rather than scattered onto individuals.

## Least privilege in practice

The principle is easy to state and easy to violate. The lab habits that keep it honest:

- **Start with deny.** Everything is denied until a policy allows it, so the work is justifying each grant, not remembering to remove the ones you regret.
- **Scope to the resource.** A policy that allows `s3:GetObject` on one bucket ARN is a different risk from one that allows it on `*`. Naming the resource is most of the security.
- **Prefer roles over keys.** Temporary, auto-rotating credentials from an assumed role beat a static access key in a config file every time. The credential that does not exist cannot leak.
- **Separate duties.** The identity that deploys is not the identity that reads production data. Splitting them limits what any single compromise reaches.

The through-line with the rest of my work is the same default-deny instinct as my [host firewall](https://github.com/Duresa7/Network-Lab/blob/main/docs/07-host-firewall.md): close everything, then open the specific paths that have a reason to exist, and be able to point at why each one is open.
