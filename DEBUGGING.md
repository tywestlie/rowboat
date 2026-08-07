# Debugging Journey

A record of real problems hit while building and deploying this project, and how they were diagnosed and fixed. Kept here as a reference and because working through infrastructure problems end-to-end is as valuable as the deployment itself.

Each entry follows: **symptom → root cause → fix → takeaway**. Platform-specific notes (mostly Docker Desktop / WSL) are called out separately since most of the underlying lessons apply regardless of OS.

---

## Local environment setup

**Docker CLI not available in a Linux dev environment running under Windows**
Docker Desktop needs its WSL integration explicitly enabled per-distro before the `docker` command is available inside that distro's shell. If you're on native Linux or macOS this doesn't apply, Docker's daemon runs natively.

**Docker credential helper fails with an exec format error**
Symptom: `docker-credential-desktop.exe: exec format error` when pulling/pushing images.
Cause: the credential store config points at a Windows-native binary that a Linux shell can't execute directly.
Fix: remove `credsStore` from `~/.docker/config.json`, falls back to plaintext credential storage, acceptable for a personal dev machine handling short-lived tokens, not for shared or production machines.
Takeaway: cross-platform credential helpers are a common friction point in any Windows+Linux dev setup, not just WSL.

**Missing system libraries when running the app locally**
Symptom: `LoadError: cannot load such file -- vips` or similar, after adding a gem with native dependencies.
Cause: some gems (image processing, PDF generation, etc.) wrap a C library that must be installed at the OS level, the Ruby gem alone isn't enough.
Fix: install the missing system package (`apt install libvips` on Debian/Ubuntu; `brew install vips` on macOS).
Takeaway: whenever a gem's changelog mentions a new "requires X" dependency, check whether X is a system library, not just a gem, before assuming the Gemfile change alone is enough. This class of bug reliably resurfaces in CI too, once per environment (local, CI, Docker image) until each one gets the same system package.

---

## Networking and infrastructure

**ECR image pulls timing out from a private subnet**
Symptom: `CannotPullContainerError ... i/o timeout` when a container tries to pull from ECR.
Cause: private subnets with no NAT Gateway need explicit VPC endpoints to reach AWS services. The ECR API endpoints existed, but ECR stores actual image layers in S3, and the S3 gateway endpoint wasn't associated with the private route table.
Fix: associate the S3 gateway endpoint with both public and private route tables.
Takeaway: "the API endpoint exists" doesn't mean every dependency of that API is reachable. Trace what a service actually calls under the hood, not just its primary endpoint.

**Container crashes with "no such file or directory" for the app's own entrypoint**
Symptom: `bin/rails: no such file or directory` inside a container that ran fine locally.
Cause: the image that got pushed was built from a development Dockerfile relying on a bind-mounted volume for source code, the image itself never had the app baked in.
Fix: build from the actual production Dockerfile (`COPY . .`), not the dev compose config.
Takeaway: "works locally" can be true for reasons that have nothing to do with the image being correct. Always verify an image's contents directly (`docker run <image> ls <path>`) rather than trusting that a successful local run proves the image is right, and be aware that `docker run` uses a cached local image with a matching tag rather than re-pulling from a registry, so this check can itself be misleading if you don't force a pull first (`docker pull`).

**Container can't bind to its configured port**
Symptom: `bind: permission denied` on port 80.
Cause: the container runs as a non-root user (good practice), and non-root processes can't bind to privileged ports (below 1024) on Linux.
Fix: run the app on an unprivileged port internally (3000), let the load balancer handle the public-facing privileged port (80/443) and forward internally.
Takeaway: security hardening (non-root containers) and infrastructure config (port choice) need to be considered together, not independently.

**Two processes in one container both trying to bind the same port**
Symptom: `Address already in use` after fixing the above.
Cause: a reverse proxy (Thruster) and the app server (Puma) both defaulted to the same internal port once the external port was reconfigured.
Fix: explicitly set separate internal ports for the proxy and the app server.
Takeaway: changing one environment variable can have a cascading effect on defaults elsewhere in the same process chain, check the full chain, not just the piece you changed.

---

## DNS and certificates

**DNS record technically exists but doesn't resolve**
Symptom: `NXDOMAIN` or timeout for a record visible in the DNS provider's dashboard.
Cause (recurring, several forms): a DNS record's "name" field auto-appends the zone, so typing the fully-qualified name results in an unintended duplicate suffix. Separately, a record set to "proxied" mode can silently fail for non-HTTP targets like ACM validation strings, since the proxy doesn't know what to do with them.
Fix: verify the record's actual resolved value by querying a public resolver directly (`dig @1.1.1.1 <name>`), not just trusting the dashboard's display. Confirm proxy status is off for anything that isn't a plain web-facing record.
Takeaway: a DNS dashboard showing a record exists doesn't confirm it resolves correctly. Always verify against a real resolver.

**Local machine reports a domain as unreachable while other devices reach it fine**
Symptom: `curl` and `dig` fail locally, but a browser on another device (or a public resolver queried directly) shows the domain resolving correctly.
Cause: local DNS caching, at the OS level, at a virtualization layer, or in a router, can hold onto a negative (failure) result from before a record was correctly configured, independent of whether the record is now fixed.
Fix: query a public resolver directly to confirm ground truth (`dig @8.8.8.8 <domain>`), then flush local caches (varies by OS) or simply wait out the negative-cache TTL.
Takeaway: when a domain seems broken, check a neutral, external source of truth before assuming the infrastructure itself is wrong. Different devices and even different processes on the same device can have independently stale DNS state.

**ACM certificate stuck in "pending validation"**
Symptom: an SSL certificate never issues despite adding the required DNS record.
Cause: usually either the validation record wasn't actually saved correctly (see DNS issues above), or, after a certificate gets recreated, its validation record is genuinely identical to a previous certificate's for the same domain, easy to assume a stale record is "already handled" when it actually needs to be re-verified as present.
Fix: pull the exact expected record directly from the certificate authority's API/console rather than reusing a value from memory or an old command's output, confirm it resolves via a public resolver, then wait for the next validation poll.
Takeaway: don't assume a previously-correct value is still correct after any resource gets recreated. Re-verify from the source.

---

## CI/CD

**A gem update in CI fails immediately with no useful output**
Symptom: a security scanner exits non-zero in seconds, with no findings printed.
Cause: the scanner's exit code was actually flagging "you're not on the latest version of this tool," an `--ensure-latest`-style check, not an actual security finding.
Fix: update the tool itself (`bundle update <tool>`), unrelated to any code change.
Takeaway: a fast failure with no report is often a different failure mode than a slow failure with a report, don't assume every red X in CI means the same kind of problem.

**A dependency bump breaks the app in CI but not in the original PR's local testing**
Symptom: a background job or boot-time initializer errors referencing a library that "should" be present.
Cause: a major version bump changed how a gem declares its own dependencies, previously implicit, now requiring an explicit addition to the Gemfile, and separately, the underlying native library it needs isn't installed in the CI environment by default.
Fix: add the newly-required gem, and add the missing system package to every CI job that boots the app (matching the pattern already used for other system dependencies like database client libraries).
Takeaway: major version bumps deserve manual review even when tests technically pass in some environments, this is exactly why automated dependency updates should auto-merge only patch/minor bumps and leave major bumps for a human to look at.

**Deployed code doesn't match what was just pushed and confirmed to build correctly**
Symptom: a live service is still running old behavior despite a build that locally looks correct.
Cause: testing a locally-built image (`docker run <local-tag>`) doesn't verify what's actually in the remote registry, `docker run` uses a local cached image matching that tag rather than pulling fresh. Separately, a running container in a orchestrated environment (e.g. ECS/Kubernetes) doesn't auto-update just because a `:latest` tag moves, it keeps running whatever digest it originally pulled until explicitly redeployed.
Fix: verify the actual pushed image's digest and push timestamp directly from the registry, and always force a fresh deployment/rollout after confirming a new image is really there.
Takeaway: "I built it and it looked right" and "the registry actually has the new version" and "the running service is actually using the new version" are three separate facts, verify each one independently rather than inferring one from another.

**CI silently stops running entirely, with a normal-looking config**
Symptom: no new checks appear for any push, not tied to any single PR.
Cause: sometimes it's genuinely nothing on your end, the CI provider is having a platform-wide outage.
Fix: check the provider's public status page directly before spending time debugging your own config. If confirmed, have a manual fallback path (running checks locally, deploying by hand) ready so an outage doesn't fully block you.
Takeaway: rule out "is the platform actually down" early when everything you can control checks out clean, and keep a manual escape hatch for your critical paths (like deployment) that doesn't depend on any single automation provider.

---

## General takeaways

- When something "should" work and doesn't, verify each link in the chain independently rather than assuming the whole chain is fine because most of it looks right.
- Prefer checking ground truth (a registry's actual contents, a public DNS resolver, a provider's status page) over trusting a cached, local, or dashboard view of the same information.
- Platform-specific setup friction (Docker Desktop integration, credential helpers, etc.) is usually a one-time cost, worth documenting once rather than re-debugging from memory each time.