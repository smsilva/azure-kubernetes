# Provisioning Time Estimates

Measured on `examples/cluster_argocd_ingress_istio` (azurerm v5.2 / helm v3.2 /
AKS 1.35.7), full stack from scratch, 35 resources, region `eastus2`,
`install_app_of_apps_infra = false`. Helm release durations come from
Terraform's `Creation complete after`; parallel modules overlap, so the total
is **not** the sum of the rows.

| Step                                    | Duration      | Notes                                              |
| --------------------------------------- | ------------- | -------------------------------------------------- |
| Resource Group + VNet/subnets           | ~15s          | fast Azure control-plane ops                       |
| Managed identities + app registration   | ~10s          | 2 UAMIs, federated credentials come after the AKS  |
| AKS cluster (control plane + nodepool)  | 3m29s         | dominant cost; varies with region/load             |
| Role assignments (kubelet, DNS, RBAC)   | ~25s each     | created in parallel                                |
| cert-manager (v1.21.1, helm)            | 1m40s         | includes CRDs                                      |
| cert-manager-issuers (helm)             | 7s            |                                                    |
| external-secrets (ESO 2.9.0, helm)      | 1m37s         | + Workload Identity federated credential           |
| external-secrets-config (helm)          | 4s            | `ClusterSecretStore`                               |
| external-dns (0.21.0, helm)             | 39s           | + `external-dns-config` 6s                         |
| ingress-istio (helm, 1.30.3)            | 20s/28s/38s   | `istio-base` / `istio-discovery` / `istio-gateway` |
| httpbin (helm)                          | 2m30s         | waits for Gateway + cert readiness                 |
| argo-cd 10.4.0 / v3.5.1 (helm)          | 2m35s         | `atomic=true`, waits all 7 pods ready              |
| argo-cd-config (helm)                   | 3s            | idle on istio (azure/nginx subcharts disabled)     |
| **Full `terraform apply` (wall-clock)** | **~9min**     | AKS provisioning dominates; helm stage overlaps    |

> Measured 2026-08-22 on cluster `wasp-sandbox-9f5ed`. Enabling
> `install_app_of_apps_infra` adds one more helm release plus the ArgoCD sync
> time of the external GitOps repo.

## Following a provisioning run

```bash
watch -n 10 'scripts/follow-creation/follow xpt3'
```

`scripts/follow-creation/follow` waits on each stage in order (resource group,
AKS, namespaces, cluster issuers, external-secrets, ArgoCD pods, DNS,
certificate, HTTPS response). Each step has a bounded retry budget, so a stage
that never converges fails with a message instead of looping forever.
