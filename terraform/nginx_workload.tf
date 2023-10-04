terraform {
  required_providers {
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = ">= 0.5.39"
    }
  }
}

provider "sysdig" {
  sysdig_secure_api_token = var.secure_api_token
}

data "sysdig_fargate_workload_agent" "containers_instrumented" {
  container_definitions = jsonencode([
    {
      "name" : "nginx",
      "image" : "nginx",
      "linuxParameters": {
        "initProcessEnabled": true
      },
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.instrumented_logs.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "nginx"
        },
      }
    }
  ])

  workload_agent_image = "quay.io/sysdig/workload-agent:latest"

  sysdig_access_key = var.access_key
  orchestrator_host = module.fargate-orchestrator-agent.orchestrator_host
  orchestrator_port = module.fargate-orchestrator-agent.orchestrator_port
}

resource "aws_ecs_task_definition" "task_definition" {
  family             = "${var.prefix}-fargate-demo"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.execution_role.arn

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.sysdig_fargate_workload_agent.containers_instrumented.output_container_definitions
}

resource "aws_cloudwatch_log_group" "instrumented_logs" {
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-nginx-demo"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "execution_role" {
  name = "${var.prefix}-nginx-demo-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_iam_role" "task_role" {
  name = "${var.prefix}-nginx-demo-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "root"
    policy = data.aws_iam_policy_document.task_policy.json
  }
}

resource "aws_ecs_service" "service" {
  name = "${var.prefix}-nginx-demo-service"

  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task_definition.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    security_groups  = [aws_security_group.security_group.id]
    assign_public_ip = true
  }
}

