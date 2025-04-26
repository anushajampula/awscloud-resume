terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# CloudFront Origin Access Control 

resource "aws_cloudfront_origin_access_control" "origin_access_control" {
  name                              = "CF-OAC"
  description                       = "OAC for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Cloudfront Distribution

resource "aws_cloudfront_distribution" "resume_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  aliases  = ["anusha-cloud-resume.com"]
 
  viewer_certificate {
    acm_certificate_arn             = "arn:aws:acm:us-east-1:864899867882:certificate/bc549fa3-3f4e-458b-9c4d-1022505b6344"
    ssl_support_method              = "sni-only"
    minimum_protocol_version        = "TLSv1.2_2021"
}

  origin {
    domain_name                     = "anusha-resume-bucket.s3.us-east-1.amazonaws.com"
    origin_id                       = "anusha-resume-bucket.s3.us-east-1.amazonaws.com"
    origin_access_control_id        = aws_cloudfront_origin_access_control.origin_access_control.id
  }

  default_cache_behavior {
    target_origin_id       = "anusha-resume-bucket.s3.us-east-1.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id           = "aa808013-c7b7-4a26-bcc1-a57015b4562b"
    origin_request_policy_id  = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "cloudfront-resume-distribution"
  }
  
  price_class = "PriceClass_100"
}
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.resume_distribution.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.resume_distribution.domain_name
}

# S3 Bucket 

resource "aws_s3_bucket" "resume" {
  bucket = "anusha-resume-bucket"  
}

# IAM Role

resource "aws_iam_role" "lambda_execution_role" {
 name = "VisitorCounter-role-sj5dnid4"
 path = "/service-role/"

 assume_role_policy = jsonencode(
     {
         Statement = [
             {
                 Action    = "sts:AssumeRole"
                 Effect    = "Allow"
                 Principal = {
                     Service = "lambda.amazonaws.com"
                 }
              },
        ]
        Version    = "2012-10-17"
    }
)
}

# Lambda

resource "aws_lambda_function" "visitor_counter" {
  filename         = "lambda_code.zip" 
  function_name    = "VisitorCounter"  
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = filebase64sha256("lambda_code.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visitor_counter.name
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  # logging will be handled by default in /aws/lambda/VisitorCounter log group
}

# iam role policy for apigateway invoke permissions

resource "aws_iam_role_policy_attachment" "lambda_apigateway_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

# iam role policy for dynamodb

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# iam role policy attachment to lambda role

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::864899867882:policy/service-role/AWSLambdaBasicExecutionRole-29e6e074-cdf9-44de-86c5-5a207e599336"
}

# DynamoDB Table

resource "aws_dynamodb_table" "visitor_counter" {
  name             = "visitorCount"
  tags             = {
       "Name"      = "visitorCounterTable"
}
   tags_all        = {
            "Name" = "visitorCounterTable"
}
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# API Gateway

resource "aws_apigatewayv2_api" "visitor_counter_api" {
  name          = "VisitorCounterAPI"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["Content-Type"]
    expose_headers = []
    max_age        = 3600
 }
}

# API Gatewayv2 stage

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_counter_api.id
  name        = "$default"
  auto_deploy = true
}

# API Gatewayv2 integration with lambda

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.visitor_counter_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:lambda:us-east-1:864899867882:function:VisitorCounter"
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# Route53

data "aws_route53_zone" "primary" {
  name         = "anusha-cloud-resume.com"
  private_zone = false
}

resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "anusha-cloud-resume.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.resume_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}