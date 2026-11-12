# Tellagen Plugin for Claude Code

Claude Code plugin for [Tellagen](https://tellagen.com): diagnose incidents with your own tools, post structured findings and figures, and keep a record of the steps.

## What's included

- **Tellagen MCP server** ([`@tellagen/mcp-server`](https://www.npmjs.com/package/@tellagen/mcp-server)): tools for reading incidents, running diagnoses, posting findings, causes, figures and source links, and promoting to timelines.
- **`/tellagen:connect`**: sign in with your browser. No API key to copy.
- **`/tellagen:diagnose [run or incident]`**: find the run that waits for you in Tellagen and diagnose it. With no argument it takes the run that waits.
- **Investigation skill** (`/tellagen:investigate`): the workflow for a full diagnosis.
- **Hooks**: a session start check, and the recording of Grafana, GitHub, `kubectl` and `gh` calls as steps (see "Hooks" below).

## Install

```bash
/plugin marketplace add tellagen/tellagen-marketplace
/plugin install tellagen@tellagen-marketplace
```

Then run `/tellagen:connect`. Claude shows a short code, you check it in the browser and approve. The key goes to your system keychain.

Claude Desktop does not run plugins. To use Tellagen there, add the server to `claude_desktop_config.json` as the [server README](https://github.com/Tellagen/tellagen-mcp-server#2-add-the-server-to-your-client) shows, and ask Claude to sign in to Tellagen.

### Sign out

`npx @tellagen/mcp-server logout` removes the key from this computer. To sign the client out on the server too, open **Settings > Local diagnosis** in Tellagen, find the client under **Connected clients**, and choose **Sign out**; that revokes the key.

### Use an API key instead

Set `TELLAGEN_API_KEY` and `TELLAGEN_API_URL` (they win over a sign-in). In `~/.claude/settings.json`:

```json
{
  "env": {
    "TELLAGEN_API_KEY": "tllg_your_key_here",
    "TELLAGEN_API_URL": "https://mycompany.api.tellagen.com"
  }
}
```

Create the key in **Settings > API Keys** with the **Local Diagnosis** preset, which sets the scopes it needs (`incidents:read` and `incidents:write`).

## Which server version

The plugin starts `@tellagen/mcp-server@^0.5.0`: the newest 0.5 release, and not a 0.6 or later one. A plugin that pins one exact server version goes stale (installed copies keep an old protocol and an old skill). A range that follows every release would let a breaking release reach the hooks at once, which run the server on each Grafana, GitHub, `kubectl` and `gh` call with access to your stored key. The caret range follows the fixes of 0.5 and stops at the next minor version, so a plugin update raises it on purpose. The hooks start the server with `--prefer-offline`, so they use the version the server start already installed, and a hook never waits on the network when the package is in the cache.

## Usage

```
/tellagen:diagnose
```

Or ask directly: `Investigate incident #42 on Tellagen`. Claude reads the incident, attaches to a run (visible live in the Diagnosis tab), queries your Grafana, GitHub, Kubernetes and other tools, posts findings as it discovers them, and completes the run with the cause chain, figures and what it ruled out.

## Hooks

The plugin installs hooks in Claude Code:

- **Session start**: `npx @tellagen/mcp-server status --line` prints one sentence when the sign-in is missing or about to expire, when the workspace wants a newer server, or when a diagnosis run is open ("Call tellagen_resume"). It prints nothing when all is well, and it never contacts Tellagen.
- **Step recording**: after a Grafana or GitHub MCP tool, or a shell command that starts with `kubectl` or `gh`, `npx @tellagen/mcp-server trace-hook` records the call as a step of the open run. It does nothing when no run is open. It runs in the background and never holds up the tool call; if Tellagen does not answer in two seconds it gives up.

**What the step recording sends:** the tool, the query or command (tokens and passwords masked), the time range when there is one, how long it took, the size of the result and the first 300 characters of it. It never sends the whole result. Tellagen redacts the step again when it receives it.

To turn step recording off, set the plugin option **Record steps of a diagnosis** to off (`/plugin configure tellagen@tellagen-marketplace`), or set `TELLAGEN_RECORD_STEPS=0`. Claude then posts the steps by hand. Clients with no hooks keep that manual flow.

## Let your computer take diagnosis runs

With listening on, a diagnosis you start in Tellagen needs no terminal: your computer takes the run and runs it with your own Claude Code, with no window. It works on macOS and Linux. In Tellagen, open **Settings > Local diagnosis** and turn on **Take my runs automatically**. Then run in a terminal:

```bash
npx @tellagen/mcp-server listen
```

When you choose **Run diagnosis** on the Diagnosis tab of an incident, the listener starts Claude Code for the run.

A listened run only reads. It may use the Tellagen diagnosis tools (so it writes to its own run and can add a timeline event, but it cannot create or edit an incident or a postmortem), the read tools of Grafana and GitHub, and `kubectl` and `gh` commands that read from a fixed list of verbs and flags (no chaining, no secrets, no watching). A rule checks every shell call before it runs, and anything outside the list is refused and the run records a gap. It never runs in a mode that skips permission prompts, runs one diagnosis at a time and stops each after 45 minutes. Text from Tellagen and from tools is treated as data, not as instructions. The first start makes one short model call to prove that the rule is active and obeyed in your Claude Code version. Only Claude Code can be listened to: Codex is refused, because it cannot be held to a read-only tool list, and so is Windows, because the listener cannot prove the rule there. Ctrl+C stops listening and lets the current run finish. `listen --status` shows the current run and the last five. The [server README](https://github.com/Tellagen/tellagen-mcp-server#listening) has the exact rules and the settings (`~/.tellagen/listen.json`).

## MCP tools

### Read

| Tool | Description |
|------|-------------|
| `tellagen_get_incident` | Get incident details |
| `tellagen_list_incidents` | List incidents, filter by status |
| `tellagen_get_incident_timeline` | Get timeline events |
| `tellagen_list_investigation_runs` | List investigation runs |
| `tellagen_list_findings` | List findings for an incident |
| `tellagen_get_finding` | Get a single finding with evidence refs |

### Write

| Tool | Description |
|------|-------------|
| `tellagen_create_incident` | Declare a new incident |
| `tellagen_start_investigation` | Start an investigation run |
| `tellagen_post_finding` | Post a structured finding |
| `tellagen_complete_investigation` | Close an investigation run |
| `tellagen_update_finding` | Dismiss or restore a finding |
| `tellagen_promote_finding` | Promote a finding to the timeline |

### Diagnosis

| Tool | Description |
|------|-------------|
| `tellagen_pick_up_investigation` | Attach to a run and read its context and capabilities |
| `tellagen_post_trace_step` | Post a check, with its outcome and cause key |
| `tellagen_update_cause` | Post or update a cause you are testing |
| `tellagen_build_figure` | Build a typed figure (stats, compare, trend, checks, range_overlap, histogram, run_history, diff) from numbers you read |
| `tellagen_build_source_link` | Build a Grafana or GitHub link for an evidence ref |
| `tellagen_get_context_attachment` | Read a screenshot a responder added to a run |

The server lists the `diagnosis` and `incidents` tools at the start (32 tools). Others (timeline, postmortem, settings) are listed when a task needs them: Claude calls `tellagen_enable_toolset`, or you set `TELLAGEN_TOOLSETS` (see the server's documentation). The server has 50 tools in all.

## Works with your existing tools

The plugin composes with any MCP servers you already have configured. Claude will use them automatically during investigations:

- **Grafana** — query Loki logs, Prometheus metrics, search dashboards
- **GitHub** — check recent deploys, read diffs, search code
- **PagerDuty** — alert history, escalation details
- **Sentry** — error groups, stack traces
- **Kubernetes** — pod restarts, OOMKills, events

No extra configuration on the Tellagen side — just install the vendor MCP servers and Claude uses them.

## Requirements

- [Claude Code](https://claude.ai/claude-code) with plugin support (hooks need a recent version; without hooks the plugin works and you post steps by hand)
- Node.js 18 or later (the plugin starts the MCP server with `npx`)
- A [Tellagen](https://tellagen.com) workspace and a responder seat

## License

MIT
