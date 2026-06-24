# Simplify Deployment: Docker Swarm → plain Docker Compose

**Date:** 2026-06-24
**Status:** Approved

## Problem

Deployment uses Docker Swarm (`docker stack deploy`) for an app that only ever
runs a single replica. Swarm adds machinery (stack config rendering, ingress
networking, replicated deploy blocks, `--with-registry-auth`) without benefit.
The GitHub Actions workflow is also overbuilt: four jobs and a GitHub Release
upload/download cycle exist only to ship the compose file to the deploy host —
unnecessary, because the self-hosted runner *is* the production host and already
has the repo checked out. Image tags are timestamps (`2026.0624.1430`), which
are hard to read and remember.

## Context / Constraints

- **Single host:** the self-hosted GitHub Actions runner runs on the production
  machine itself.
- **Postgres is out of scope:** it runs as a separate, long-lived container on
  an external Docker network named `common`, managed outside this deploy. The
  app connects to it at host `postgresql`. Do not touch it.
- **Registry:** images are pushed to `ghcr.io/emadb/lorx`. The runner is already
  authenticated to ghcr (the current workflow pushes without an explicit
  `docker login`).
- **Platform:** `linux/arm64`.

## Decisions

| Topic | Decision |
|-------|----------|
| Orchestrator | Plain `docker compose` (drop Swarm) |
| Image tags | GitHub `run_number` (incrementing integer), e.g. `42` |
| Tags pushed | `:${run_number}` **and** `:latest` |
| Deploy selection | Deploy pins the explicit `:${run_number}` via `VERSION` |
| Rollback | Re-run deploy with an older build number |
| GitHub Releases | Removed |
| Postgres | Untouched; keep external `common` network |

## Design

### `docker-compose-prod.yml`

Replace Swarm-specific config with plain compose semantics:

```yaml
services:
  backend:
    image: ghcr.io/emadb/lorx:${VERSION}
    pull_policy: always
    restart: unless-stopped
    ports:
      - "80:4000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgresql/lorx_dev
      - SECRET_KEY_BASE=xhSxmI3mCFHOfGwkc483qhI1dkXSrw3yh6XniKW88HmcoDSAUcYaW7gObmfz8Occ
      - ENV_NAME=${ENV_NAME}
      - DEVICE_POLLING_INTERVAL=300000
      - SAVING_INTERVAL=900000
      - POWER_METER_IP=192.168.0.50
    networks:
      - common

networks:
  common:
    external: true
```

Changes from current file:
- Remove obsolete `version: "3.9"`.
- Remove the entire `deploy:` block (`mode`, `replicas`, `restart_policy`) —
  Swarm-only.
- `restart: unless-stopped` replaces Swarm's `restart_policy`.
- `pull_policy: always` replaces `--resolve-image always`.
- Collapse long-form `ports` (`target`/`published`/`mode: ingress`) to `"80:4000"`.
- Keep the external `common` network and all environment values unchanged.

### `.github/workflows/deploy.yml`

Collapse four jobs (`setup`, `package`, `tag-and-release`, `deploy`) into **two**,
referencing `${{ github.run_number }}` directly (no job-to-job output passing):

- **`build`** — checkout → `docker/setup-buildx-action` (arm64) →
  `docker/build-push-action` pushing two tags: `:${{ github.run_number }}` and
  `:latest`.
- **`deploy`** (needs `build`, environment `prod`) — checkout, then on the host:
  ```bash
  docker compose -f docker-compose-prod.yml pull
  docker compose -f docker-compose-prod.yml up -d
  ```
  with `VERSION=${{ github.run_number }}` and `ENV_NAME=${{ vars.ENV_NAME }}`
  exported into the step environment. Native compose variable substitution
  replaces the `docker stack config` rendering step.

Removed:
- The `setup` job (timestamp version generation).
- The `tag-and-release` job (GitHub Release creation).
- The deploy `gh release download` step.
- `docker stack config` / `docker stack deploy` and all Swarm flags.

`build.yml` (Elixir CI) is unrelated and stays as-is.

## Out of Scope / Known Issues (unchanged by this work)

- `SECRET_KEY_BASE` and DB credentials are stored in plaintext in the repo
  compose file. Pre-existing; left as-is to keep this change focused. Future
  improvement: move to GitHub secrets / a host `.env` file.
- Registry auth relies on the host's ambient ghcr credentials. If
  `docker compose pull` ever returns 401, add a `docker/login-action` step.

## One-Time Migration Step (manual, on the prod host)

The previous `docker stack deploy ... lorx` left a running Swarm **service**
publishing port 80 via the ingress mesh. Plain `docker compose up -d` cannot
bind `80:4000` while that service holds the port. Before the first new deploy,
on the host:

```bash
docker stack rm lorx          # remove the old Swarm stack
docker service ls             # confirm empty
# (optional, if Swarm is otherwise unused on this host)
docker swarm leave --force
```

A `concurrency` guard (`group: deploy`) was also added to `deploy.yml` so two
quick pushes to `release` cannot interleave on the single self-hosted runner.

Registry auth intentionally relies on the host's existing ghcr credentials (the
same ones the runner already uses to push). We deliberately did **not** add a
`docker/login-action` with `GITHUB_TOKEN`, to avoid overwriting the known-good
host credentials with a token that may lack access to the private image.

## Acceptance Criteria

1. `docker-compose-prod.yml` contains no Swarm-only keys (`deploy:`, `version:`,
   `mode: ingress`) and validates under `docker compose config`.
2. `deploy.yml` has exactly two jobs (`build`, `deploy`), no `setup` /
   `tag-and-release` jobs, and no `docker stack` / `gh release` commands.
3. Images are pushed as both `:<run_number>` and `:latest`.
4. Deploy runs `docker compose pull` + `up -d` pinned to the build's
   `run_number`.
5. Postgres config and the external `common` network are unchanged.
