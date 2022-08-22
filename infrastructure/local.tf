locals {
  ecr_repo_uri   = "${var.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repository_name}"
  ecr_repo_arn   = "arn:aws:ecr:${var.region}:${var.registry_id}:repository/${var.repository_name}"
  ecr_image_name = "${local.ecr_repo_uri}:${var.image_tag}"
}
