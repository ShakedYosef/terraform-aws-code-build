locals{
    splited_repository_list= split("/",var.source_repository)
    repository_name = local.splited_repository_list[1]
    branch_name = var.source_branch
}


resource "aws_codebuild_project" "codebuild" {
  name          = "codebuild-${var.env_name}-${local.repository_name}" 
  description   = "Build spec for ${local.repository_name}"
  build_timeout = "120"
  service_role  = aws_iam_role.codebuild_role.arn
  # source  {
  #   type = "NO_SOURCE"
  #   buildspec = "./files/buildspec.yml"
  # }
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

source {
    type = "CODEPIPELINE"
    buildspec = "files/buildspec.yml"
}



  # source {
  #   type            = "BITBUCKET"
  #   location        = "https://github.com/mitchellh/packer.git"
  #   git_clone_depth = 1

  #   git_submodules_config {
  #     fetch_submodules = false
  #   }
  #   filter {
  #     source = /infra
  #   }
  # }

  source_version = var.source_branch

    tags = tomap({
                Name="codebuild-${var.env_name}-${local.repository_name}",
                environment=var.env_name,
                created_by="terraform"
    })
}

resource "aws_iam_role" "codebuild_role" {
  name = "role-${local.repository_name}-${var.env_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}