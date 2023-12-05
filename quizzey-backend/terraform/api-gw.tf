resource "aws_api_gateway_rest_api" "quizzey-api-gateway" {
  name        = "quizzey-api-gateway"
  description = "AWS Rest APIs for Quizzey Application"

  endpoint_configuration {
    types = ["REGIONAL"] #TODO: Create the VPC where this API Gateway will live 
  }
}





# setting all endpoint resources ------------------------------------------------------------
resource "aws_api_gateway_resource" "create_tables" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part   = "create_tables"
}

resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part   = "courses"
}

resource "aws_api_gateway_resource" "course" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{courseId}"
}

resource "aws_api_gateway_resource" "sets" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part   = "sets" 
}

resource "aws_api_gateway_resource" "sets_by_courseId" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_resource.sets.id
  path_part   = "{courseId}" 
}

resource "aws_api_gateway_resource" "questions" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part   = "questions" 
}

resource "aws_api_gateway_resource" "questions_by_set_id" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id   = aws_api_gateway_resource.questions.id
  path_part   = "{setId}" 
}

# modules for all method specific endpoints I want to create -------------------------------
module "create_tables" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.create_tables
  lambda_function = aws_lambda_function.create_tables_lambda
  authorization   = "NONE"
  httpmethod      = "GET"
}



module "get_courses" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.courses
  lambda_function = aws_lambda_function.courses_get_lambda
  authorization   = "NONE"
  httpmethod      = "GET"
}



module "get_course" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.course
  lambda_function = aws_lambda_function.ind_course_get_lambda
  authorization   = "NONE"
  httpmethod      = "GET"
}



module "create_course" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.courses
  lambda_function = aws_lambda_function.create_course_lambda
  authorization   = "NONE"
  httpmethod      = "POST"
}



module "update_course" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.courses
  lambda_function = aws_lambda_function.update_course_lambda
  authorization   = "NONE"
  httpmethod      = "PUT"
}



module "get_sets_by_cid" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.sets_by_courseId
  lambda_function = aws_lambda_function.get_sets_by_cid_lambda
  authorization   = "NONE"
  httpmethod      = "GET"
}



module "create_set" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.sets
  lambda_function = aws_lambda_function.create_set_lambda
  authorization   = "NONE"
  httpmethod      = "POST"
}



module "update_set" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.sets
  lambda_function = aws_lambda_function.update_set_lambda
  authorization   = "NONE"
  httpmethod      = "PUT"  
}



module "get_questions_by_sId" {
  source          = "./gw-method-and-intg-resources"
  apigateway      = aws_api_gateway_rest_api.quizzey-api-gateway
  resource        = aws_api_gateway_resource.questions_by_set_id
  lambda_function = aws_lambda_function.get_questions_by_sid_lambda
  authorization   = "NONE"
  httpmethod      = "GET" 
}
# deployment and stage ----------------------------------------------------------------------
resource "aws_api_gateway_deployment" "quizzey-backend-deployment" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  depends_on = [
    module.create_tables,
    module.get_courses,
    module.get_course,
    module.create_course,
    module.update_course,
    module.get_sets_by_cid,
    module.create_set,
    module.update_set,
    module.module.get_questions_by_sId
  ]
  lifecycle {
    # if changes are made in the deployment create new resources before deleting
    # existing resources
    create_before_destroy = true
  }
}

# an api gateway stage is a reference to an api gateway deployment. (Current snapshot of API Gateway after deployment)
resource "aws_api_gateway_stage" "name" {
  stage_name    = "r"
  rest_api_id   = aws_api_gateway_rest_api.quizzey-api-gateway.id
  deployment_id = aws_api_gateway_deployment.quizzey-backend-deployment.id
  depends_on    = [aws_api_gateway_rest_api.quizzey-api-gateway]
}