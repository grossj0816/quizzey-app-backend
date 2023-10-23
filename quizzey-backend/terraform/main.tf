terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
# data "aws_vpc" "quizzey_vpc" {
#   filter {
#     name = "tag:Name"
#     values = ["Quizzey VPC"]
#   }
# }

# # querying lambda security groups in quizzey vpc
# data "aws_security_groups" "lambda_sg" {
#   filter {
#     name = "group-name"
#     values = ["quizzey_lambda_sg"]
#   }
# }

# # querying lambda subnets in quizzey vpc
# data "aws_subnets" "lambda_subnets" {
#   filter {
#     name = "vpc-id"
#     values = [data.aws_vpc.quizzey_vpc.id] 
#   }

#   filter {
#     name = "tag:Name"
#     values = local.subnets
#   }
# }
#  -------------------   End Networking  ---------------------------


resource "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_role_for_quizzey_lambdas"

  assume_role_policy = <<EOF
    {
        "Version":"2012-10-17",
        "Statement": [
            {
                "Action":"sts:AssumeRole",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
      EOF 
}


resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "iam_policy_for_quizzey_lambdas"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }
    ]    
}
    EOF
}



resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}


resource "aws_s3_object" "quizzey-object" {
  bucket    = "tu-api-lambda-deploys"
  key       = "quizzey_app/lambdas.zip"
  source    = "../lambdas/lambdas.zip"
}


# fetch all courses -----------------------------------------------------------------
resource "aws_lambda_permission" "courses_get_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.courses_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}


resource "aws_lambda_function" "courses_get_lambda" {
  depends_on       = [
                      aws_s3_object.quizzey-object, 
                      aws_iam_role_policy_attachment.attach_policy_to_role
                     ]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "fetch_all_courses"
  source_code_hash = join("", data.aws_s3_object.source_hash.*.body)
  role             = aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.courses_getter_handler"
  runtime          = "python3.10"

  # vpc_config {
  #   subnet_ids = data.aws_subnets.lambda_subnets.ids
  #   security_group_ids = data.aws_security_groups.lambda_sg.ids
  # }
}


# fetch course by id -----------------------------------------------------------------
resource "aws_lambda_permission" "ind_course_get_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ind_course_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}


resource "aws_lambda_function" "ind_course_get_lambda" {
  depends_on       = [
                      aws_s3_object.quizzey-object, 
                      aws_iam_role_policy_attachment.attach_policy_to_role
                     ]
  s3_bucket        = "tu-api-lambda-deploys"
  s3_key           = "quizzey_app/lambdas.zip"
  function_name    = "fetch_course"
  source_code_hash = join("", data.aws_s3_object.source_hash.*.body)
  role             = aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.course_getter_handler"
  runtime          = "python3.10"

  # vpc_config {
  #   subnet_ids = data.aws_subnets.lambda_subnets.ids
  #   security_group_ids = data.aws_security_groups.lambda_sg.ids
  # }
}

