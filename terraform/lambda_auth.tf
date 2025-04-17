resource "null_resource" "build_lambda_auth_deps" {
  triggers = {
    app_hash = filesha256("${path.module}/lambda_auth/app.py")
  }

  provisioner "local-exec" {
    command = "${path.module}/lambda_auth/build.sh"
  }
}

module "lambda_auth" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.2"

  function_name = "${var.environment}_auth"
  description   = "${replace(var.environment, "_", " ")} api authorizer function"
  handler       = "app.lambda_handler"
  publish       = true
  runtime       = "python3.13"
  timeout       = 30

  environment_variables = {
    USERS_TABLE_NAME = aws_dynamodb_table.this["users"].name
    JWT_SECRET_NAME  = aws_secretsmanager_secret.lambda_auth.name
    JWT_EXPIRATION   = 86400
  }

  source_path = [
    {
      path = "${path.module}/lambda_auth"
    },
    {
      path = "${path.module}/lambda_auth/python"
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:Query*",
        "dynamodb:GetItem*"
      ]
      resources = [
        aws_dynamodb_table.this["users"].arn,
        "${aws_dynamodb_table.this["users"].arn}/*"
      ]
    }
    secrets = {
      effect    = "Allow",
      actions   = ["secretsmanager:*"],
      resources = [aws_secretsmanager_secret.lambda_auth.arn]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 3

  tags = var.tags
}

resource "aws_secretsmanager_secret" "lambda_auth" {
  name        = "${local.environment}-lambda-auth-secret"
  description = "${local.environment} JWT secret"

  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "lambda_auth" {
  secret_id = aws_secretsmanager_secret.lambda_auth.id

  secret_string = jsonencode({ "jwt_secret" = random_string.jwt_secret.result })
}

resource "random_string" "jwt_secret" {
  length = 64
}