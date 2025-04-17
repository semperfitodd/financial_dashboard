terraform {
  backend "s3" {
    bucket = "bsc.sandbox.terraform.state"
    key    = "cloud_financial_dashboard/terraform.tfstate"
    region = "us-east-2"

    use_lockfile = true
  }
}
