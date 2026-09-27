# module-service Helm chart (Aufgabe 6)

Deploys the Python `module_service` (FastAPI) + its Kubernetes wiring:

- Deployment, ClusterIP Service, PodDisruptionBudget
- Secret holding the MySQL SQLAlchemy URL (fed from `terraform output`)
- ServiceMonitor + PrometheusRule (label `release: monitoring`)
- Grafana dashboard (auto-loaded via sidecar)
- Complies with the Kyverno ClusterPolicies from `helm/policy/`
  (`runAsNonRoot`, explicit tag, resources + probes)

## Bootstrap

```sh
kubectl apply -f argocd/application-module-service-prod.yaml
```

## Feeding the DB credentials

```sh
cd ../../terraform
export TF_VAR_do_token='dop_v1_...'
terraform apply

helm upgrade --install module-service-prod ../helm/module-service \
  --namespace module-service-prod \
  --create-namespace \
  --set-string database.url=$(terraform output -raw mysql_sqlalchemy_url) \
  --set-string image.tag=$(git -C ../../module_service rev-parse --short HEAD | sed 's/^/sha-/')
```

For ArgoCD-managed deploys use external-secrets / sealed-secrets so the
Managed MySQL URL never lives in plaintext values.

## Talking to it from user_mgmt_service

The backend `user_mgmt_service` reaches the module_service via its cluster DNS:

```
http://module-service-prod.module-service-prod.svc.cluster.local:8080
```

Override with `MODULE_SERVICE_URL` env-var (see `helm/user-mgmt/values.yaml →
backend.config` — not yet exposed there; add it if you deploy staging).
