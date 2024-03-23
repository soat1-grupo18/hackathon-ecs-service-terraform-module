variable "app_name" {
  type = string
}

variable "app_docker_image" {
  type = string
}

variable "app_docker_port" {
  type = number
}

variable "app_health_check_path" {
  type = string
}

variable "app_task_role_policy" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}
