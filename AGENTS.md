# Lorx project guidance

Lorx is an Elixir/Phoenix application for device polling, heating control, and temperature history. Follow the existing OTP and Phoenix structure. Read `README.md` for the data flow and module overview; confirm details in the source before changing behavior.

## Run and verify

- Use `iex -S mix phx.server` for an interactive shell **with** the HTTP server. `iex -S mix` starts the application but does not listen for HTTP requests. In development, open `http://localhost:4000/`; `config/dev.exs` binds to IPv4 loopback only.
- The application starts `Lorx.Repo` and device processes. Have a local PostgreSQL database configured before testing a running server. Be careful with real device network access and the admin restart route.
- For code changes, run `mix format --check-formatted`, `mix compile --warnings-as-errors`, and `mix test`. Tests use the test database; see `config/test.exs` and the `test` alias in `mix.exs`. For HTTP or LiveView changes, also exercise the changed route while the server runs.

## Change boundaries

- `lib/lorx/shelly/device_state.ex` holds control decisions; `lib/lorx/shelly/device.ex` orchestrates polling and device state. Keep pure decision logic separate from hardware I/O.
- `lib/lorx_web/` contains routes, controllers, and LiveView UI; `lib/lorx/management/` contains persisted device and schedule data; `lib/lorx/collector/` writes temperature history.
- Check both process state and persisted state when changing modes, schedules, or history. Modes are currently in memory; do not assume that they survive a restart.
- Use environment-specific configuration in `config/`. Treat `.env` and runtime environment values as sensitive; do not include them in output or documentation.
