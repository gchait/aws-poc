resource "aws_iam_role" "lambda_exec_role" {
    name = "lambda_exec"
    path = "/"
    description = "Allows Lambda Functions to call AWS services on your behalf."

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "lambda_function" {
    role = aws_iam_role.lambda_exec_role.arn
    handler = "lambda.handler"
    runtime = "python3.8"
    filename = "lambda/lambda.zip"
    function_name = "time_func"
    source_code_hash = filebase64sha256("lambda/lambda.zip")
}

