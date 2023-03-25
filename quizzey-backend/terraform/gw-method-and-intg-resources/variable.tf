variable "apigateway" {}

variable "resource" {}

variable "lambda_function" {}

variable "authorization" {
    default = "NONE"
}

variable "httpmethod" {
    default = "GET"
}