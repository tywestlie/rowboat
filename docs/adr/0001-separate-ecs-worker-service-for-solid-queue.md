# Separate ECS worker service for Solid Queue

Status: accepted

Production has no Solid Queue supervisor running: `SOLID_QUEUE_IN_PUMA` is only set in `config/deploy.yml` (Kamal), which isn't the actual deploy path, and the ECS task definition's `environment` block never sets it. Jobs enqueued via `perform_later` currently sit unprocessed.

We considered flipping `SOLID_QUEUE_IN_PUMA=true` in the ECS task definition — a one-line change that runs the Solid Queue supervisor inside the existing Puma process. We rejected it: it couples job processing to the web dyno's CPU/memory budget and lifecycle, so a stuck or heavy job (e.g. a large import) can degrade request latency, and scaling workers independently becomes impossible.

Instead, we're adding a second ECS Fargate service in the same cluster, running the same `rowboat-web` image with its container `command` overridden to `./bin/jobs`. It reuses the existing execution/task IAM roles and Secrets Manager wiring, gets its own minimal egress-only security group (it accepts no inbound traffic) and its own CloudWatch log group, and is deployed by extending the existing `deploy.yml` GitHub Actions job rather than a separate workflow. Sized at 256 cpu / 512 memory, `desired_count = 1`, no autoscaling yet — `config/queue.yml` already runs a single worker process covering all queues, so this matches current load; scale up if/when there's a real backlog.

## Consequences

- Two ECS services to keep in sync on deploys (handled by extending the one CI job, not a new one).
- Recurring tasks (`config/recurring.yml`) run inside the worker's own supervisor; Solid Queue dedups recurring execution via a DB unique constraint, so this stays safe if `desired_count` is ever raised.
