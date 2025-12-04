<div align="center">

# Lorx

Modular home climate monitoring & control platform (Elixir / Phoenix / OTP).

</div>

<img width="910" height="1191" alt="Screenshot 2025-12-04 at 21 03 29" src="https://github.com/user-attachments/assets/991315e0-41c8-4d14-82de-cb5aa77d3f5d" />


---

## 1. Overview

Lorx manages thermostatic devices, applies schedule‑based temperature control with hysteresis, supports manual override modes (auto / on / off), streams real‑time updates to a Phoenix LiveView dashboard, and periodically persists historical temperature data.

Current capabilities:

- Device polling (temperature + hardware status)
- Schedule-driven auto mode with hysteresis threshold
- Manual override modes (`:on` forces heating, `:off` forces idle)
- PubSub event fan‑out for UI + persistence decoupling
- Historical temperature storage & retrieval
- Live dashboard with per‑device mode switching

Planned (see Roadmap): authentication, multi‑tenant isolation, external weather integration, richer analytics.

---

## 2. Supervision & Runtime Topology

Application tree (`Lorx.Application`):

```
Lorx.Supervisor (one_for_one)
├─ LorxWeb.Telemetry
├─ Lorx.Repo
├─ DNSCluster (optional / clustering)
├─ Phoenix.PubSub (Lorx.PubSub)
├─ Finch (HTTP client)
├─ LorxWeb.Endpoint (HTTP + WebSocket)
├─ Registry (Lorx.Device.Registry)  # name -> device process
├─ Lorx.DeviceSupervisor (DynamicSupervisor)
└─ Lorx.Collector.Monitor (GenServer)
```

On startup `Lorx.DeviceSupervisor.spawn_children/0` starts one `Lorx.Device` GenServer per row in `devices`.

---

## 3. Core Processes

### 3.1 Lorx.DeviceSupervisor

DynamicSupervisor managing a fleet of per‑device GenServers. Loads devices from the database and starts children `{Lorx.Device, [device.id]}`.

### 3.2 Lorx.Device (GenServer)

Represents one physical thermostat‑capable unit.

Responsibilities:

- Periodically poll hardware (temperature + current status)
- Delegate decision logic to `Lorx.DeviceState`
- Broadcast state changes efficiently
- Accept manual mode changes (`set_mode/2`)

Internal cycle:

1. `init/1` seeds a minimal `DeviceState` then schedules `:setup`
2. `handle_continue(:setup)` loads DB device + schedules + first temp/status, then triggers immediate poll
3. `handle_info(:check_temp)` every poll interval:
   - Recompute new state via `DeviceState.update_state/1`
   - Broadcast telemetry (always) to `temperature_notification`
   - Broadcast dashboard update (only if `updated?`) to `dashboard`

Public API:

- `get_status(id)` – synchronous snapshot (returns full internal state; slated for narrowing)
- `set_mode(id, mode)` – asynchronous override (`:auto | :on | :off`)

### 3.3 Lorx.DeviceState (Pure Logic Module)

Holds and transforms device state.

Fields: `:device, :schedules, :temp, :prev_temp, :status, :target_temp, :updated?, :mode`.

Mode branches:

- `:on` – force switch on (idempotent if already heating)
- `:off` – force switch off
- `:auto` – schedule + hysteresis logic

Hysteresis rule (with threshold T = 0.5):

```
if target > current + T and status == :idle    -> switch_on
if target < current - T and status == :heating -> switch_off
else keep
```

Scheduling:
`get_current_schedule/1` filters by current weekday + time range (supports overnight windows) using a `days` array of string flags (`"true"/"false"`).

### 3.4 Lorx.Collector.Monitor (GenServer)

Subscribes to `"temperature_notification"` and periodically persists snapshots to `temperature_history` respecting `saving_interval` (ms). Throttles writes: only inserts when interval elapsed since last save.

### 3.5 LiveView Layer

**LorxWeb.LiveDashboard** – On mount: fetches all devices, queries each device process for current state, subscribes to `"dashboard"`, and updates each `DeviceComponent` via `send_update/2` upon new broadcasts.

**LorxWeb.DeviceComponent** – Renders a device card with temperature, target, status badge, and three mode buttons. On button click:

- Sends `phx-click` event `set_mode`
- Calls `Device.set_mode/2`
- Optimistically updates local `@mode`; reconciled by broadcast.

---

## 4. PubSub Channels & Events

| Topic                      | Producer                                | Consumers                | Payload                                                    |
| -------------------------- | --------------------------------------- | ------------------------ | ---------------------------------------------------------- |
| `temperature_notification` | Each `Lorx.Device` on every poll        | `Lorx.Collector.Monitor` | `%Lorx.NotifyTemp{device_id,temp,status,target_temp,mode}` |
| `dashboard`                | Each `Lorx.Device` only when `updated?` | LiveDashboard (UI)       | Same struct                                                |

Reasoning: decouple high-frequency polling from UI refresh (UI only when state materially changes) while still capturing regular telemetry for history.

---

## 5. Data Model (Ecto Schemas)

### devices

Fields: `name`, `ip`, timestamps.
Used for process identity and hardware network targeting.

### schedules

Fields: `temp`, `start_time`, `end_time`, `device_id`, `days` (array of strings). Drives auto mode target temperature selection.

### temperature_history

Fields: `device_id`, `timestamp`, `temp`, `device_status`, `target_temp` (+ row timestamps). Populated throttled by Collector.

### Derived / In-Memory Only

`mode` (currently not persisted; defaults to `:auto` on restart) and `updated?` diff flag.

---

## 6. State vs Persistence

| Concern             | Database                         | Process State                  | Notes                              |
| ------------------- | -------------------------------- | ------------------------------ | ---------------------------------- |
| Device identity     | ✔                                | Cached in `DeviceState.device` | Reloaded at load only              |
| Schedules           | ✔                                | `DeviceState.schedules`        | Re-fetched each poll (optimizable) |
| Current temperature | ✖                                | `DeviceState.temp`             | From `DeviceClient`                |
| Device status       | History in `temperature_history` | `DeviceState.status`           | Live vs historical                 |
| Target temperature  | Derived (from schedule)          | `DeviceState.target_temp`      | 0 if none active                   |
| Mode                | ✖                                | `DeviceState.mode`             | Reset to `:auto` after restart     |
| Updated flag        | ✖                                | `DeviceState.updated?`         | Broadcast gating                   |

---

## 7. Data & Control Flow (End-to-End)

1. User opens dashboard → LiveView mounts → loads DB devices → queries each device process → initial render.
2. Each `Lorx.Device` polls: reads hardware → computes new state → broadcasts telemetry (always) & dashboard diff (conditional).
3. Collector persists samples at configured interval.
4. User toggles mode → LiveComponent event → `set_mode/2` cast → device recomputes state immediately → broadcast updates UI.

---

## 8. Key Design Choices

- Separation of decision logic (`DeviceState`) from orchestration (`Device`) simplifies testing.
- Dual-topic PubSub prevents UI overdraw while retaining raw sampling cadence.
- Manual modes override all schedule logic—clear predictable semantics.
- Hysteresis reduces relay chatter / hardware wear.

---

## 9. Current Limitations & Technical Debt

1. Mode not persisted (loss across restarts).
2. Schedule reload every poll (introduces DB overhead).
3. `days` stored as string flags instead of booleans or bitmask.
4. Lack of failure handling / backoff around `DeviceClient` I/O.
5. `get_status/1` leaks full internal struct (violates encapsulation).
6. `updated?` consistency in manual branches (ensure always set).
7. No authentication / multi-tenant boundary yet.
8. No caching for schedule lookups or diffing.
9. Absence of rate limiting for mode toggles.

---

## 10. Roadmap (Proposed)

Short Term:

- Persist `mode` (migration + schema + restore on load)
- Normalize `days` to booleans
- Extract `DeviceView` for safe public snapshot
- Cache schedules with change invalidation

Medium Term:

- Add authentication & authorization
- Multi-tenant scoping (household/workspace model)
- External weather integration (adjust predictive targets)
- Historical analytics endpoints & charts

Long Term:

- Alerting (out-of-range temps, device offline)
- Energy optimization strategies
- API keys / remote control API
- Edge deployment / clustering improvements

---

## 11. Development Setup (TBD Sketch)

```
mix deps.get
mix ecto.setup   # creates & migrates DB, loads seeds if added
mix phx.server
```

Environment config keys (example):

- `config :lorx, :device, polling_interval: <ms>, saving_interval: <ms>`

---

## 12. Testing

Focused tests exist for `DeviceState` decision logic. Recommended additions:

- Mode persistence (future)
- Schedule boundary (overnight, single-day) tests
- PubSub integration tests (broadcast gating on `updated?`)

---

## 13. Contributing

1. Fork & branch
2. Add tests for behavior changes
3. Run formatter & credo (if added later)
4. Open PR with rationale

---

## 14. Glossary

| Term       | Meaning                                                |
| ---------- | ------------------------------------------------------ |
| Device     | Physical heating/thermostat endpoint controlled via IP |
| Schedule   | Time window + target temperature definition            |
| Mode       | Manual override or automatic control strategy          |
| Hysteresis | Threshold band to prevent rapid toggling               |
| Collector  | Background sampler persisting periodic measurements    |

---

## 15. Original TODO (Superseded / Integrated)

- [ ] Dashboard device card: show active schedule window
- [ ] Temperature history chart
- [ ] External temperature ingestion API
- [ ] Authentication layer
- [ ] Multi-tenant (multi-house, cloud-ready)
- [ ] Current weather (https://open-meteo.com/en/docs?time_mode=time_interval&start_date=2025-09-16&end_date=2025-09-16&timezone=Europe%2FBerlin&latitude=45.54&longitude=10.21&hourly=&current=temperature_2m,apparent_temperature,wind_speed_10m,precipitation)

---

## 16. License

TBD

---

## 17. CI & Deployment

| Workflow  | File                           | Trigger                                     | Branch Scope   | Purpose                                                        |
| --------- | ------------------------------ | ------------------------------------------- | -------------- | -------------------------------------------------------------- |
| Elixir CI | `.github/workflows/build.yml`  | `push` (any branch)                         | `*`            | Compile & basic validation (deps fetch + compile)              |
| Deploy    | `.github/workflows/deploy.yml` | `workflow_run` (after successful Elixir CI) | `release` only | Build & push container image, create release tag, deploy stack |

### Badges

You can add these badges (uncomment if you like) at the top of the README:

```
![CI](https://github.com/emadb/lorx/actions/workflows/build.yml/badge.svg)
![Deploy](https://github.com/emadb/lorx/actions/workflows/deploy.yml/badge.svg)
```

### Flow Summary

1. Any push to any branch triggers the Elixir CI workflow.
2. If (and only if) the branch is `release` and CI concludes with `success`, the Deploy workflow is triggered via `workflow_run`.
3. Deploy workflow stages:
   - `precheck`: Ensures CI succeeded and branch == `release`.
   - `setup`: Generates a timestamp-based version (format `YYYY.MMDD.HHMM`).
   - `package`: Builds and pushes a Docker image to GHCR (`ghcr.io/emadb/lorx:<version>`).
   - `tag-and-release`: Creates a GitHub Release with the same version.
   - `deploy`: Downloads release artifacts (compose file), performs a stack deploy on the self-hosted runner.

### Versioning Strategy

The version is time-based (build timestamp). This avoids collisions without manual tagging. If you later introduce semantic versions you can replace the `setup` step logic.

### Redeploy / Rerun Behavior

Re-running the successful CI for a `release` branch commit will (by default) trigger the Deploy workflow again and thus a new version (since timestamp regenerated). If you want to prevent redeploys via rerun, add a guard checking `run_attempt == 1` inside `precheck`.

### Concurrency / Rate Limiting (Optional Enhancements)

Add to the Deploy workflow to prevent overlapping deploys:

```
concurrency:
   group: deploy-release
   cancel-in-progress: true
```

### Required Secrets / Vars

Secrets expected (GitHub UI → Repo → Settings → Secrets and variables):
| Name | Type | Used In | Notes |
|------|------|---------|-------|
| `POSTGRES_PASSWORD` | Secret | Deploy | Injected into stack deploy env |
| `GITHUB_TOKEN` | Built-in | Deploy | Release + artifact download |

Variables (Repository Variables):
| Name | Used In | Purpose |
|------|---------|---------|
| `ENV_NAME` | Deploy | Environment label / runtime flag |
| `DEVICE_POLLING_INTERVAL` | Deploy | Device poll ms override |
| `SAVING_INTERVAL` | Deploy | Persistence cadence ms |

### Local Test of Docker Build

Replicate locally what `package` does:

```
docker build -t ghcr.io/emadb/lorx:dev .
```

### Future Improvements

- Add test (mix test) & dialyzer steps to CI before compile.
- Cache deps & build artifacts (actions/cache) for faster runs.
- Add a security scan (e.g., Trivy or Grype) on the image before push.
- Push SBOM (CycloneDX) alongside the image.

---
