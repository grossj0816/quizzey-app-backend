resource "aws_api_gateway_rest_api" "quizzey-api-gateway" {
  name = "quizzey-api-gateway"
  description =  "AWS Rest APIs for Quizzey Application"

  endpoint_configuration {
    types = ["REGIONAL"] #TODO: Create the VPC where this API Gateway will live 
  }
}





# setting all endpoint resources ------------------------------------------------------------
resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part = "courses"
}

resource "aws_api_gateway_resource" "sets" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part = "sets"
}


resource "aws_api_gateway_resource" "questions" {
  rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
  parent_id = aws_api_gateway_rest_api.quizzey-api-gateway.root_resource_id
  path_part = "questions"
}





# modules for all method specific endpoints I want to create -------------------------------
module "get_courses" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.courses
    lambda_function  = aws_lambda_function.courses_get_lambda
    authorization    = "NONE"
    httpmethod       = "GET"
}



module "update_course" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.courses
    lambda_function  = aws_lambda_function.course_update_lambda
    authorization    = "NONE"
    httpmethod       = "PUT"
}



module "delete_course" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.courses
    lambda_function  = aws_lambda_function.course_delete_lambda
    authorization    = "NONE"
    httpmethod       = "DELETE"
}



module "get_sets_by_courseID" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.sets
    lambda_function  = aws_lambda_function.sets_get_lambda
    authorization    = "NONE"
    httpmethod       = "GET"
}



module "get_recently_opened_sets" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.sets
    lambda_function  = aws_lambda_function.recent_sets_get_lambda
    authorization    = "NONE"
    httpmethod       = "GET"
}



module "update_set" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.sets
    lambda_function  = aws_lambda_function.course_update_lambda
    authorization    = "NONE"
    httpmethod       = "PUT"
}



module "delete_set" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.sets
    lambda_function  = aws_lambda_function.set_delete_lambda
    authorization    = "NONE"
    httpmethod       = "DELETE"
}



module "get_questions_by_setID" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.questions
    lambda_function  = aws_lambda_function.questions_get_lambda
    authorization    = "NONE"
    httpmethod       = "GET"
}



module "update_questions" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.questions
    lambda_function  = aws_lambda_function.questions_update_lambda
    authorization    = "NONE"
    httpmethod       = "PUT"
}



module "delete_question" {
    source           = "./gw-method-and-intg-resources"
    apigateway       = aws_api_gateway_rest_api.quizzey-api-gateway
    resource         = aws_api_gateway_resource.questions
    lambda_function  = aws_lambda_function.question_delete_lambda
    authorization    = "NONE"
    httpmethod       = "DELETE"
}





# deployment and stage ----------------------------------------------------------------------
resource "aws_api_gateway_deployment" "quizzey-backend-deployment" {
    rest_api_id = aws_api_gateway_rest_api.quizzey-api-gateway.id
    depends_on = [
        module.get_courses.integration,
        module.update_course.integration,
        module.delete_course.integration,
        module.get_sets_by_courseID.integration,
        module.get_recently_opened_sets.integration,
        module.update_set.integration,
        module.delete_set.integration,
        module.get_questions_by_setID.integration,
        module.update_questions.integration,
        module.delete_question.integration,
    ]
    lifecycle {
      # if changes are made in the deployment create new resources before deleting
      # existing resources
      create_before_destroy = true
    }
}

# an api gateway stage is a reference to an api gateway deployment. (Current snapshot of API Gateway after deployment)
resource "aws_api_gateway_stage" "name" {
  stage_name = "r"
  rest_api_id = aws_api_gateway_deployment.quizzey-backend-deployment.id
  deployment_id = aws_api_gateway_deployment.quizzey-backend-deployment.id
  depends_on = [aws_api_gateway_rest_api.quizzey-api-gateway]
}