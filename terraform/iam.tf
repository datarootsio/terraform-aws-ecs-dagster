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
}

resource "aws_iam_role" "task" {
  name               = "${var.resource_prefix}-dagster-task-role-${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

