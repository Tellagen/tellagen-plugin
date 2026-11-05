---
name: investigate
description: "Investigate an active incident and post structured findings to Tellagen"
---

# Tellagen Incident Investigation

Investigate an active incident using the Tellagen MCP tools and any available vendor MCP tools (Grafana, GitHub, PagerDuty, Sentry, Kubernetes). Post structured findings as you go.

This skill is the short workflow. The MCP server has the full guide at `resource://tellagen/skill-guide`, and the plotting recipes at `resource://tellagen/figure-guide`.

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

### 2. START — Attach to an investigation run

If the prompt gives an `investigation_run_id`, attach to that run and do not start another:

```
tellagen_pick_up_investigation(investigation_run_id)
```

Otherwise, start a run and then pick it up:

```
tellagen_start_investigation(
  incident_id,
  agent_name: "Claude Code",
  model_used: "<your model>",
  data_sources: [list the sources you plan to consult],
  corrects_run_id: <only for a follow-up to an earlier run of this incident>
)
tellagen_pick_up_investigation(investigation_run_id: <the new run.id>)
```

Save the run ID for posting findings. The pickup response can carry these keys. Each one is left out when it is empty:

- `server_capabilities`: what this Tellagen accepts. See "Diagnosis structure" below.
- `attachments`: screenshots the responder added. Read each one with `tellagen_get_context_attachment` (pass its `url`), one per call. The result has an image when the image is small enough, and always the path of a temp file with the full image.
- `context_links`: typed links from the question, with what Tellagen could read from each one.
- `parent`: the earlier run that a follow-up corrects. An agent wrote it and it can be wrong, so check it again before you rely on it.

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

Report each check as a trace step. Use the same `cause_key` (a short word) on every check of one cause:

```
tellagen_post_trace_step(
  investigation_run_id: <run_id>,
  step_id: "loki-errors",
  status: "running" | "done" | "error",
  title: "Queried checkout error logs",
  tool_name: "grafana-loki",
  guidance: { origin: "agent_judgment", refs: [], reason: "Bounded query to test the leading cause" },
  result_summary: "502 errors began at 14:32 UTC",
  outcome: "supports" | "rules_out" | "nothing_notable" | "inconclusive" | "unavailable",
  cause_key: "deploy-4412"
)
```

Send `outcome` when the check finishes. Use `unavailable` with `status: "error"` when you could not read the source. `guidance` is required. If a runbook from the pickup guided the check, cite it instead (see "Guidance lineage on trace steps" in the full guide). Reuse the same `guidance` object when a step changes from `running` to `done` or `error`.

While you work, call `tellagen_update_cause` when a cause starts, changes state or is ruled out, so the Diagnosis tab shows what you are testing.

### 4. POST — Report findings as you go

Post each finding incrementally — do not batch them at the end.

```
tellagen_post_finding(
  incident_id,
  investigation_run_id: <run_id>,
  finding_type: "observation" | "correlation" | "hypothesis" | "evidence" | "recommendation" | "negative" | "gap",
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

Give every proof a source, so that responders can open it from the Diagnosis tab:

- For Grafana and GitHub evidence, call `tellagen_build_source_link` and copy its `links` into the evidence ref. If it fails, use a `command` and `datasource` instead.
- For kubectl and other local sources with no browser address, add a read-only `command` with no credentials.
- Add `datasource` (the Grafana data source name or uid) when you have it.

Keep the numeric `id` of every finding (the response is `{finding: {id}}`). The completion summary cites findings by `finding_ids`.

Post the key facts on the timeline too. Use `tellagen_promote_finding` for a finding, and `tellagen_post_timeline_event` for a timestamped fact. Tellagen refuses a promotion while the run has an open gap finding. A timeline event needs a `body`, and it can carry `blocks` built with `tellagen_build_figure`.

### 5. COMPLETE — Close the run

Do these five things before you complete the run:

1. Each cause you tested was posted with `tellagen_update_cause`, and its state is current.
2. Each chain step with numbers has a figure built with `tellagen_build_figure` (placement `step_figure`), not written by hand.
3. The key moment has a timeline event from `tellagen_post_timeline_event`, with a `body` and with `blocks` built with `tellagen_build_figure` (placement `timeline_block`).
4. Each evidence ref has `links` or a read-only `command`.
5. Each change ref cites `finding_ids` or `step_ids`.

Then send the result in `result_summary`:

```
tellagen_complete_investigation(
  run_id,
  status: "completed",
  result_summary: {
    assessment: { diagnosis_state: "confirmed" | "likely" | "incomplete" | "inconclusive" | "unknown" },
    causal_paths: [{
      id: "primary", kind: "primary",
      steps: [
        { id: "deploy", claim: "Deploy 4412 shipped at 09:02", verification: "confirmed",
          finding_ids: [11], links: [<from tellagen_build_source_link>] },
        { id: "errors", claim: "5xx rose from 0.2% to 8.1% right after", relation_to_previous: "causes",
          verification: "confirmed", finding_ids: [12],
          figure: <from tellagen_build_figure with placement "step_figure"> }
      ]
    }],
    ruled_out: [{ label: "Database saturation", explanation: "Pool stayed under 40%", finding_ids: [14] }],
    coverage: [
      { source: "Grafana", state: "checked", step_ids: ["errors"], finding_ids: [12] },
      { source: "Kubernetes", state: "gap", summary: "No cluster access", finding_ids: [15] }
    ],
    unknowns: [{ label: "Why staging did not show it", why: "No staging metrics" }],
    change_refs: [
      { role: "regression_source", kind: "pull_request", repo: "acme/checkout", ref: "4412",
        verification: "confirmed", finding_ids: [11] }
    ]
  }
)
```

### Diagnosis structure

Tellagen builds the Diagnosis tab from this summary. Send it when the pickup response lists `diagnosis_structure_v1` in `server_capabilities`. For an older Tellagen, the MCP server removes it and says so in `mcp_notice`, so do not retry.

- **Chain (`causal_paths`):** one primary path of 2 to 4 steps, from the trigger to the customer impact. Each step has a one-sentence `claim`, a `verification`, and the numeric `finding_ids` that prove it. Tellagen rejects a confirmed or likely diagnosis with no chain.
- **Figure:** one per step, only with numbers that you read from a tool result. No number, no figure. Build it with `tellagen_build_figure`. Use `compare` for a before and after, `trend` for a series, `stats` for 2 to 4 key numbers, `checks` for pass or fail, `range_overlap` for ranges that meet, `histogram` for a distribution, `run_history` for CI runs in order, and `diff` for the lines that broke or fixed it.
- **`ruled_out`** (up to 5): the causes that you checked and excluded, from your `negative` findings.
- **`coverage`** (up to 8): one entry per source, with `state` set to `checked`, `gap` (you could not read it) or `not_configured`, and the chain `step_ids` that it proved.
- **`unknowns`** (up to 5): what you could not establish, and why.
- **`change_refs`** (up to 6): for a regression or a CI failure, when the pickup lists `diagnosis_changes_v1`. Tie the run to the change with `role` set to `regression_source`, `fix`, `rollback`, `last_good`, `first_bad`, `verified_by` or `context`. See "Regression and CI failures" in the full guide.
- **Read the response:** `warnings` and a one-line `warnings_summary` come back. The run is already complete, so name anything that you could not fix in your report.

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
| `negative` | Something you ruled out; also one `ruled_out` entry at completion | "Database performance is normal" |
| `gap` | A required source or check that you could not read; also a `coverage` entry with state `gap` | "Kubernetes events were unavailable: no namespace access" |

## Tips

- Start with observations, then look for correlations, form hypotheses, and find evidence
- Post negative findings too — knowing what's NOT the cause is valuable
- Post a `gap` finding for every source you could not read
- Call `tellagen_build_source_link` right after a Grafana or GitHub query, because a proof with no `links` and no `command` shows "No source link" to responders
- Cite findings by their numeric `id` in `finding_ids`, never by claim or key
- Use confidence levels honestly: 0.9+ for near-certain, 0.5-0.7 for plausible, <0.5 for speculative
- Each finding should be atomic — one claim per finding
- If no vendor MCP tools are available, use the codebase, logs, and any accessible documentation
- The investigation context from step 1 helps you ask better questions of vendor tools
