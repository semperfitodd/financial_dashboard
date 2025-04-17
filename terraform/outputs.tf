output "latest_image_tags" {
  value = {
    for repo_key in var.ecr_repos :
    repo_key => "${module.ecr[repo_key].repository_url}:${tolist(data.aws_ecr_image.latest[repo_key].image_tags)[0]}"
  }
}

output "s3_sec_bucket" {
  value = module.sec_insights_s3_bucket.s3_bucket_id
}

output "secret_jwt_token" {
  value = aws_secretsmanager_secret.lambda_auth.name
}