# Project Context

This file gives Claude Code persistent context about this project. It's read automatically at the start of every session.

## What this app is

An AI-powered data explorer for public astronomy datasets. Users import real data from public APIs, browse it (star systems, individual exoplanets, leaderboards of extremes), and ask natural-language questions about it to get back structured answers and visualizations.

The repo/app is currently named "rowboat" (a leftover pun: "row" as in CSV rows, "boat" completing the word). A rename is planned but not yet done, current naming favorite under consideration: "Parallax" or a pun variant that keeps the "row" wordplay (e.g. "Rowllax"). Don't rename anything unprompted, just be aware the current name is provisional.

## Current architecture

- Ruby on Rails 8.1, PostgreSQL, RSpec (not Minitest, was migrated deliberately)
- Deployed on AWS: ECS Fargate, RDS, ALB, all defined in `terraform/`
- CI/CD via GitHub Actions: `ci.yml` (tests/lint/security scans) triggers automatically, `deploy.yml` triggers via `workflow_run` after CI passes on `main`
- Dependabot configured with auto-merge for patch/minor bumps only; major bumps require manual review (this already caught a real breaking change once, don't loosen this)

## Data model

```
Dataset
  - name, description, source_url, imported_at, row_count
  - has_many :queries
  - metadata-only registry row; does not store the imported rows itself

Exoplanet
  - pl_name, hostname, discoverymethod, disc_year:integer,
    pl_orbper/pl_rade/pl_bmasse/pl_eqt/st_teff/sy_dist:float
  - belongs_to :stellar_host, foreign_key: :hostname, primary_key: :hostname, optional: true
  - indexed on hostname

StellarHost
  - hostname (unique index), st_spectype,
    st_teff/st_rad/st_mass/st_met/st_lum/sy_dist/ra/dec:float
  - has_many :exoplanets, foreign_key: :hostname, primary_key: :hostname

Query
  - question, generated_query (jsonb), result_summary
  - standalone; no dataset reference (this app is scoped entirely to exoplanets/stellar hosts)
```

Reworked from a generic jsonb-based Dataset/DatasetColumn/DatasetRow system (flexible schema, no per-field types, needed explicit casts like `(data->>'pl_rade')::float`) to typed per-dataset tables with real associations. That jsonb design was previously a deliberate, discussed tradeoff; it was revisited and replaced once the query feature's needs became clearer, per the plan this superseded. `Dataset` rows are still created/updated by the import jobs (name, source_url, imported_at, row_count) for the datasets index and future registry use, but no longer own the imported data.

No `User` model currently exists. Auth was deliberately deferred until the core AI-query feature works. Don't add auth unprompted.

## What's built and working

- `ImportExoplanetsJob` (`app/jobs/import_exoplanets_job.rb`) — pulls live data from NASA's Exoplanet Archive (PSCompPars table), confirmed working, imports ~6,300 real rows
- `ImportStellarHostsJob` (`app/jobs/import_stellar_hosts_job.rb`) — pulls the companion stellar-host data from the same archive
- Rake tasks `datasets:import_exoplanets` and `datasets:import_stellar_hosts` (`lib/tasks/import_datasets.rake`) to trigger them
- Browsing UI, no `DatasetsController` (that was the original plan; it ended up split by resource instead): `HomeController#index` (root), `SystemsController#index`/`#show` (star systems list and per-system detail, `kaminari`-paginated, starfield chart), `ExoplanetsController#index`/`#show`/`#random`, `ExtremesController#index` (leaderboards: hottest, coldest, closest-to-Earth-size, most recent, closest-to-Earth)
- The AI query feature: natural-language question → LLM translates to a structured query (filter/aggregate spec, NOT raw SQL, this was a deliberate choice, "Option A" in earlier planning) → execute against the typed tables (`Exoplanet`, `StellarHost`) via a whitelisted `QueryTranslator` → return answer + visualization. Gated behind a session-based access code (`AiAccessController`, `AiAuthorization` concern, `AiCredentials` module for the code and Anthropic API key). See `app/jobs/answer_question_job.rb`, `app/services/query_translator.rb`, `app/services/query_executor.rb`, `app/models/queryable_fields.rb`, `app/controllers/questions_controller.rb`. Uses the `anthropic` gem (~> 1.62).
- A separate ECS service (`rowboat-worker-service`, `terraform/ecs_worker.tf`) runs Solid Queue background job processing via `./bin/jobs`
- ECS Exec is enabled for production debugging (`dangerzone` / `dangerzone-bash` bash functions in `~/.bashrc` exec into the live task)

## What's next (in planned order)

1. NeoWs (Near Earth Object) importer — second data source, JSON-based (needs flattening, unlike the clean CSV exoplanet source). Will likely need its own typed table, following the Exoplanet/StellarHost pattern rather than reintroducing a generic jsonb store.

## Conventions and preferences

- No em dashes in written content (docs, commit messages, comments)
- Prefer complete file contents over partial diffs when discussing code changes
- Concise, direct communication preferred generally
- Terraform changes: always show `terraform plan` output before applying
- Docker builds: this project has been bitten before by `docker run` using a stale local image instead of pulling fresh from a registry, and by ECS tasks not picking up a new `:latest` image without an explicit `force-new-deployment`. Verify pushed image digests match what's actually running when deploy issues come up.

## Local dev

```bash
docker compose up
```

System deps if running outside Docker: `libpq-dev`, `libvips` (required by `image_processing` 2.x / Active Storage).

```bash
bundle exec rspec        # tests
bin/rubocop -a           # autofix lint
bin/brakeman --no-pager  # security scan
bin/bundler-audit        # dependency vuln scan
```

## Deployment

```bash
cd terraform
terraform apply
```

Day-to-day pause/resume uses partial scale-down (ECS desired-count 0, RDS stopped), NOT full `terraform destroy`, since a full destroy recreates the ALB with a new DNS name and requires updating the Cloudflare CNAME record manually each time. See `pause-resume-runbook.md` for the exact commands.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (tywestlie/rowboat), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels used as-is (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.

### Version Control
When asked to create a PR, use gh pr create with a description
covering Summary / Changes / Testing, based on the commits and
diff since main.