# CLAUDE.md

Guidance for an agent that changes this repository: the Tellagen plugin for Claude Code. It holds no code of its own. It starts `@tellagen/mcp-server` (from `Tellagen/tellagen-mcp-server`), adds three commands and one skill, and records steps through hooks.

## What is here

- `.claude-plugin/plugin.json`: name, version and the `record_steps` setting.
- `.mcp.json`: how the client starts the server.
- `hooks/hooks.json`: the session start line and the step recording, each a call of the same server package.
- `commands/`: `/tellagen:connect`, `/tellagen:diagnose`, `/tellagen:check-tools`.
- `skills/investigate/SKILL.md`: the short version of the server's guide. The sections "Diagnosis structure" and "Regression and CI failures" say the same as the guide (`SKILL.md` in the server repository), so change both together.

## Things that move together

- **The server range.** `.mcp.json` and every command of `hooks/hooks.json` name the same range of `@tellagen/mcp-server`. Change it with `scripts/set-server-range.sh '<range>'`; with no argument the script prints the range and fails when the files disagree. A `^0.x.y` range does not take the next minor version, so a new minor version of the server needs the range raised here.
- **The version.** `.claude-plugin/plugin.json` holds the plugin version, and the marketplace list names the same one (the sync script sets it). Ask the maintainer whether a change needs a new version before you raise it.
- **The marketplace copy.** People install from `Tellagen/tellagen-marketplace`, which holds a copy of this plugin in `plugins/tellagen`. A change here reaches nobody until that copy is refreshed: run `scripts/sync-marketplace.sh <marketplace checkout>` and open a PR there. `scripts/sync-marketplace.sh --check <marketplace checkout>` fails when the copy differs, and the marketplace runs it in CI.

## Rules

- A skill description says when to use the skill, with the words a person would type. Claude reads only the description when it decides to load the skill.
- Never tell the model to read the whole guide first. The server names the guide part to read at each step.
- This repository is public. Name no internal ticket, person or private path.
- Do not commit, push or change the marketplace unless you are asked to.
