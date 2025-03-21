terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}

# S3 Bucket

resource "aws_s3_bucket" "resume" {
  bucket = "anusha-resume-bucket"
}
# CloudFront

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin Access Identity for CloudFront"
  lifecycle {
    ignore_changes = [comment]
  }
}

resource "aws_cloudfront_distribution" "resume_distribution" {
  origin {
    domain_name = "anusha-resume-bucket.s3.us-east-1.amazonaws.com"
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  lifecycle {
    ignore_changes = [price_class, default_cache_behavior, origin]
  }
}
# IAM Role

resource "aws_iam_role" "lambda_execution_role" {
 name = "VisitorCounter-role-sj5dnid4"
 path = "/service-role/"
lifecycle{
  ignore_changes = [assume_role_policy, tags]
}

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
 function_name = "arn:aws:lambda:us-east-1:864899867882:function:VisitorCounter"
lifecycle {
 ignore_changes = [source_code_hash, filename, role, id, tags, environment]
}

 role          = aws_iam_role.lambda_execution_role.arn
 handler       = "lambda_function.lambda_handler"
 runtime       = "python3.13"
 filename      = "lambda_code.zip"
 source_code_hash = filebase64sha256("lambda_code.zip")
 environment {
  variables = {
   DYNAMODB_TABLE = aws_dynamodb_table.visitor_counter.name
  }
 }
}
# DynamoDB Table

resource "aws_dynamodb_table" "visitor_counter" {
lifecycle {
 ignore_changes = [tags]
}
  name           = "visitorCount"  # Match the actual table name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "visitorCounterTable"
  }
}
# API Gateway

resource "aws_apigatewayv2_api" "visitor_counter_api" {
lifecycle {
 ignore_changes = [tags]
}
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
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_counter_api.id
  name        = "$default"
  auto_deploy = true
}