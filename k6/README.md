# k6 – load testing the user_mgmt_service

Self-contained k6 load test that runs as a Kubernetes Job inside the cluster
and generates ramp-up load against `user_mgmt_service`. Metrics land in
Prometheus via the ServiceMonitor deployed with `helm/user-mgmt/` and can be
observed live on the "User Management Service" Grafana dashboard.

## Layout

```
k6/
├── kustomization.yaml           # kustomize entry point (namespace + Job + ConfigMap)
├── manifests/
│   ├── namespace.yaml           # loadtest namespace
│   └── k6-job.yaml              # Job that runs grafana/k6:0.53.0
└── scripts/
    └── user-mgmt-load.js        # ramping-vus scenario, targets /users/register
```

## Run

```sh
# Point at the release you want to stress – prod is the default.
kubectl apply -k user-mgmt-ops/k6

# Follow the log
kubectl -n loadtest logs -f job/k6-user-mgmt-load
```

To target a different backend, edit `TARGET_BASE_URL` in `manifests/k6-job.yaml`
or set `--from-literal` in a kustomize patch. Example for staging:

```yaml
# k6/overlays/staging/kustomization.yaml
resources: [../../]
patches:
  - patch: |
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: http://user-mgmt-staging-user-mgmt-backend.user-mgmt-staging.svc.cluster.local:8080
    target: { kind: Job, name: k6-user-mgmt-load }
```

## What the test does

The script runs two scenarios in parallel:

| Scenario | Executor | Load | Purpose |
|----------|----------|------|---------|
| `health` | `constant-vus`  | 5 VUs, 10 min | baseline liveness signal |
| `register` | `ramping-vus` | 1 → 60 VUs over 10 min | drives CPU + DB writes to trigger the HPA |

Thresholds fail the run if the register-error-rate exceeds 10 % or p95 latency
exceeds 1.5 s – aligned with the PrometheusRule `UserMgmtHighErrorRate` /
`UserMgmtHighLatencyP95`.

## Observing HPA scaling

```sh
# In separate terminals, before / during the run:
kubectl -n user-mgmt-prod get hpa -w
kubectl -n user-mgmt-prod get pods -l app.kubernetes.io/component=backend -w
```

Expect the backend deployment to scale from `minReplicas: 2` up to
`maxReplicas: 4` while VUs are ≥30, then shrink back within `--horizontal-pod-autoscaler-downscale-stabilization` (~5 min default) after ramp-down.

## Verifying load balancing

Once at least two backend pods are Ready, the Service (`ClusterIP` with
`sessionAffinity: None`) fans requests out via kube-proxy's iptables rules.
Confirm the distribution:

```sh
kubectl -n user-mgmt-prod logs -l app.kubernetes.io/component=backend --tail=200 \
  | grep -oE 'RequestId=[^ ]+' | sort | uniq -c
```

Or inspect per-pod request rate in Grafana → "User Management Service" →
Request rate panel (grouped by `uri`) and split by `pod` from the Kubernetes /
Pods dashboard shipped with kube-prometheus-stack.

## Clean up

```sh
kubectl delete -k user-mgmt-ops/k6
```
