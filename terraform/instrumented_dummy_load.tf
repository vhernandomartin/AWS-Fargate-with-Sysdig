data "sysdig_fargate_workload_agent" "dummy_container" {
  container_definitions = jsonencode([
    {
      "name" : "Dummy_Write_to_bin_app",
      "image" : "sysdiglabs/writer-to-bin:latest",
      "command" : ["/usr/bin/demo-writer-c", "/usr/bin/oh-no-i-wrote-in-bin"],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.instrumented_logs.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "dummy-workload"
        },
      }
    }
  ])

  workload_agent_image = "quay.io/sysdig/workload-agent:latest"

  sysdig_access_key = var.access_key
  orchestrator_host = module.fargate-orchestrator-agent.orchestrator_host
  orchestrator_port = module.fargate-orchestrator-agent.orchestrator_port
}

resource "aws_ecs_task_definition" "dummy_workload_task_definition" {
  family             = "${var.prefix}-fargate-demo"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.execution_role.arn

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.sysdig_fargate_workload_agent.dummy_container.output_container_definitions
}

resource "aws_ecs_service" "dummy_service" {
  name = "${var.prefix}-dummy-workload-service"

  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.dummy_workload_task_definition.arn
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