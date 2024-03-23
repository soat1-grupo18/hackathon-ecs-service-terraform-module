
data "aws_iam_policy_document" "ecs_task_execution_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = format("%s-task-execution-role", var.app_name)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_trust.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task_role" {
  name               = format("%s-task-role", var.app_name)
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_trust.json
  inline_policy {
    name   = "inline_policy"
    policy = var.app_task_role_policy
  }
}

data "aws_iam_policy_document" "ecs_task_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}
