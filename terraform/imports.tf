# Terraform import blocks bring the existing DigitalOcean Kubernetes cluster
# under state management without recreating it. Regenerate the actual
# resource body with:
#
#   terraform plan -generate-config-out=generated.tf
#
# then merge / clean the emitted `generated.tf` into `main.tf`.

import {
  to = digitalocean_kubernetes_cluster.this
  id = var.cluster_id
}
