# Consolidate the Solid Queue worker into Puma

Status: accepted

Supersedes [ADR-0001](0001-separate-ecs-worker-service-for-solid-queue.md).

## Context

ADR-0001 split job processing into its own ECS Fargate service so a stuck or
heavy job couldn't degrade web request latency, and so workers could scale
independently of the web dyno.

That reasoning applied to ECS Fargate, where each service gets its own
CPU/memory allocation from a shared cluster. It's since moved to a single
DigitalOcean droplet (`westlie-cloud-01`) running everything via Docker
Compose. On the droplet, `web` and `worker` are two separate containers, but
they compete for the same fixed pool of RAM and CPU on one machine — there's
no independent scaling to protect. Running two full Rails boots (each
~250-450MB RSS just from `eager_load` + gems) to get isolation that the
underlying host can't actually enforce was costing roughly 2x the idle
memory for no real benefit at this app's current job volume (the NASA
import jobs and the AI query jobs).

## Decision

Set `SOLID_QUEUE_IN_PUMA=true` in the droplet's `.env` and remove the
`worker` service from `docker-compose.yml`. `config/puma.rb` already has:

```ruby
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

which runs the Solid Queue supervisor inside the Puma process, so no code
change is required, only the env var and the compose file.

## Consequences

- Roughly halves this app's idle memory footprint on the droplet (one Rails
  process instead of two).
- A stuck or long-running job (e.g. a large import) now shares Puma's
  process with web requests and can degrade request latency while it runs.
  Acceptable for now given current traffic and job volume; revisit if that
  changes.
- Recurring tasks (`config/recurring.yml`) run inside the same process;
  Solid Queue still dedups recurring execution via a DB unique constraint,
  so this is safe.
- No independent scaling of job processing vs. web. Not needed on a
  single-droplet deployment, but relevant if this ever moves to multiple
  droplets or back to a platform with independent service scaling.

## How to revert

If job volume grows enough to noticeably affect web latency, or the droplet
is resized with more available memory, split them back out:

1. On the droplet, edit `.env` and remove (or set to false)
   `SOLID_QUEUE_IN_PUMA`.
2. Edit `/srv/rowboat/docker-compose.yml` to add back a `worker` service:

   ```yaml
     worker:
       build: .
       restart: unless-stopped
       command: bin/jobs
       env_file: .env
       networks:
         - web
   ```

3. Redeploy (`docker compose up -d --build`, or via the normal
   `deploy-droplet.yml` path if `.env` changes are already in place before
   the next push to `main`).

No database or code changes are needed either direction — the queue
database (`rowboat_production_queue`) and job definitions are the same
regardless of which process runs the supervisor.
