data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.dagster.arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:s3:::*"
    ]

    actions = ["s3:ListBucket", "s3:ListAllMyBuckets"]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.dagster_config_bucket}", "arn:aws:s3:::${var.dagster_config_bucket}/*"]
    actions   = ["s3:ListBucket", "s3:GetObject"]
  }

}

data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

# role for ecs to create the instance
resource "aws_iam_role" "execution" {
  name               = "${var.resource_prefix}-dagster-task-execution-role-${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  tags = var.tags
}

# role for the dagster instance itself
resource "aws_iam_role" "task" {
  name               = "${var.resource_prefix}-dagster-task-role-${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "${var.resource_prefix}-dagster-task-execution-${var.resource_suffix}"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.resource_prefix}-dagster-log-permissions-${var.resource_suffix}"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}