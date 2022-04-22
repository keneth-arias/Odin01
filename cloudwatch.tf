resource "aws_iam_role" "api_gw_cloudwatch" {
  name = "api_gateway_cloudwatch_logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api_gw_cloudwatch" {
  name = "api_gw_cloudwatch_policy"
  role = aws_iam_role.api_gw_cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "api_gw_group" {
  name              = "api_gw_group"
  retention_in_days = 120
}

resource "aws_cloudwatch_log_stream" "api_gw_log_stream" {
  name           = "api_gw_log_stream"
  log_group_name = aws_cloudwatch_log_group.api_gw_group.name
}