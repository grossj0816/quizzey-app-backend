resource "aws_api_gateway_rest_api" "quizzey-api-gateway" {
  name        = "quizzey-api-gateway"
  description = "AWS Rest APIs for Quizzey Application"

  endpoint_configuration {
    types = ["REGIONAL"] #TODO: Create the VPC where this API Gateway will live 
  }
}





# setting all endpoint resources ------------------------------------------------------------
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




# modules for all method specific endpoints I want to create -------------------------------
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



# deployment and stage ----------------------------------------------------------------------
resource "aws_api_gateway_deployment" "quizzey-backend-deployment" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  depends_on = [
    module.get_courses,
    module.get_course
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