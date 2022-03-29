resource "aws_s3_bucket" "static_content" {
  bucket = "static.webapp.com"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn 
        sse_algorithm     = "aws:kms"
        }
     }
  }
  replication_configuration {
    role =  module.s3_replication_bucket.role_replication
    rules {
      id     = "personal_data"
      status = "Enabled"

      destination {
        bucket        = module.s3_replication_bucket.destination_bucket
        storage_class = "STANDARD"
      }
    }
  }
}

#
# Modules for S3 bucket replication
#
module "s3_replication_bucket" {
  source = "../module-s3-replication"
  source_bucket = aws_s3_bucket.static_content
}

resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket = aws_s3_bucket.static_content.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

#
# KMS Key
#
resource "aws_kms_key" "mykey" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
  enable_key_rotation = true
}
