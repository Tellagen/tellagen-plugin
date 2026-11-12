---
description: Diagnose the incident run that waits for you in Tellagen
argument-hint: "[run ID or incident number]"
allowed-tools: mcp__plugin_tellagen_tellagen__tellagen_next_investigation, mcp__plugin_tellagen_tellagen__tellagen_pick_up_investigation, mcp__plugin_tellagen_tellagen__tellagen_resume, mcp__plugin_tellagen_tellagen__tellagen_start_investigation
---

Diagnose with Tellagen. The argument is: $ARGUMENTS

- If the argument is empty, call `tellagen_next_investigation` to find the run that waits for you. With one run, use it. With several, ask the person which one. With none, say so and offer to start a run for an incident.
- If the argument is a number, or looks like an incident number (`42`, `#42`, `INC-42`), it is an incident. Call `tellagen_next_investigation` with that `incident_id`. If a run waits, pick it up. If none waits, start one with `tellagen_start_investigation` and pick it up.
- Otherwise the argument is a run ID. Call `tellagen_pick_up_investigation` with it.
- If a run is already open on this computer and the person says to continue, call `tellagen_resume`.

Pick the run up with `tellagen_pick_up_investigation`. Pass your model name and the data sources you can reach. Then follow the `tellagen:investigate` skill: read the context, post each cause you test and each finding when you find it, build figures with `tellagen_build_figure`, and complete the run with a result whose headline has 15 words or fewer.

If Tellagen says it is not set up, tell the person to run `/tellagen:connect`, and stop.
