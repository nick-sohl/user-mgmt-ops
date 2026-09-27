# Kyverno – Policy as Code (Aufgabe 5)

Installs Kyverno into namespace `policy` and ships four cluster-wide
`ClusterPolicy` resources that enforce sensible defaults across every
workload namespace.

## Chart layout

```
helm/policy/
├── Chart.yaml                             # depends on kyverno 3.3.5
├── values.yaml                            # kyverno controller sizing + resource filters
├── templates/
│   ├── require-resource-limits.yaml       # CPU/memory requests + limits are mandatory
│   ├── disallow-latest-tag.yaml           # image must have an explicit, non-latest tag
│   ├── require-run-as-non-root.yaml       # containers may not run as root
│   └── require-probes.yaml                # readiness + liveness probes are mandatory
├── samples/
│   └── bad-deployment.yaml                # intentionally violates every rule above
└── README.md
```

Policies exclude the system + platform namespaces (`kube-system`, `kube-public`,
`kube-node-lease`, `policy`, `argocd`, `monitoring`, `loadtest`) so Kyverno,
ArgoCD and the observability stack cannot lock themselves out.

## Bootstrap

```sh
cd helm/policy && helm dependency build
kubectl apply -f ../../argocd/application-policy.yaml
```

## Verifying enforcement

```sh
# 1. Confirm the policies are Ready.
kubectl get clusterpolicy

# 2. Apply the intentionally-bad Deployment. Expect a rejection.
kubectl apply -f helm/policy/samples/bad-deployment.yaml -n default
# error: admission webhook "validate.kyverno.svc-fail" denied the request:
#   resource Deployment/default/kyverno-demo-bad was blocked due to the following policies:
#     disallow-latest-tag
#     require-resource-limits
#     require-probes
#     require-run-as-non-root

# 3. Inspect background-scan reports for existing workloads.
kubectl get policyreport,clusterpolicyreport -A
```

## Rolling out a new policy

1. Add a new file under `templates/`.
2. Commit → push. ArgoCD syncs it into the `policy` namespace.
3. Watch existing workloads via `PolicyReport` to see what would fail *before*
   flipping the action to `Enforce`. Ship policies as `Audit` first, then
   promote once the reports are clean.
