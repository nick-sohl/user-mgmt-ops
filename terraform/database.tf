# DigitalOcean Managed PostgreSQL (Aufgabe 4).
#
# Replaces the in-cluster StatefulSet. Terraform owns the cluster, database
# and service user; connection details are surfaced via outputs and materialised
# as a Kubernetes Secret out-of-band (see terraform/README.md → "Feeding the
# Helm chart").

resource "digitalocean_database_cluster" "postgres" {
  name       = var.postgres.name
  engine     = "pg"
  version    = var.postgres.version
  size       = var.postgres.size
  region     = var.region
  node_count = var.postgres.node_count

  tags = concat(var.cluster_tags, ["postgres"])

  maintenance_window {
    day  = var.postgres.maintenance.day
    hour = var.postgres.maintenance.hour
  }
}

resource "digitalocean_database_db" "user_mgmt" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.postgres.database
}

resource "digitalocean_database_user" "user_mgmt" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.postgres.username
}

# Restrict inbound traffic to the K8s cluster + optional operator CIDRs.
resource "digitalocean_database_firewall" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.this.id
  }

  dynamic "rule" {
    for_each = var.postgres.allowed_ip_cidrs
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}

# -----------------------------------------------------------------------------
# DigitalOcean Managed MySQL for module_service (Aufgabe 6).
# -----------------------------------------------------------------------------

resource "digitalocean_database_cluster" "mysql" {
  name       = var.mysql.name
  engine     = "mysql"
  version    = var.mysql.version
  size       = var.mysql.size
  region     = var.region
  node_count = var.mysql.node_count

  tags = concat(var.cluster_tags, ["mysql", "module-service"])

  maintenance_window {
    day  = var.mysql.maintenance.day
    hour = var.mysql.maintenance.hour
  }
}

resource "digitalocean_database_db" "module_service" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = var.mysql.database
}

resource "digitalocean_database_user" "module_service" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = var.mysql.username
}

resource "digitalocean_database_firewall" "mysql" {
  cluster_id = digitalocean_database_cluster.mysql.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.this.id
  }

  dynamic "rule" {
    for_each = var.mysql.allowed_ip_cidrs
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}
