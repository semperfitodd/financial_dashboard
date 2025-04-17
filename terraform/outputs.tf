output "s3_sec_bucket" {
  value = module.sec_insights_s3_bucket.s3_bucket_id
}

output "secret_jwt_token" {
  value = aws_secretsmanager_secret.lambda_auth.name
}