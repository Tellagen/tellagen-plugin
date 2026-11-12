---
description: Sign in to Tellagen with your browser (no API key to copy)
allowed-tools: mcp__plugin_tellagen_tellagen__tellagen_sign_in
---

Sign the person in to Tellagen.

1. Call `tellagen_sign_in`.
2. If it says `already_signed_in`, tell the person which workspace and stop. Call it with `restart` true only if they ask to sign in again.
3. If it says `waiting`, tell the person the short code (`user_code`) and the address (`verification_uri_complete`). Say that a browser window may have opened, and that they should check that the code on the page matches before they approve.
4. Call `tellagen_sign_in` again with `wait_seconds` 20. Repeat until the status is not `waiting`.
5. On `signed_in`, tell the person the workspace and where the key is stored (`storage`). If `storage_notice` is there, tell them that too. Say that the Tellagen tools work now.
6. On `denied`, `expired` or `failed`, tell the person the `message` and offer to try again.

Never ask the person for an API key, and never repeat one. A sign-in key is not shown to you.
