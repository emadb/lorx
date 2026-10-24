# External temperature meter — implementation plan

## Decisions

- Use the existing `external_temperature_history` table and `Lorx.ExternalMeter.TempEntry` schema. Do not replace the current untracked schema or migration.
- The external meter is optional. Read its IP address from a runtime environment variable into device settings; the API client builds `http://<ip>/temp`, like the other device clients. An absent IP does not prevent Lorx from starting. Poll immediately, then every five minutes by default.
- Each valid JSON response with a numeric `temp` produces one timestamped history row, including repeated values. Reject missing or nonnumeric temperatures.
- The GenServer owns the displayed status. On startup, load the latest saved value. A request or response failure sets the status to `:error`. A valid temperature is displayed and broadcast even if its database insert fails; that reading is not in history and a restart restores the latest saved reading instead. With no configured IP, show the last saved value marked **not configured**.
- The home page reads the GenServer status on mount and receives updates after each poll. Replace **Tensione** with **Temperatura Esterna** in °C; retain power and current.

## Work items

1. **Polling and persistence** — Status: `done` (HTTP success, duplicate readings, malformed replies, and request errors exercised against a local source; database-write failure handled in code but not induced at runtime)
   - Goal: Complete the draft external-meter GenServer and HTTP reader with a five-minute default interval, startup read, validated JSON, one attempted insert per valid poll, and explicit communication-error status. Preserve the valid reading in state and broadcast it even when persistence fails; report the persistence failure without crashing the polling process. Load the latest persisted reading on startup; supervise the server. Preserve the corrected module names in the two `api_client.ex` files; keep URL construction in the external API client.
   - Files: `lib/lorx/external_meter/server.ex`, `lib/lorx/external_meter/api_client.ex`, `lib/lorx/application.ex`, existing `lib/lorx/external_meter/temp_entry.ex` only if required.
   - Acceptance checks: A local HTTP test endpoint returns `{"temp":18.0}` and yields one timestamped row and current status; identical consecutive responses yield two rows; malformed JSON, missing/nonnumeric `temp`, HTTP failure yields `:error` without a new row; insert failure leaves the valid temperature visible but creates no row. Restart restores the newest saved value.

2. **Runtime configuration** — Status: `done` (configured and unset environments exercised)
   - Goal: Read the external meter IP from an environment variable into device settings at runtime; keep an unset IP safe for local development and tests. The API client builds the fixed `/temp` URL. Make the five-minute default explicit in config without requiring a real device.
   - Files: `config/config.exs`, `config/runtime.exs`, `config/test.exs` if needed, `README.md` for operator setup.
   - Acceptance checks: With no configured IP, the app starts, performs no external-meter request, and reports not configured. With a configured local IP, it polls immediately. Do not record real addresses or environment values in documentation or test output.

3. **Home-page status** — Status: `done` (initial render and live update observed in a browser)
   - Goal: Replace the voltage tile with external temperature while keeping the power and current tiles. Show the GenServer status on initial render and update it after each poll; distinguish error, no reading, and not configured.
   - Files: `lib/lorx_web/components/live_dashboard.ex`, `lib/lorx_web/components/live_dashboard.html.heex` if needed, `lib/lorx_web/components/power_consumption_component.ex`.
   - Acceptance checks: The home page shows temperature in °C after a good reading, an error after a communication failure, the valid temperature after a database write failure, and the last saved value marked not configured when the IP is absent; a newly opened page agrees with an already open page. Power and current still render.

4. **Business-level verification** — Status: `done` (manual flow complete; known project-wide checks still fail as noted below)
   - Goal: Exercise the configured local HTTP source, persistence, restart behavior, and home-page updates in a running application. The user waived new automated tests for now.
   - Files: no test files; use local runtime fixtures outside the repository.
   - Acceptance checks: Run available project checks and report existing unrelated failures. Start the application against a local stub and check HTTP status/body, saved row, and browser rendering/console. Report any unverified boundary explicitly.

## Verification record

- `mix ecto.migrate` applied the existing external-temperature migration to the local development database. A configured local HTTP source returned a temperature, the home page returned HTTP 200 and showed it, and a database query found the saved row. Synthetic rows were removed after the check.
- An unset IP returned HTTP 200 and showed **Non configurato**. A browser showed the new value after a later poll without a reload; browser console: zero errors, one existing Tailwind CDN warning.
- A temporary local integration check exercised duplicate readings, invalid JSON, missing or nonnumeric temperature, and unreachable HTTP. It passed; the test file was removed when the user waived new automated tests.
- `mix compile` and `mix format --check-formatted` on changed files pass. The repository-wide format check includes pre-existing unformatted templates; `mix compile --warnings-as-errors` fails on existing HEEx/core-component warnings. `mix test` fails on existing page-test expectations and device-fixture/supervision failures; no new tests remain.
- Persistence-failure behavior and real hardware were not exercised. The persistence error branch logs the failure and keeps the received temperature visible as agreed.

## Scope note

Existing user changes in `mix.exs`, `.tool-versions`, `AGENTS.md`, and the external-temperature migration/schema are outside this plan unless a later item requires a targeted edit. The new external-meter server and HTTP client drafts are user work; preserve and complete them under item 1 after approval. The existing deletion under `docs/` remains untouched.
