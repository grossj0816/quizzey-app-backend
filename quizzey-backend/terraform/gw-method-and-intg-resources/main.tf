# provides a http method for an api gateway resource
resource "aws_api_gateway_method" "method" {
  authorization = var.authorization
  http_method   = var.httpmethod
  resource_id   = var.resource.id
  rest_api_id   = var.apigateway.id 
}

resource "aws_api_gateway_method_response" "response" {
  depends_on    = [aws_api_gateway_method.method]
  rest_api_id   = var.apigateway.id
  resource_id   = var.resource.id
  http_method   = var.httpmethod
  status_code  =  200
  #response parameters is essentially a list of response headers that can be read from backend response
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true,

  }
  response_models = {
    "application/json" = "Empty"
  }
}

# Creates the integration between the lambda event that will trigger when this is called.
resource "aws_api_gateway_integration" "integration" {
 rest_api_id             = var.apigateway.id 
 resource_id             = var.resource.id
 http_method             = var.httpmethod
 integration_http_method = "POST" 
#The type set means that we are integrating with a lambda
 type                    = "AWS_PROXY"
 uri                     = var.lambda_function.invoke_arn  
 content_handling        = "CONVERT_TO_TEXT" 
}

resource "aws_api_gateway_integration_response" "intgresponse" {
  depends_on             = [aws_api_gateway_integration.integration]
  rest_api_id            = var.apigateway.id 
  resource_id            = var.resource.id
  http_method            = var.httpmethod
  status_code            = aws_api_gateway_method_response.response.status_code
  content_handling       = "CONVERT_TO_TEXT" 
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}


