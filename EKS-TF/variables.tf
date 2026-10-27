variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "three-tier-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "node_instance_type" {
  type    = string
  default = "m7i-flex.large"
}
