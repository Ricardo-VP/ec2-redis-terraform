terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
}

#
# TLS Private Key
#

resource "tls_private_key" "secure_store_tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#
# Key Pair
#

resource "aws_key_pair" "secure_store_key_pair" {
  key_name   = "secure_store_ec2_key"
  public_key = tls_private_key.secure_store_tls_private_key.public_key_openssh
}

#
# IAM Role
#

resource "aws_iam_role" "secure_store_ec2_iam_role" {
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

#
# IAM Instance Profile
#

resource "aws_iam_instance_profile" "secure_store_ec2_profile" {
  role = aws_iam_role.secure_store_ec2_iam_role.name
}

#
# IAM Role Policy
#

resource "aws_iam_role_policy" "secure_store_ec2_role_policy" {
  name = "secure_store_iam_policy"
  role = aws_iam_role.secure_store_ec2_iam_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "GrantSingleImageReadOnlyAccess",
        "Effect" : "Allow",
        "Action" : [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImageReplicationStatus",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
        ],
        "Resource" : local.ecr_repo_arn
      },
      {
        "Sid" : "GrantECRAuthAccess",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetRegistryPolicy",
          "ecr:DescribeRegistry",
          "ecr:GetAuthorizationToken",
          "ecr:GetRegistryScanningConfiguration"
        ],
        "Resource" : "*"
    }]
  })
}

# 
# Security Group
#

resource "aws_security_group" "secure_store_ec2_sg" {
  name        = "secure-store-ec2-sg"
  description = "Secure store - Security group for ec2 instances"

  # Allowing SSH
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allowing redis port
  ingress {
    from_port   = "6379"
    to_port     = "6379"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# EC2 Instance
#

resource "aws_instance" "secure_store_ec2_instance" {
  # For non arm64 processors: ami-0729e439b6769d6ab
  ami = var.ec2_ami
  # For non arm64 processors: t2.micro
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.secure_store_ec2_profile.name
  key_name               = aws_key_pair.secure_store_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.secure_store_ec2_sg.id]

  user_data = <<EOF
${file("${path.module}/install.sh")}
aws ecr get-login-password \
  --region us-east-1 \
  | docker login \
  --username AWS \
  --password-stdin \
  ${local.ecr_repo_uri}
docker ps -aq | xargs docker stop | xargs docker rm
docker container prune -f
docker image prune -a -f
docker pull ${local.ecr_image_name}
docker run -p "6379:6379" -d ${local.ecr_image_name}
--//--
EOF
}

#
# Outputs
#

output "public_ip" {
  value = aws_instance.secure_store_ec2_instance.public_ip
}

output "private_pem" {
  value = nonsensitive(tls_private_key.secure_store_tls_private_key.private_key_pem)
}
