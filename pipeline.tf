resource "aws_codebuild_project" "tf-plan" {
  name          = "tf-cicd-plan"
  description   = "Terraform Plan"
  service_role  = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential{
        credential = var.dockerhub_credentials
        credential_provider = "SECRETS_MANAGER"
    }
  }
  source{
    type = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildpsec.yml")
}

}


resource "aws_codebuild_project" "tf-apply" {
  name          = "tf-cicd-apply"
  description   = "Terraform apply"
  service_role  = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential{
        credential = var.dockerhub_credentials
        credential_provider = "SECRETS_MANAGER"
    }
  }
  source{
    type = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildpsec.yml")
}

}

resource "aws_codepipeline" "cicd-pipeline" {
    name = "tf-cicd"
    role_arn = aws_iam_role.tf-codepipeline-role.arn

    artifact_store {
      type = "S3"
      location = aws_s3_bucket.codepipeline_artifacts.id
    }

    stage {
      name = "Source"
      action {
        name = "Source"
        category = "Source"
        owner = "AWS"
        provider = "CodeStarSourceConnection"
        version = "1"
        output_artifacts = ["tf-code"]
        configuration = {
          FullRepositoryId = "elderz6/impacta-pipeline"
          BranchName = "main"
          ConnectionArn = var.codestar_connector_credentials
          OutputArtifactFormat = "CODE_ZIP"
        }
      }
    }

    stage {
      name = "Plan"
      action {
        name = "Build"
        category = "Build"
        owner = "AWS"
        provider = "CodeBuild"
        version = "1"
        input_artifacts = ["tf-code"]
        configuration = {
          ProjectName = "tf-cicd-plan"
        }
      }
    }

    stage {
      name = "Deploy"
      action {
        name = "Deploy"
        category = "Build"
        owner = "AWS"
        provider = "CodeBuild"
        version = "1"
        input_artifacts = ["tf-code"]
        configuration = {
          ProjectName = "tf-cicd-plan"
        }
      }
    }

}
