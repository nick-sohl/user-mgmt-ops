# user-mgmt-ops

GitOps repository for the [user-mgmt-service](https://github.com/nick-sohl/user-mgmt-service) application.

## Layout

- `helm/user-mgmt/` — Helm chart deployed to the cluster.
- `helm/monitoring/` — Umbrella chart wrapping `kube-prometheus-stack` plus custom Grafana dashboards for `user_mgmt_service` (Aufgabe 1 Observability).
- `helm/policy/` — Umbrella chart wrapping Kyverno plus the cluster-wide ClusterPolicies (Aufgabe 5 Policy as Code).
- `helm/module-service/` — Helm chart for the Python `module_service` including ServiceMonitor + Grafana dashboard (Aufgabe 6 Microservices).
- `k6/` — Kustomize-managed k6 load-test Job for the backend (Aufgabe 2 Chaos Testing).
- `terraform/` — Infrastructure-as-Code for the DigitalOcean cluster (imported existing DOKS + Managed PostgreSQL, Aufgabe 3 + 4).
- `argocd/application-*.yaml` — ArgoCD Application manifests, one per environment / add-on.

## How it works

ArgoCD (running in the `argocd` namespace) watches this repo. Any change committed to `main` — bumping an image tag in `values.yaml`, editing a template, adding a resource — is picked up and reconciled into the target namespace within ~3 minutes.

## Monitoring

The `monitoring` Application deploys kube-prometheus-stack (Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics) into the `monitoring` namespace. Prometheus discovers ServiceMonitors and PrometheusRules with the label `release: monitoring` — the `user-mgmt` chart tags its own ServiceMonitor / PrometheusRule accordingly via `backend.monitoring.additionalLabels`.

Custom dashboards live under `helm/monitoring/dashboards/*.json` and are shipped as ConfigMaps that the Grafana sidecar auto-loads.

Bootstrap:

```sh
kubectl apply -f argocd/application-monitoring.yaml
```
