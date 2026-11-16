---
description: Recheck which tools this client can use for a Tellagen diagnosis
allowed-tools: mcp__plugin_tellagen_tellagen__tellagen_enable_toolset, mcp__plugin_tellagen_tellagen__tellagen_report_available_sources
---

Recheck the tools this client can use, and tell Tellagen.

1. Call `tellagen_enable_toolset` with `settings`.
2. Look at the MCP servers and shell tools you have. Map them to `grafana`, `kubernetes`, `github`, `docs` and `local_host`. Make one entry for each key: `found` when you can use it, `not_found` when you cannot. Add a short detail only when it holds no token, no password and no path with a user name.
3. If you have the Kubernetes tool, run the safety check from the `tellagen_report_available_sources` description: four `kubectl auth can-i` tests, with no output printed. Pass the results as `kubernetes_checks`.
4. Call `tellagen_report_available_sources` with the entries. The tools table in Tellagen settings now shows this client.
5. For each tool that is not found, say in one sentence why this client cannot see it: the server is not set up in this client, the command is not on the PATH that the client starts it with, or a setting it needs is missing. If you cannot tell, say that. Tell the person that `npx @tellagen/mcp-server doctor` finds the cause from the config files.

If Tellagen says it does not take a tool report yet, tell the person to ask an admin to update Tellagen, and stop. If it says it is not set up, tell the person to run `/tellagen:connect`, and stop.

Never print a token, a file path, a command output or a value of a setting. Never say a run is read-only: this check says what the Kubernetes identity could do, not what a session will do.
