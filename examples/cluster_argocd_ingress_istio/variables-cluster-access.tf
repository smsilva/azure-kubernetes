# Access to this cluster's ArgoCD is granted to two kinds of Azure AD group:
#
#   1. local.argocd_cluster_access_group_name — created by this example, one
#      per cluster, destroyed with it. Add individual users here.
#   2. local.argocd_extra_contributor_group_ids — pre-existing groups in the
#      directory. They are granted access by *reference* in the ArgoCD
#      policy.csv, never by being nested into the group above: nesting would
#      spend one slot of the 200-group JWT claim budget per cluster, and would
#      depend on transitive claim expansion. See the design spec.
#
# Both land in role:app-contributor + role:readonly. Changing the list below
# requires a terraform apply, which is intended — access is granted through a
# reviewed pull request.

locals {
  argocd_cluster_access_group_name = "aks-cluster-users-${local.cluster_random_id}"

  argocd_extra_contributor_group_ids = []
}
