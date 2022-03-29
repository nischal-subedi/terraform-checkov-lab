#
# KMS Key
#
resource "aws_kms_key" "mykey" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

variable source_bucket {
 
}


#
# Replication policy
#
resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-12345"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

#
# Public access block
#
resource "aws_s3_bucket_public_access_block" "destination" {
  bucket = aws_s3_bucket.destination.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

#
# Destination bucket for replication
#
resource "aws_s3_bucket" "destination" {
  #checkov:skip=CKV_AWS_144:Replication bucket does not require replication
  #checkov:skip=CKV_AWS_18
  
  bucket = "tf-test-bucket-destination-12345"

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn 
        sse_algorithm     = "aws:kms"
        }
     }
   }
}

resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-replication-12345"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.source_bucket}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.source_bucket}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

output "role_replication" {
  value = aws_iam_role.replication.arn
}

output "destination_bucket" {
  value = aws_s3_bucket.destination.arn
}
