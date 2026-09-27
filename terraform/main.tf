# Existing DOKS cluster (imported via imports.tf).
#
# Body derived from `terraform plan -generate-config-out=generated.tf`, then
# cleaned:
#   - `id`, `created_at`, `updated_at`, `status`, `ipv4_address`, `endpoint`,
#     `kube_config` etc. are computed-only and removed.
#   - Repeated values (region, version, name, sizing) hoisted into variables.
#   - Provider-default fields (surge_upgrade = true) kept explicit so future
#     plans stay stable.
#
# Re-run `terraform plan -generate-config-out=generated.tmp.tf` after each
# major DOKS version to catch new attributes, diff against main.tf, and
# fold in as needed.

resource "digitalocean_kubernetes_cluster" "this" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version
  ha      = var.ha

  surge_upgrade = true
  auto_upgrade  = false

  tags = var.cluster_tags

  node_pool {
    name       = var.node_pool.name
    size       = var.node_pool.size
    node_count = var.node_pool.node_count
    auto_scale = var.node_pool.auto_scale
    min_nodes  = var.node_pool.auto_scale ? var.node_pool.min_nodes : null
    max_nodes  = var.node_pool.auto_scale ? var.node_pool.max_nodes : null
    tags       = var.node_pool.tags
    labels     = var.node_pool.labels
  }
}
