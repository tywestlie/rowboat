# Restore separate worker service, and track production compose in git

Status: accepted

Supersedes [ADR-0002](0002-consolidate-worker-into-puma.md).

## Context

ADR-0002 consolidated the Solid Queue worker into Puma to reduce this app's
idle memory footprint on `westlie-cloud-01`. Measured in isolation it
worked: `docker stats` showed the app's own containers drop from ~650MB
(`web` + `worker`) to ~406MB (`web` alone).

But that wasn't actually the goal — the goal was to lower the droplet's
memory usage as shown on the DigitalOcean dashboard, which sat at 53.1%
before the change and 53.4% after. No visible improvement. Investigating
why: the dashboard percentage is dominated by things this change can't
touch — `dockerd`/`containerd` alone are a fixed ~294MB (15% of the
droplet's 1.9GB) regardless of app architecture, and a single eager-loaded
Rails boot already has a large baseline footprint. The ~150-250MB saved by
merging the worker into Puma is a small fraction of the total and doesn't
move the percentage in any way that matters, since freed memory is
immediately reclaimed by the OS as page cache rather than sitting idle.

Given the consolidation doesn't achieve the actual goal, and it does carry
a real cost (a stuck or long-running job now shares a process with web
requests, exactly the failure mode ADR-0001 was written to avoid), it's not
worth keeping. Reverting to a separate worker service.

Separately: the production `docker-compose.yml` had never actually been
tracked in git. `/srv/rowboat` is a checkout of this repo (`deploy.sh` runs
`git pull origin main` there), but the repo's own `docker-compose.yml` is
the dev config (Postgres container, `Dockerfile.dev`) — production's
compose file was hand-created directly on the droplet and diverged from
version control from the start. Every deploy-time compose change had to be
made by SSHing in and editing the file directly, with no history, review,
or way to revert other than the operator's memory of what it used to say.
That's how the previous consolidation change happened via SSH steps
instead of a commit.

## Decision

- Revert to a separate `worker` service running `bin/jobs`, matching
  ADR-0001. Unset `SOLID_QUEUE_IN_PUMA` (or set to `false`) in `.env`.
- Add `docker-compose.prod.yml` to the repo as the source of truth for the
  production stack, mirroring the existing `Dockerfile` /
  `Dockerfile.dev` split. `deploy.sh` now runs
  `docker compose -f docker-compose.prod.yml ...` explicitly instead of
  relying on the default `docker-compose.yml` filename, so dev and prod
  configs never collide on the same path.
- Future production compose changes (adding/removing services, restart
  policies, labels, etc.) go through a commit to
  `docker-compose.prod.yml` and a deploy, not a manual SSH edit.

## Consequences

- Idle memory returns to ~650MB for this app's own containers (worker
  isolation restored), which per the investigation above was never the
  actual lever on the droplet's dashboard percentage anyway.
- Production compose changes are now reviewable, revertible via git, and
  visible in `git log` instead of living only in one operator's memory of
  an SSH session.
- One-time manual step required on the droplet: the existing
  `/srv/rowboat/docker-compose.yml` has uncommitted local edits (it's the
  divergent hand-maintained file described above) and is no longer read by
  `deploy.sh` after this change. It can be left in place (inert) or
  discarded; it's not deleted automatically to avoid data loss if
  something was relying on it outside of `deploy.sh`.
- If droplet memory usage needs to actually come down, the real levers are
  a bigger droplet (increases the denominator) or reducing the fixed
  Docker/Rails baseline itself — not the web/worker split. See the
  investigation notes above before revisiting process consolidation as a
  memory fix.
