output "cluster_id" {
  description = "UUID of the DOKS cluster."
  value       = digitalocean_kubernetes_cluster.this.id
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = digitalocean_kubernetes_cluster.this.endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Applied Kubernetes version."
  value       = digitalocean_kubernetes_cluster.this.version
}

# --- Managed PostgreSQL (Aufgabe 4) -----------------------------------------

output "postgres_host" {
  description = "Private host of the Managed Postgres cluster."
  value       = digitalocean_database_cluster.postgres.private_host
}

output "postgres_port" {
  description = "Managed Postgres port."
  value       = digitalocean_database_cluster.postgres.port
}

output "postgres_database" {
  description = "Application database name."
  value       = digitalocean_database_db.user_mgmt.name
}

output "postgres_username" {
  description = "Application database user."
  value       = digitalocean_database_user.user_mgmt.name
}

output "postgres_password" {
  description = "Application database user password."
  value       = digitalocean_database_user.user_mgmt.password
  sensitive   = true
}

output "postgres_jdbc_url" {
  description = "Ready-to-use JDBC URL (SSL required by DO)."
  value = format(
    "jdbc:postgresql://%s:%d/%s?sslmode=require",
    digitalocean_database_cluster.postgres.private_host,
    digitalocean_database_cluster.postgres.port,
    digitalocean_database_db.user_mgmt.name,
  )
  sensitive = true
}

# --- Managed MySQL (Aufgabe 6) ----------------------------------------------

output "mysql_host" {
  description = "Private host of the Managed MySQL cluster."
  value       = digitalocean_database_cluster.mysql.private_host
}

output "mysql_port" {
  description = "Managed MySQL port."
  value       = digitalocean_database_cluster.mysql.port
}

output "mysql_database" {
  description = "module_service database name."
  value       = digitalocean_database_db.module_service.name
}

output "mysql_username" {
  description = "module_service database user."
  value       = digitalocean_database_user.module_service.name
}

output "mysql_password" {
  description = "module_service database user password."
  value       = digitalocean_database_user.module_service.password
  sensitive   = true
}

output "mysql_sqlalchemy_url" {
  description = "SQLAlchemy URL for the module_service (uses PyMySQL driver)."
  value = format(
    "mysql+pymysql://%s:%s@%s:%d/%s",
    digitalocean_database_user.module_service.name,
    digitalocean_database_user.module_service.password,
    digitalocean_database_cluster.mysql.private_host,
    digitalocean_database_cluster.mysql.port,
    digitalocean_database_db.module_service.name,
  )
  sensitive = true
}
