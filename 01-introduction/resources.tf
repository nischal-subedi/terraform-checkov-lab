#
# KMS Key
#
provider "aws" {
  region = "eu-west-1"
}

resource "aws_kms_key" "mykey" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

#
# Module for S3 bucket replication
#
module "s3_personal_data" {
  source = "../module-s3-replication"
  source_bucket = aws_s3_bucket.personal_data
}


#
# Bucket where we will store user details
#
resource "aws_s3_bucket" "personal_data" {
  bucket = "user-personal-data"
  acl    = "private"
  
  logging {
    target_bucket = data.aws_s3_bucket.audit_log_bucket.id
  }

  # CKV_AWS_21 and #CKV_AWS_52
  versioning {
    enabled    = true
    mfa_delete = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
        }
      }
    }
  tags = {
    Name        = "user-personal-data-store"
    Environment = "production"
    Owner       = "AwesomeSquad"
  }
  replication_configuration {
    role = module.s3_personal_data.role_replication
    rules {
      id     = "personal_data"
      status = "Enabled"

      destination {
        bucket        = module.s3_personal_data.role_replication
        storage_class = "STANDARD"
      }
    }
  }
}

#
# Block public ACLs
#
resource "aws_s3_bucket_public_access_block" "personal_data" {
  bucket = aws_s3_bucket.personal_data.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


#
# EC2 instance to process user details for marketing research
#
resource "aws_instance" "data_processor" {
  #checkov:skip=CKV2_AWS_17: Out of lab's scope
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = "t2.micro"
  ebs_optimized = true
  monitoring    = true
  # Permissions for EC2 instance to access the S3 bucket
  iam_instance_profile = aws_iam_instance_profile.data_processor.id
  
  root_block_device {
    # 10 GiB volume size
    volume_size = 10
    encrypted = true
  }
  
  metadata_options {
    # CKV_AWS_79
    http_tokens = "required"
  }

  tags = {
    Name        = "user-personal-data-processor"
    Environment = "production"
    Owner       = "AwesomeSquad"
  }
}

#
# EC2 IAM role config
#
resource "aws_iam_instance_profile" "data_processor" {
  name = "data-processor-profile"
  role = aws_iam_role.data_processor.name
}

resource "aws_iam_role" "data_processor" {
  name = "data-processor-role"
  path = "/"
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

resource "aws_iam_role_policy" "data_processor" {
  name   = "data-processor-role"
  role   = aws_iam_role.data_processor.id
  policy = data.aws_iam_policy_document.data_processor.json
}

#
# The EC2 role policy: 
#
data "aws_iam_policy_document" "data_processor" {
  
  # Entity can list the files in the bucket
  statement {
    sid = "AllowListBucketContents"
    actions = [
      "s3:ListBucket",
    ]

    resources = aws_s3_bucket.personal_data.arn
  }
    
  # Entity can read all files in the bucket and their config:
  # GetObjectAcl, GetObjectTagging, and so on. Simplified with wildcard
  statement {
    sid = "AllowAllObjectReads"
    
    # Allows all object read-only actions, s3:GetObject*
    actions = [
      "s3:GetObject*"
    ]

    resources = [
      "${aws_s3_bucket.personal_data.arn}/*"
    ]
  }
  
  # Entity can write new files to the bucket and set permissions and retention
  # No wildcard, to explicitly limit the allowed actions.
  statement {
    sid = "AllowLimitedObjectWrites"
    
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectRetention",
    ]

    resources = [
      "${aws_s3_bucket.personal_data.arn}/*"
    ]
  }

}
