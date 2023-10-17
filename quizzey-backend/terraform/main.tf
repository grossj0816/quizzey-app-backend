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


#exposes lambda resources to manage how they will manage their zip files
provider "archive" {}



locals {

  type                       = "zip"
  source_dir                 = "../lambdas"
  output_path_course_lambdas = "../lambda-zips/courses.zip"
  # output_path_set_lambdas       = "../lambda-zips/sets.zip"
  # output_path_questions_lambdas = "../lambda-zips/questions.zip"
}




data "archive_file" "courses-zip" {
  type        = local.type
  source_dir  = local.source_dir
  output_path = local.output_path_course_lambdas
}


# data "archive_file" "sets-zip" {
#   type        = local.type
#   source_dir  = local.source_dir
#   output_path = local.output_path_set_lambdas
# }

# data "archive_file" "questions-zip" {
#   type        = local.type
#   source_dir  = local.source_dir
#   output_path = local.output_path_questions_lambdas
# }


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


# fetch all courses -----------------------------------------------------------------
resource "aws_lambda_permission" "courses_get_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.courses_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
}


resource "aws_lambda_function" "courses_get_lambda" {
  function_name    = "fetch_all_courses"
  filename         = data.archive_file.courses-zip.output_path
  source_code_hash = data.archive_file.courses-zip.output_base64sha256
  role             = aws_iam_role.iam_role_for_lambda.arn
  handler          = "courses.courses_getter_handler"
  runtime          = "python3.10"
  depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
}


# # update course ----------------------------------------------------------------------
# resource "aws_lambda_permission" "course_update_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.course_update_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "course_update_lambda" {
#   function_name    = "update_course"
#   filename         = data.archive_file.courses-zip.output_path
#   source_code_hash = data.archive_file.courses-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "courses.course_update_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # delete course ------------------------------------------------------------------------
# resource "aws_lambda_permission" "course_delete_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.course_delete_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "course_delete_lambda" {
#   function_name    = "delete_course"
#   filename         = data.archive_file.courses-zip.output_path
#   source_code_hash = data.archive_file.courses-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "courses.course_delete_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # get all sets by  courseId ----------------------------------------------------------
# resource "aws_lambda_permission" "sets_get_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.sets_get_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "sets_get_lambda" {
#   function_name    = "fetch_all_sets_by_courseId"
#   filename         = data.archive_file.sets-zip.output_path
#   source_code_hash = data.archive_file.sets-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "sets.sets_getter_by_courseId_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # get all recent sets ---------------------------------------------------------------
# resource "aws_lambda_permission" "recent_sets_get_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.recent_sets_get_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "recent_sets_get_lambda" {
#   function_name    = "fetch_all_recent_sets"
#   filename         = data.archive_file.sets-zip.output_path
#   source_code_hash = data.archive_file.sets-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "sets.recent_sets_getter_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # update set -------------------------------------------------------------------------
# resource "aws_lambda_permission" "set_update_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.set_update_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "set_update_lambda" {
#   function_name    = "update_set"
#   filename         = data.archive_file.sets-zip.output_path
#   source_code_hash = data.archive_file.sets-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "sets.set_update_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # delete set ----------------------------------------------------------------------
# resource "aws_lambda_permission" "set_delete_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.set_update_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "set_delete_lambda" {
#   function_name    = "delete_set"
#   filename         = data.archive_file.sets-zip.output_path
#   source_code_hash = data.archive_file.sets-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "sets.set_delete_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # get all questions by setId ------------------------------------------------------
# resource "aws_lambda_permission" "questions_get_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.questions_get_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "questions_get_lambda" {
#   function_name    = "fetch_questions_by_setId"
#   filename         = data.archive_file.questions-zip.output_path
#   source_code_hash = data.archive_file.questions-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "questions.questions_getter_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # update questions -------------------------------------------------------------------
# resource "aws_lambda_permission" "question_update_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.question_update_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "question_update_lambda" {
#   function_name    = "update_questions"
#   filename         = data.archive_file.questions-zip.output_path
#   source_code_hash = data.archive_file.questions-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "questions.question_update_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }



# # delete question -------------------------------------------------------------------
# resource "aws_lambda_permission" "question_delete_lambda_perm" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.question_delete_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.quizzey-api-gateway.execution_arn}/*/*"
# }


# resource "aws_lambda_function" "question_delete_lambda" {
#   function_name    = "delete_question"
#   filename         = data.archive_file.questions-zip.output_path
#   source_code_hash = data.archive_file.questions-zip.output_base64sha256
#   role             = aws_iam_role.iam_role_for_lambda.arn
#   handler          = "questions.question_delete_handler"
#   runtime          = "python3.10"
#   depends_on       = [aws_iam_role_policy_attachment.attach_policy_to_role]
# }