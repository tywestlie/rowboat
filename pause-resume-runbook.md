# Pause/Resume Runbook (historical, AWS-specific)

**Status: deprecated.** This runbook described how to pause and resume the previous AWS deployment (ECS Fargate desired-count scaled to 0, RDS instance stopped) without doing a full `terraform destroy`, which would have recreated the ALB with a new DNS name and required a manual Cloudflare CNAME update each time.

That AWS infrastructure is being decommissioned. The current deployment is a single DigitalOcean Droplet (`westlie-cloud-01`) running Docker Compose continuously, at a flat cost of roughly $20-30/month regardless of load. There's no per-resource billing to optimize by pausing overnight or between uses the way ECS/RDS had, and no ALB-with-changing-DNS problem to work around, so a pause/resume workflow doesn't carry its weight here.

If cost ever becomes a concern, the droplet itself can simply be powered off and back on (`doctl compute droplet-action power-off/power-on`) without any DNS implications, since the droplet's IP is stable across a stop/start. That's the closest equivalent, but it hasn't been needed so far and isn't currently part of any regular workflow.

Kept here for historical reference in case the AWS architecture in `terraform/` is ever revived.
