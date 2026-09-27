# Terraform — existing DOKS cluster as code (Aufgabe 3)

Brings the already-running DigitalOcean Kubernetes cluster under Terraform
management **without recreating it**, using the `import` block plus
`terraform plan -generate-config-out=generated.tf`.

## Files

```
terraform/
├── versions.tf                # required_version + provider constraint
├── providers.tf               # DigitalOcean provider (token via variable)
├── variables.tf               # inputs (do_token, cluster_id, region, …)
├── imports.tf                 # import block: state ← existing cluster
├── main.tf                    # cleaned resource body (post-generate)
├── database.tf                # Managed PostgreSQL cluster + db + user + firewall (Aufgabe 4)
├── outputs.tf                 # useful outputs (cluster_id, endpoint, postgres_*)
├── terraform.tfvars.example   # copy → terraform.tfvars, fill in values
└── .gitignore                 # excludes *.tfvars, state, generated.tf
```

## Prerequisites

- Terraform ≥ 1.6 (`import` block requires 1.5+; we pin ≥ 1.6 for stability).
- A DigitalOcean API token with **read + write** on Kubernetes.
- The cluster UUID (`doctl kubernetes cluster list` or the DO UI).

## Workflow

### 1. Provide credentials — never in the repo

```sh
# Preferred: environment variable (also picked up by doctl)
export TF_VAR_do_token='dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

# Alternative: terraform.tfvars (git-ignored)
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars, set do_token / cluster_id
```

### 2. Initialise

```sh
terraform init
```

### 3. First import — generate the initial resource body

Only needed when bootstrapping. Skip on subsequent runs.

```sh
terraform plan -generate-config-out=generated.tf
```

Terraform reads the live cluster via the DO API and writes every attribute it
sees to `generated.tf`. **This file is git-ignored** — treat it as scratch.

### 4. Clean it up → `main.tf`

Merge/replace the interesting bits into `main.tf`, then delete `generated.tf`.

- Drop computed-only fields (`id`, `created_at`, `updated_at`, `status`,
  `ipv4_address`, `endpoint`, `kube_config` …).
- Replace hardcoded values with `var.*` references — the current `main.tf`
  already parametrises name, region, version, tags, node_pool sizing, HA.
- Keep provider-default fields explicit (e.g. `surge_upgrade = true`) so
  future plans stay noise-free.

### 5. Verify

```sh
terraform fmt -check -recursive
terraform validate
terraform plan
```

`plan` must report **no changes** for the existing cluster. If it does, either
adjust the variables (values.tfvars) or fold the missing attribute into
`main.tf`.

### 6. Apply — should be a no-op on first run

```sh
terraform apply
```

## Rotating the API token

```sh
export TF_VAR_do_token='dop_v1_new_token'
terraform plan   # provider re-authenticates on the next call
```

## Managed PostgreSQL (Aufgabe 4)

`database.tf` provisions a `digitalocean_database_cluster` (Postgres 16),
declares the application database and user, and locks the firewall to the
DOKS cluster + any operator CIDRs listed in `var.postgres.allowed_ip_cidrs`.

### Feeding the Helm chart

`helm/user-mgmt/values.yaml` carries placeholders under `backend.database.*`.
Materialise the real values from Terraform outputs at deploy time – **never**
commit real credentials.

```sh
# From within terraform/
PG_HOST=$(terraform output -raw postgres_host)
PG_PORT=$(terraform output -raw postgres_port)
PG_DB=$(terraform output -raw postgres_database)
PG_USER=$(terraform output -raw postgres_username)
PG_PASS=$(terraform output -raw postgres_password)

helm upgrade --install user-mgmt-prod ../helm/user-mgmt \
  --namespace user-mgmt-prod \
  -f ../helm/user-mgmt/values.yaml \
  -f ../helm/user-mgmt/values-prod.yaml \
  --set-string backend.database.host=$PG_HOST \
  --set-string backend.database.port=$PG_PORT \
  --set-string backend.database.name=$PG_DB \
  --set-string backend.database.username=$PG_USER \
  --set-string backend.database.password=$PG_PASS
```

ArgoCD-managed deploys should read the credentials from a sealed / external
secret rather than plaintext values. The Helm template `backend-db-secret.yaml`
still produces the Kubernetes Secret consumed by the backend Deployment — only
the *source* of the credentials changes.
