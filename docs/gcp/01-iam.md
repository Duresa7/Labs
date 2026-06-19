# GCP - IAM

The GCP work was an IAM quickstart, and the piece worth keeping is how Google structures access around its **resource hierarchy**. Permissions are not set in isolation; they inherit down a tree, and understanding the tree is what makes the access model predictable.

## The hierarchy

```
Organization
  └─ Folders
       └─ Projects
            └─ Resources
```

A policy set at any level flows down to everything beneath it. Grant a role at the organization and it applies everywhere; grant it on a single project and it stops there. The same least-privilege rule as everywhere else applies: bind a role at the lowest node that still does the job.

## Roles and bindings

GCP IAM grants access by binding a **member** (a user, group, or service account) to a **role** on a resource:

- **Basic roles** (Owner, Editor, Viewer) are broad and mostly a holdover; they grant far more than a specific task needs.
- **Predefined roles** are scoped to a service and an action set, "Compute Storage Admin", "Pub/Sub Subscriber", and are what least privilege usually means in practice.
- **Custom roles** exist for when even the predefined ones grant too much, letting you assemble the exact permission list.

**Service accounts** are the identities non-human workloads use, the GCP analogue of an AWS role for a workload: a VM or an application acts as a service account rather than carrying a user's credentials.

The pattern across all three providers is identical once you see it: a hierarchy of scopes, roles that bundle permissions, and a least-privilege discipline that says bind the narrowest role at the lowest scope. AWS calls them policies and ARNs, Azure calls them role assignments and scopes, GCP calls them bindings and a resource hierarchy. The instinct transfers unchanged.
