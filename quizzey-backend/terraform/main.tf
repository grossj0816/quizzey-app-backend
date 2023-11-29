terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "tc-terraform-state-storage-s3"
    key            = "app-quizzey-backend"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}


provider "aws" {
  region = "us-east-1"
}

locals {
  subnets = ["Lambda Subnet 1", "Lambda Subnet 2"]
}


#  -------------------   Begin Networking  ---------------------------
# querying quizzey vpc info
data "aws_vpc" "quizzey_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Quizzey VPC"]
  }
}

# querying lambda security groups in quizzey vpc
data "aws_security_groups" "lambda_sg" {
  filter {
    name   = "group-name"
    values = ["quizzey_lambda_sg"]
  }
}

# querying lambda subnets in quizzey vpc
data "aws_subnets" "lambda_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.quizzey_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = local.subnets
  }
}
#  -------------------   End Networking  ---------------------------

#  -------------------   Begin Pulling Secret  ---------------------------
data "aws_secretsmanager_secret" "db_secret" {
  name = "DB_SECRET"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}
#  -------------------   End Pulling Secret  ---------------------------

# IAM Role for Lambda -------------------------------------------------
data "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_role_for_quizzey_lambdas"
}



# S3 object storing lambda zip
resource "aws_s3_object" "quizzey-object" {
  bucket = "tu-api-lambda-deploys"
  key    = "quizzey_app/lambdas.zip"
  source = "../lambdas/lambdas.zip"
  etag   = filemd5("../lambdas/lambdas.zip")
}


# create tables -----------------------------------------------------------------
resource "aws_lambda_permission" "create_tables_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_tables_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "create_tables_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.create_tables_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "create_tables_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "create_quizzeydb_tables"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "tables.all_tables_create_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240
  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}




# fetch all courses -----------------------------------------------------------------
resource "aws_lambda_permission" "courses_get_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.courses_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "courses_get_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.courses_get_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "courses_get_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "fetch_all_courses"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.courses_getter_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240
  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}




# fetch course by id -----------------------------------------------------------------
resource "aws_lambda_permission" "ind_course_get_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ind_course_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "ind_course_get_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ind_course_get_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "ind_course_get_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "fetch_course"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.course_getter_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240

  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}




# insert course -----------------------------------------------------------------
resource "aws_lambda_permission" "create_course_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_course_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "create_course_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.create_course_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "create_course_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "create_course"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.create_new_course_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240

  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}




# update course -----------------------------------------------------------------
resource "aws_lambda_permission" "update_course_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_course_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "update_course_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.update_course_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "update_course_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "update_course"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.update_course_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240

  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}




# create set -----------------------------------------------------------------
resource "aws_lambda_permission" "create_set_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_set_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "create_set_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.create_set_lambda.function_name}"
  retention_in_days = 30
  skip_destroy      = false
}

resource "aws_lambda_function" "create_set_lambda" {
  depends_on       = [aws_s3_object.quizzey-object]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "create_set"
  source_code_hash = filebase64sha256("../lambdas/lambdas.zip")
  role             = data.aws_iam_role.iam_role_for_lambda.arn
  handler          = "sets.create_new_set_handler"
  runtime          = "python3.10"
  architectures    = ["arm64"]
  timeout          = 240

  vpc_config {
    subnet_ids         = data.aws_subnets.lambda_subnets.ids
    security_group_ids = data.aws_security_groups.lambda_sg.ids
  }

  environment {
    variables = {
      HOST          = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["host"]
      DATABASE_NAME = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["dbname"]
      USERNAME      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["password"]
    }
  }
}