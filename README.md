# user-mgmt-ops

GitOps repository for the [user-mgmt-service](https://github.com/nick-sohl/user-mgmt-service) application.

## Layout

- `helm/user-mgmt/` — Helm chart deployed to the cluster.
- `argocd/application.yaml` — ArgoCD Application manifest that points the cluster at this repo.

## How it works

ArgoCD (running in the `argocd` namespace) watches this repo. Any change committed to `main` — bumping an image tag in `values.yaml`, editing a template, adding a resource — is picked up and reconciled into the `user-mgmt` namespace within ~3 minutes.
