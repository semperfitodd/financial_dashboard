data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}

locals {
  node_group_name = join("-", [for word in split("-", local.environment) : substr(word, 0, 1)])
}

module "csi_irsa_role_ebs" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name             = "${var.environment}_ebs_csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "csi_irsa_role_s3" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name                       = "${var.environment}_s3_csi"
  attach_mountpoint_s3_csi_policy = true
  mountpoint_s3_csi_bucket_arns   = [module.sec_insights_s3_bucket.s3_bucket_arn]
  mountpoint_s3_csi_path_arns     = ["${module.sec_insights_s3_bucket.s3_bucket_arn}/*"]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:s3-sa"]
    }
  }
}

module "csi_irsa_role_secrets" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name                      = "${var.environment}_secrets_csi"
  attach_external_secrets_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["dashboard:secrets-sa"]
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.35.0"

  cluster_name = local.environment

  authentication_mode             = "API_AND_CONFIG_MAP"
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_ip_family = "ipv4"

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.csi_irsa_role_ebs.iam_role_arn
      most_recent              = true
    }
    aws-mountpoint-s3-csi-driver = {
      service_account_role_arn = module.csi_irsa_role_s3.iam_role_arn
      most_recent              = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  iam_role_additional_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  enable_cluster_creator_admin_permissions = true

  cluster_tags = var.tags

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    (local.node_group_name) = {
      ami_type       = "AL2_x86_64"
      instance_types = [var.eks_node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      use_latest_ami_release_version = true

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        gpu = false
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
        eks_s3                       = aws_iam_policy.eks_s3.arn
      }

      tags = var.tags
    }
  }
}

