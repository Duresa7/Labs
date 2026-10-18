# Sources

What I referenced during and after the response.

## The incident itself

- **Vercel, "Vercel April 2026 security incident" (security bulletin), last updated 2026-04-24.**
  `https://vercel.com/kb/bulletin/vercel-april-2026-security-incident`
  The vendor disclosure that triggered this response. It described unauthorized access to internal systems originating from a compromised third-party integration, the enumeration and decryption of non-sensitive environment variables for a subset of customers, and the remediation guidance I followed (enable MFA, rotate environment variables not marked "sensitive," use the sensitive-variable feature, review account activity and recent deployments, and rotate deployment-protection tokens).

## Vendor documentation I used to do the rotation

- **Vercel, "Environment variables" and "Sensitive Environment Variables" documentation.**
  `https://vercel.com/docs/environment-variables`
  Used to confirm where variables are stored, how the "sensitive" flag changes their handling, and how to update them safely (follow-up item F-2).
- **Supabase, "API Keys" documentation (publishable / secret keys, legacy JWT keys).**
  `https://supabase.com/docs/guides/api/api-keys`
  Used for the rotation mechanics: issuing new publishable and secret keys, and disabling the legacy anon JWT key.
- **Supabase, "Database password" and project settings.**
  `https://supabase.com/docs/guides/database/managing-passwords`
  Used to rotate the Postgres database password.
- **Supabase, "Edge Functions secrets."**
  `https://supabase.com/docs/guides/functions/secrets`
  Used to update the `delete-account` function's stored secrets to the new key values.

## Framework that shaped the structure of the record

- **NIST SP 800-61, "Computer Security Incident Handling Guide."**
  `https://csrc.nist.gov/pubs/sp/800/61/r2/final`
  The preparation / detection-and-analysis / containment-eradication-recovery / post-incident phases are the spine of the report's structure, adapted here to a precautionary credential-rotation response rather than a confirmed intrusion.
