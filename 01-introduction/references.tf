# Reference to the latest Ubuntu 18.04 LTS AMI provided by Canonical
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# Reference to the bucket destination for audit logs
data "aws_s3_bucket" "audit_log_bucket" {
  bucket = "audit-logging-bucket"
}
