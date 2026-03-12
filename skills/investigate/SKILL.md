---
name: investigate
description: "Investigate an active incident and post structured findings to Tellagen"
---

# Tellagen Incident Investigation

Investigate an active incident using the Tellagen MCP tools and any available vendor MCP tools (Grafana, GitHub, PagerDuty, Sentry, Kubernetes). Post structured findings as you go.

The user may provide an incident ID or say something like "investigate incident #42". If no incident ID is given, use `tellagen_list_incidents` to show active incidents and ask which one to investigate.

## Workflow

### 1. CONTEXT — Read the incident first

Before investigating, understand what's already known:

```
tellagen_get_incident(incident_id) — severity, status, services, started_at, manager
tellagen_get_incident_timeline(incident_id) — existing events, decisions, notes
tellagen_list_investigation_runs(incident_id) — any prior investigation runs
```

Use this context to focus your investigation. Don't repeat work that's already been done.

### 2. START — Create an investigation run

```
tellagen_start_investigation(
  incident_id,
  agent_name: "Claude Code",
  model_used: "<your model>",
  data_sources: [list the sources you plan to consult]
)
```

Save the returned `run.id` for posting findings.

### 3. INVESTIGATE — Use available data sources

Use whichever vendor MCP tools are available. Common investigation patterns:

**Grafana MCP** (if available):
- `query_loki_logs` — search error logs for the affected service
- `query_prometheus` — check error rates, latency, resource saturation
- `search_dashboards` — find relevant monitoring dashboards

**GitHub MCP** (if available):
- `list_commits` — check for recent deploys to affected services
- `search_code` — find relevant error handlers or config
- `list_pull_requests` — what merged recently?

**PagerDuty MCP** (if available):
- `get_incident` — alert details and escalation history
- `list_change_events` — what changed before the incident?

**Sentry MCP** (if available):
- Search for related errors and stack traces

**Kubernetes MCP** (if available):
- Check pod restarts, OOMKills, recent events

**Codebase** (always available):
- `Grep` for error messages seen in logs
- `Read` relevant source files, configs, runbooks
- `Glob` to find related files

### 4. POST — Report findings as you go

Post each finding incrementally — do not batch them at the end.

```
tellagen_post_finding(
  incident_id,
  investigation_run_id: <run_id>,
  finding_type: "observation" | "correlation" | "hypothesis" | "evidence" | "recommendation" | "negative",
  claim: "One-sentence finding statement",
  evidence_summary: "Detailed explanation with supporting data",
  confidence: 0.0 to 1.0,
  confidence_reason: "Why this confidence level",
  evidence_refs: [
    {
      source: "grafana-loki",
      query: '{app="checkout"} |= "error"',
      result_summary: "Found 500 errors in last 30 min",
      url: "https://grafana.example.com/explore?..."
    }
  ]
)
```

Include deep links in `evidence_refs.url` where possible — engineers will use these to verify your findings.

### 5. COMPLETE — Close the run

When investigation is finished:

```
tellagen_complete_investigation(run_id, status: "completed")
```

If the investigation fails or times out:

```
tellagen_complete_investigation(run_id, status: "failed", failure_reason: "...")
```

## Finding type guidance

| Type | When to use | Example |
|------|------------|---------|
| `observation` | Something notable you observed | "Error rate is 5x normal" |
| `correlation` | Two things that appear related | "Spike started 3 min after deploy X" |
| `hypothesis` | A proposed explanation | "Null check was removed in PR #456" |
| `evidence` | Concrete proof supporting a hypothesis | "Stack trace shows NPE at line 42" |
| `recommendation` | Suggested action | "Roll back deployment abc123" |
| `negative` | Something you ruled out | "Database performance is normal" |

## Tips

- Start with observations, then look for correlations, form hypotheses, and find evidence
- Post negative findings too — knowing what's NOT the cause is valuable
- Use confidence levels honestly: 0.9+ for near-certain, 0.5-0.7 for plausible, <0.5 for speculative
- Each finding should be atomic — one claim per finding
- If no vendor MCP tools are available, use the codebase, logs, and any accessible documentation
- The investigation context from step 1 helps you ask better questions of vendor tools
