terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

# Creating Lambda IAM resource
resource "aws_iam_role" "lambda_iam" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }      
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apiGatewayLambda" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "apiGatewayLambda" {
  name = "/aws/lambda/${aws_lambda_function.apiGatewayLambda.function_name}"
  retention_in_days = 30
}

data "archive_file" "apiGatewayLambda" {
  type = "zip"

  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

# Creating Lambda resource
resource "aws_lambda_function" "apiGatewayLambda" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_iam.arn
  handler          = "${var.handler_name}.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout
  filename         = "src.zip"
  source_code_hash = data.archive_file.apiGatewayLambda.output_base64sha256
  environment {
    variables = {
      env            = var.environment
    }
  }
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = var.api_gateway_endpoint
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = var.api_gateway_endpoint
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "apiGatewayLambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.apiGatewayLambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "apiGatewayLambda" {
  api_id = aws_apigatewayv2_api.lambda.id  
  route_key = "GET /read"
  target    = "integrations/${aws_apigatewayv2_integration.apiGatewayLambda.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apiGatewayLambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}