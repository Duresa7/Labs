# Security Incident Response Record

| Field | Value |
|---|---|
| **Document ID** | SIR-2026-04-19-01 |
| **Classification** | Internal / Confidential |
| **Status** | Complete (with tracked follow-ups) |
| **Date of action** | 2026-04-19 |
| **Prepared by** | Project owner |
| **Version** | 1.1 |

> This is the deliverable produced during the response. Names, the application's brand, and the Supabase project/organization identifiers have been replaced with placeholders; the structure, decisions, rotation order, and verification are exactly as performed. The narrative of how I worked through it is in the [project README](README.md); the sources I relied on are in [sources.md](sources.md).

## 1. Executive summary

In response to a publicly disclosed security incident at Vercel, I rotated all primary access credentials that were stored in, or reachable from, the Vercel deployment of my web application; disabled legacy credentials; and verified the application's configuration end to end. I observed no evidence of unauthorized access to this project. The response was initiated and concluded on 2026-04-19. Five lower-priority follow-up items were logged for tracking rather than left implicit.

## 2. Incident reference

| Field | Value |
|---|---|
| Incident source | Vercel public security bulletin, "Vercel April 2026 security incident" |
| Reference | `https://vercel.com/kb/bulletin/vercel-april-2026-security-incident` |
| Vendor | Vercel Inc. |
| Vendor classification | Unauthorized access to internal systems via a compromised third-party integration; enumeration and decryption of non-sensitive environment variables for a subset of customers |
| Direct customer notification received | No |
| Response window | Initiated and concluded 2026-04-19 |

The trigger was a vendor disclosure, not an alert on my own systems. With no indication of a specific compromise of my project, the goal is to invalidate anything the vendor incident could have exposed, on the assumption that a secret held by a breached third party may already be gone. The vendor's own guidance (rotate environment variables not marked "sensitive," enable MFA, review account activity and deployments) shaped the action list below.

## 3. Scope of review

**In scope** (reachable from or stored in Vercel):

- The **Vercel** project itself (the application's primary deployment).
- The **Supabase** project (`qwzmrtbxnplkdvfhgjsy`) and its organization (`bcbfklmnpqrstvwxzghj`), because Supabase keys were stored as Vercel environment variables.
- The **GitHub** integration that auto-deploys to Vercel.
- The Supabase **`delete-account` Edge Function** and the secrets it holds.

**Out of scope** (not stored in or reachable from Vercel; handled separately or flagged):

- Google OAuth provider credentials (held in Supabase, not Vercel).
- The Resend transactional-email API key (held in Supabase).
- End-user session tokens.

## 4. Risk assessment

| Asset | Where it lives | Exposure | Action |
|---|---|---|---|
| Supabase publishable (anon) key | Vercel env var | Direct | **Rotated** |
| Supabase project URL | Vercel env var | None (public identifier) | No action |
| Supabase secret / service key | Edge Function secret | Indirect | **Rotated** (precaution) |
| Supabase database password | Not in Vercel | Indirect | **Rotated** (precaution) |
| Legacy anon JWT API key | Supabase | Indirect | **Disabled** |
| Vercel <-> GitHub integration token | Vercel/GitHub | Direct | **Integration reinstalled** |
| Supabase personal access token | Local `.env` only | Low | Flagged (F-1) |
| Google OAuth client secret | Supabase | Low | Flagged (F-4) |
| Resend API key | Supabase | Low | Flagged (F-5) |

The publishable key got the highest priority because it was directly in Vercel; the service key and database password followed because they sit one hop away. "Rotate as a precaution" applied to secrets not stored in Vercel, on the logic that once you are rotating, the marginal cost of rotating an adjacent secret is small and the cost of a wrong assumption about reach is large.

## 5. Actions taken

All actions performed 2026-04-19.

### 5.1 Supabase
- Rotated the publishable (anon) key; new active key labeled `default_v2` (type: publishable); prior key deleted.
- Rotated the secret/service key; new active key labeled `secret_v2`; prior key deleted.
- Rotated the Postgres database password.
- Disabled the legacy anon JWT API key (status now `disabled`).

### 5.2 Edge Function
- Updated the `delete-account` function's stored secrets (`EDGE_PUBLISHABLE_KEY`, `EDGE_SECRET_KEY`) to the new values.
- Verified the function's CORS allow-list and environment variables were intact.

### 5.3 Vercel
- Updated the `VITE_SUPABASE_ANON_KEY` environment variable to the new publishable key.
- Confirmed `VITE_SUPABASE_URL` was unchanged (public identifier, not a secret).
- Confirmed no other environment variable referenced a rotated value.

### 5.4 Local environment
- Updated the local `.env` to the new publishable key so development matched production.

### 5.5 GitHub integration
- Uninstalled the Vercel GitHub App.
- Reinstalled it with repository access restricted to this application's repository only.
- Triggered a test deployment to confirm the rebuilt integration worked.

### 5.6 Code verification
Searched the working tree for any surviving secret: the prior publishable key, the legacy anon JWT signature, the generic `sb_secret_` prefix, and the HS256 JWT header pattern. All four searches returned zero results. Also confirmed the `delete-account` function validates the caller's JWT with `auth.getUser(token)` inside the function body, so a stale or forged token cannot drive it.

## 6. Verification

| Check | Result |
|---|---|
| Old publishable key absent from all systems | Pass |
| Legacy anon key shows `disabled: true` | Pass |
| Edge Function secrets reference the new keys | Pass |
| Vercel env vars reference the new keys | Pass |
| Site functional (login, data load, account delete) via browser test | Pass |
| Edge Function invocation succeeds | Pass |
| Zero rotated values present in the working tree | Pass |
| No suspicious activity in the Vercel account audit | Pass |

## 7. Residual risk

- Git history was not scrubbed of previously committed values; mitigated because those values are now invalidated and useless even where they persist in history.
- The Vercel account activity audit showed no suspicious activity, but absence of evidence is not proof the incident never reached the project.
- End-user sessions were not forcibly invalidated; the risk was judged low relative to the disruption of a forced global logout.

## 8. Follow-up items

| ID | Item | Priority |
|---|---|---|
| F-1 | Rotate the Supabase personal access token held in the local `.env` | Medium |
| F-2 | Mark secret Vercel environment variables as "Sensitive" | Medium |
| F-3 | Establish a periodic credential-rotation schedule | Low |
| F-4 | Evaluate rotating the Google OAuth client secret | Low |
| F-5 | Evaluate rotating the Resend API key | Low |

## 9. Lessons learned

1. **Inventory secrets before an incident, not during one.** The slowest part of the response was reconstructing where each credential lived; a maintained secret-to-location map would have made scoping minutes instead of an hour.
2. **Set sensitivity flags at creation.** Several Vercel variables were not marked sensitive (F-2). Doing it up front is free; doing it under pressure is a task. The vendor's guidance to use the "sensitive" flag is exactly this lesson from their side.
3. **A pre-existing bug can mask the root cause.** Post-rotation testing surfaced a separate, unrelated bug in the `delete-account` function. Had I not tested functionally, I might have attributed it to the rotation.
4. **Rotation without verification is incomplete.** Changing a key and not confirming every consumer uses the new one is how you end up with a half-rotated system that fails at the worst time.

## 10. Sign-off

Actions in section 5 and verification in section 6 performed and confirmed by the project owner, 2026-04-19.
