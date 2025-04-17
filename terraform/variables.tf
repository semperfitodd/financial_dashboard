locals {
  environment = replace(var.environment, "_", "-")
}

resource "random_string" "this" {
  length = 4

  lower   = true
  numeric = true
  special = false
  upper   = false
}

variable "domain" {
  description = "Base domain for the website"
  type        = string

  default = null
}

variable "dynamo_tables" {
  description = "Map of all DynamoDB table configurations"

  type = map(object({
    attributes = list(object({
      name = string
      type = string
    }))
    hash_key  = string
    range_key = optional(string)
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = string
    })))
    stream_enabled   = optional(bool, false)
    stream_view_type = optional(string)
  }))

  default = {}
}

variable "ecr_repos" {
  description = "A list of ECR repository names. The first item in the list represents the repository for the dynamic website image (used for Docker image builds)."
  type        = map(string)

  default = {}
}

variable "eks_cluster_version" {
  description = "Version of kubernetes running on cluster"
  type        = string

  default = null
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string

  default = null
}

variable "environment" {
  description = "Environment name"
  type        = string

  default = null
}

variable "region" {
  description = "AWS region"
  type        = string

  default = null
}

variable "sec_zip_file_url" {
  description = "SEC filings zip url"
  type        = string

  default = null
}

variable "tags" {
  description = "Universal tags"
  type        = map(string)

  default = {}
}

variable "vpc_cidr" {
  description = "VPC cidr block"
  type        = string

  default = null
}

variable "vpc_redundancy" {
  description = "Redundancy for this VPCs NAT gateways"
  type        = bool

  default = false
}
