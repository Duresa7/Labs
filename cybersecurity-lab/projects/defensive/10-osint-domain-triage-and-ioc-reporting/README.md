# OSINT domain triage and IOC reporting

A short, common analyst task: a set of domains needs a reputation check, and the answer has to come back as a report someone can act on, not a screenshot of a website. This project is one of those. I ran a passive open-source reputation assessment on four web domains, then wrote it up as a formal indicator-of-compromise (IOC) report: what I checked, what I found, what it means, and what to do about it. The point of the exercise was as much the report discipline as the lookup.

The four domains are shown as `domain-a[.]example` through `domain-d[.]example` in defanged form.

## The task and the method

The job was a first-pass triage: given a list of domains, decide quickly which ones, if any, deserve a closer look. I kept the collection passive, meaning I never browsed to the sites or sent them traffic that would tip off an operator; I only queried third-party reputation data. Every domain went to VirusTotal, which aggregates the verdicts of roughly 97 security vendors and URL-scanning engines for a given URL. That gives two useful things at once: a consensus reputation score, and the per-vendor detail showing exactly which engine flagged what.

Passive, single-source collection has clear limits, and naming them is part of an honest report: VirusTotal reflects what its vendors have already seen, so a brand-new malicious site can read as clean, and a benign site can pick up a stray flag. The output of this stage is a lead to investigate, not a verdict.

## Indicators

The result of the four lookups, in the structure I would hand to whoever owns the blocklist:

| # | Type | Value | Status | Last analyzed | Notes |
|---|---|---|---|---|---|
| 1 | URL | `domain-a[.]example` | **Suspicious** | 2 days ago | Flagged "Suspicious" by Forcepoint ThreatSeeker. 1 / 97 vendors. |
| 2 | URL | `domain-b[.]example` | Clean | 3 days ago | 0 / 97 vendors flagged. |
| 3 | URL | `domain-c[.]example` | Clean | 2 days ago | 0 / 97 vendors flagged. |
| 4 | URL | `domain-d[.]example` | Clean | 2 months ago | 0 / 97 vendors flagged. |

## What the result actually means

One domain out of four drew a single flag; the other three were clean across the board. The analytical question is what to do with a 1-out-of-97 signal.

A single "Suspicious" verdict is low confidence by definition, and it would be wrong to call the domain malicious on that basis. It would also be wrong to dismiss it. One vendor flagging what 96 others miss is the pattern you would expect from an emerging threat that is not yet widely categorized, or from a threat class that only some engines are tuned to catch, such as adware distribution or social engineering, which leave little of the file-based signature that most engines look for. The recency matters too: the flagged domain had been analyzed within the last two days, so the finding was current rather than a stale artifact. Low confidence is a reason to verify, not a reason to ignore.

## Recommendations

The report closed on actions, ordered by what I would do first:

- **Block and monitor.** Add the flagged domain to the firewall and web-proxy blocklist as a precaution, and search internal logs (DNS, proxy) for any past or present connections to it. A precautionary block costs nothing if the domain is benign and contains the risk if it is not.
- **Confirm with dynamic analysis.** Detonate the domain in a sandbox to watch its actual behavior: what it loads, where it connects, and whether it tries to drop a file. That is what turns a low-confidence reputation flag into a real verdict.
- **Monitor continuously.** Re-check all four domains on a schedule. Reputation is a moving target; a clean domain today can be compromised and repurposed tomorrow.
- **Notify affected users.** If the log search turns up internal connections, follow up with those users and check their machines.

## Why this belongs here

This is the intake end of the same lifecycle the rest of this side of the repo works in. A reputation flag like this one is exactly the kind of low-confidence lead that, confirmed, becomes an entry in a [detection rule](../03-detection-engineering/README.md) or a line in an [incident timeline](../02-dfir-investigation/README.md). Writing it up in a fixed structure (summary, method, indicators, analysis, recommendations) with an honest confidence level is what makes it useful to the next person instead of a dead end. Real IOC reports also carry a Traffic Light Protocol marking that controls who the report can be shared with.

## Files in this project

- [sources.md](sources.md) - VirusTotal, the Traffic Light Protocol, and IOC references.
