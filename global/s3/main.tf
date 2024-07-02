terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "terraform_user"
}


# AWS S3 Bucket 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "myterraform-bucket-state-kang-t"
  tags = {
    Name = "terraform_state"
  }
    lifecycle {
    #prevent_destroy = true
  }
  # S3와 같은 중요한 서비스는 실수로 삭제되지 않도록 Lifecycle을 정의한다.
  # 실제 삭제 작업을 진행하고 싶은 경우 주석처리를 진행한다.

  force_destroy = true
  # S3 bucket 강제삭제 가능 옵션 ( 데이터가 저장되어있는 Bucket은 삭제가 불가능 )
  # 강제 삭제 옵션을 활성화 할 경우 데이터가 존재하여도 삭제가 가능하다.
}

resource "aws_kms_key" "terraform_state_kms" {
  description             = "terraform_state_kms"
  deletion_window_in_days = 7
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sec" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_ver" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "myTerraform-bucket-lock-kang-t"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
