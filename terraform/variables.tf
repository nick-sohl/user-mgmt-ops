variable "do_token" {
  description = "DigitalOcean API token. Provide via TF_VAR_do_token or terraform.tfvars (excluded from git)."
  type        = string
  sensitive   = true
}

variable "cluster_id" {
  description = "UUID of the existing DOKS cluster, used by the import block."
  type        = string
}

variable "cluster_name" {
  description = "Name of the DOKS cluster."
  type        = string
  default     = "user-mgmt-cluster"
}

variable "region" {
  description = "DigitalOcean region slug (e.g. fra1, ams3)."
  type        = string
  default     = "fra1"
}

variable "kubernetes_version" {
  description = "Full DOKS version slug (e.g. 1.31.1-do.4). Use `doctl kubernetes options versions` to list available."
  type        = string
}

variable "node_pool" {
  description = "Default node pool sizing for the existing cluster."
  type = object({
    name       = string
    size       = string
    node_count = number
    auto_scale = bool
    min_nodes  = optional(number)
    max_nodes  = optional(number)
    tags       = optional(list(string), [])
    labels     = optional(map(string), {})
  })
  default = {
    name       = "default"
    size       = "s-2vcpu-4gb"
    node_count = 1
    auto_scale = false
  }
}

variable "cluster_tags" {
  description = "Tags applied to the cluster."
  type        = list(string)
  default     = ["user-mgmt", "teko"]
}

variable "ha" {
  description = "Whether the control plane runs in HA mode. Existing single-node cluster uses false."
  type        = bool
  default     = false
}

variable "mysql" {
  description = "DigitalOcean Managed MySQL settings for module_service (Aufgabe 6)."
  type = object({
    name       = string
    version    = string
    size       = string
    node_count = number
    database   = string
    username   = string
    maintenance = object({
      day  = string
      hour = string
    })
    allowed_ip_cidrs = optional(list(string), [])
  })
  default = {
    name       = "module-service-mysql"
    version    = "8.4"
    size       = "db-s-1vcpu-1gb"
    node_count = 1
    database   = "module_service"
    username   = "module_service_app"
    maintenance = {
      day  = "sunday"
      hour = "03:30:00"
    }
  }
}

variable "postgres" {
  description = "DigitalOcean Managed PostgreSQL settings (Aufgabe 4)."
  type = object({
    name       = string
    version    = string
    size       = string
    node_count = number
    database   = string
    username   = string
    maintenance = object({
      day  = string
      hour = string
    })
    allowed_ip_cidrs = optional(list(string), [])
  })
  default = {
    name       = "user-mgmt-postgres"
    version    = "16"
    size       = "db-s-1vcpu-1gb"
    node_count = 1
    database   = "user_mgmt"
    username   = "user_mgmt_app"
    maintenance = {
      day  = "sunday"
      hour = "03:00:00"
    }
  }
}
