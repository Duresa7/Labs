# Azure - Resources and RBAC

The Azure labs centered on how the platform organizes resources and controls who can touch them. The organizing unit is the **resource group**: a container for resources that share a lifecycle, so things created together and deleted together live together. Getting that grouping right is what keeps an account from becoming a flat pile of resources nobody can reason about.

## Role-based access control

Azure RBAC assigns access as a triple, who, what role, over which scope:

- **Security principal** - the user, group, or managed identity being granted access.
- **Role definition** - a set of permitted actions (Owner, Contributor, Reader, or a narrower built-in role).
- **Scope** - the level the assignment applies at: management group, subscription, resource group, or a single resource.

Because scope is hierarchical, an assignment flows down: grant Reader at a resource group and the principal can read everything in it. The least-privilege move is to assign the narrowest role at the narrowest scope that still lets the person do their job, Reader on one resource group, not Contributor on the whole subscription.

## Resource locks

One lab covered **resource locks**, which protect against the wrong kind of accident rather than the wrong person:

- A **CanNotDelete** lock lets people read and modify a resource but blocks deletion.
- A **ReadOnly** lock blocks modification and deletion both.

Locks apply regardless of RBAC role, so even an Owner is stopped from deleting a locked resource until the lock is removed. It is a deliberate speed bump on destructive actions, the cloud equivalent of the accidental-deletion protection I put on important objects elsewhere.

The deeper identity work, hybrid directory sync, conditional access, and the rest, lives in my [Azure AD lab](https://github.com/Duresa7/Hybrid-Azure-AD-Lab); this was the resource-management and access-control foundation under it.
