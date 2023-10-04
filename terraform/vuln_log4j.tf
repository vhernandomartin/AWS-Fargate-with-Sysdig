data "sysdig_fargate_workload_agent" "vuln_log4j_container" {
  container_definitions = jsonencode([
    {
      "name" : "vuln_log4j",
      "image" : "bobcheat/log4j:2.0",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.instrumented_logs.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "vuln-log4j"
        },
      }
    }
  ])

  workload_agent_image = "quay.io/sysdig/workload-agent:latest"

  sysdig_access_key = var.access_key
  orchestrator_host = module.fargate-orchestrator-agent.orchestrator_host
  orchestrator_port = module.fargate-orchestrator-agent.orchestrator_port
}

resource "aws_ecs_task_definition" "vuln_log4j_task_definition" {
  family             = "${var.prefix}-fargate-demo"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.execution_role.arn

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.sysdig_fargate_workload_agent.vuln_log4j_container.output_container_definitions
}

resource "aws_ecs_service" "vuln_log4j_service" {
  name = "${var.prefix}-vuln-log4j-service"

  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.vuln_log4j_task_definition.arn
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