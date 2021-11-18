
module "lambda_dynamodb_streams" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "v2.4.0"
  source_path = "../../../source/compute_plane/python/lambda/dynamodb_streams_log"
  function_name =  "lambda_dynamodb_streams-${local.suffix}"
  handler = "dynamodb_streams_log.lambda_handler"
  memory_size = 1024
  timeout = 900
  create_role = false
  lambda_role = aws_iam_role.role_lambda_dynamodb_streams.arn
  
  cloudwatch_logs_kms_key_id = var.kms_key_arn
  cloudwatch_logs_retention_in_days = var.retention_in_days
  
  environment_variables = {
      CLUSTER_NAME=var.cluster_name
  }
   tags = {
    service     = "htc-aws"
  }
  runtime     = var.lambda_runtime
  build_in_docker = false
  docker_image = "${var.aws_htc_ecr}/lambda-build:build-${var.lambda_runtime}"
  depends_on = [aws_cloudwatch_log_group.lambda_dynamodb_streams]
}

resource "aws_cloudwatch_log_group" "lambda_dynamodb_streams" {
  name = "/aws/lambda/dynamodb_streams-${local.suffix}"
  retention_in_days = var.retention_in_days
  kms_key_id = var.kms_key_arn
}

resource "aws_iam_role" "role_lambda_dynamodb_streams" {
  name = "role_lambda_dynamodb_streams-${local.suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
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


resource "aws_lambda_event_source_mapping" "mapping_dynamodb_streams" {
  event_source_arn  = aws_dynamodb_table.htc_tasks_status_table.stream_arn
  function_name     = module.lambda_dynamodb_streams.lambda_function_arn
  starting_position = "LATEST"
}

resource "aws_iam_role_policy" "dynamodb_read_log_policy" {
  name   = "lambda-dynamodb-log-policy"
  role   = aws_iam_role.role_lambda_dynamodb_streams.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [ "logs:*" ],
        "Effect": "Allow",
        "Resource": [ "arn:aws:logs:*:*:*" ]
    },
    {
        "Action": [ "dynamodb:BatchGetItem",
                    "dynamodb:GetItem",
                    "dynamodb:GetRecords",
                    "dynamodb:Scan",
                    "dynamodb:Query",
                    "dynamodb:GetShardIterator",
                    "dynamodb:DescribeStream",
                    "dynamodb:ListStreams" ],
        "Effect": "Allow",
        "Resource": [
          "${aws_dynamodb_table.htc_tasks_status_table.arn}",
          "${aws_dynamodb_table.htc_tasks_status_table.arn}/*"
        ]
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "decrypt_object_lambda_dynamodb_streams" {
    statement {
      sid= "KMSAccess"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      effect = "Allow"
      resources = [var.kms_key_arn]
    }
}

resource "aws_iam_policy" "decrypt_object_lambda_dynamodb_streams" {
  name_prefix = "decrypt-lambda-dynamodb_streams"
  description = "Policy for alowing decryption of encrypted value"
  policy      = data.aws_iam_policy_document.decrypt_object_lambda_dynamodb_streams.json
}

resource "aws_iam_role_policy_attachment" "decrypt_object_lambda_dynamodb_streams" {
  role       = aws_iam_role.role_lambda_dynamodb_streams.name
  policy_arn = aws_iam_policy.decrypt_object_lambda_dynamodb_streams.arn
}