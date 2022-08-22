variable "registry_id" {
  type        = string
  description = "ECR Registry ID"
}

variable "repository_name" {
  type        = string
  description = "ECR Repository name"
}

variable "image_tag" {
  type        = string
  description = "ECR Docker image tag"
  default     = "latest"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ec2_ami" {
  type        = string
  default     = "ami-0729e439b6769d6ab"
  description = "AMI for EC2 instance"
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}
