# Security policy

## Report a vulnerability

Email hello@tellagen.com with the subject "Security report". Do not open a public issue for a vulnerability.

Tell us which version you use, what you found, and the steps to repeat it. We reply as soon as we can.

## Supported versions

We fix security problems in the latest release of this plugin and of `@tellagen/mcp-server`. Update to the latest version before you report.

## What the plugin does on your machine

The plugin starts the Tellagen MCP server on your computer with `npx`. Its hooks run that server after Grafana, GitHub, `kubectl` and `gh` calls, to record the call as a step of the open diagnosis run. A hook masks tokens and passwords in the query or command, and sends the first 300 characters of the result, never the whole result. You can turn step recording off with the plugin option "Record steps of a diagnosis".

The sign-in key is stored in your system keychain. The plugin does not store the credentials that Claude Code uses for other tools.
