# Rowboat

An AI-powered data explorer for public astronomy datasets. Import real data (starting with confirmed exoplanets from NASA's Exoplanet Archive), then ask natural-language questions about it and get back structured answers and visualizations.

## Tech stack

- Ruby on Rails 8.1
- PostgreSQL
- RSpec for testing
- Deployed on AWS (ECS Fargate, RDS, ALB) via Terraform
- CI/CD via GitHub Actions

## Features

- Import datasets from public APIs (NASA Exoplanet Archive to start, Near Earth Object data planned next)
- Flexible schema per dataset, no migration needed to add a new data source
- Ask questions about a dataset in plain English (in progress)

## Local setup

Requirements: Docker, Docker Compose.

```bash
docker compose up
```

The app will be available at `localhost:3000`.

### System dependencies

If running outside Docker, you'll also need:

```bash
sudo apt install -y libpq-dev libvips
```

## Running tests

```bash
bundle exec rspec
```

## Importing data

```bash
bin/rails datasets:import_exoplanets
```

Pulls live data from NASA's Exoplanet Archive and seeds it into the database.

## Deployment

Infrastructure is defined in `terraform/`. The app deploys automatically to AWS via GitHub Actions on merge to `main`, after CI passes.

```bash
cd terraform
terraform apply
```