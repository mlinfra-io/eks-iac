variable "deletion_window_in_days" {
  type    = string
  default = 7
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "k8s_version" {
  type        = string
  description = "EKS Cluster version"
  default     = "1.34"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for EKS Cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets IDs for EKS Cluster"
}

variable "cluster_ip_family" {
  type        = string
  description = "Configures the IP family used by the EKS cluster"
  default     = "ipv4"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether the Amazon EKS private API server endpoint is enabled. Default is true. Read more here: https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html"
  default     = true
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether the Amazon EKS public API server endpoint is enabled. Default is true; contrary to the default value set in the module: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs"
  default     = true
}

variable "vpc_cni_addon" {
  type = object({
    before_compute              = bool
    most_recent                 = bool
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
  })
  default = {
    before_compute              = true
    most_recent                 = true
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"
  }
}

variable "vpc_cni_addon_configuration_values" {
  type        = map(any)
  description = "Configuration for VPC CNI AddOn"
  default = {
    env = {
      # if your VPC has a lot of consecutive continuous IPs
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
      # if your vpc is quite fragmented
      # WARM_IP_TARGET = "7"
      # MINIMUM_IP_TARGET = "15"
    }
  }
}

variable "coredns_addon" {
  type = object({
    most_recent                 = bool
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
  })
  default = {
    most_recent                 = true
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"
  }
}

# variable "ebs_csi_driver_addon" {
#   type = object({
#     most_recent                 = bool
#     resolve_conflicts_on_create = string
#     resolve_conflicts_on_update = string
#   })
#   default = {
#     most_recent                 = true
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"
#   }
# }

# variable "ebs_csi_driver_addon_configuration_values" {
#   type        = map(any)
#   description = "Configuration for EBS CSI Driver AddOn"
#   default = {
#     controller = {
#       affinity = {
#         nodeAffinity = {
#           requiredDuringSchedulingIgnoredDuringExecution = {
#             nodeSelectorTerms = [{
#               matchExpressions = [{
#                 key      = "nodegroup_type"
#                 operator = "In"
#                 values   = ["operations"]
#               }]
#             }]
#           }
#         }
#       }
#       tolerations = [{
#         key      = "nodegroup_type"
#         operator = "Equal"
#         value    = "operations"
#         effect   = "NoSchedule"
#       }]
#     }
#   }
# }

# variable "ebs_csi_driver_irsa_role_name_prefix" {
#   type        = string
#   description = "Name prefix for the IAM role that provides permissions for the Amazon EKS node group to call AWS APIs on your behalf."
#   default     = "ebs-csi-irsa"
# }

variable "cluster_security_group_additional_rules" {
  type = map(object({
    description                = string
    protocol                   = string
    from_port                  = number
    to_port                    = number
    type                       = string
    source_node_security_group = bool
  }))
  default = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To ports 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
}

variable "node_security_group_additional_rules" {
  type = map(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    type             = string
    self             = optional(bool)
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
  }))
  default = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the EKS cluster and related modules."
  default     = {}
}
