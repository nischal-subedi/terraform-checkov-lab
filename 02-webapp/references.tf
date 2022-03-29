data "aws_vpc" "main" {
  tags = {
    environment = "production"
  }
}

data "aws_subnet" "main" {
    vpc_id = data.aws_vpc.main.id
}


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


# TLS certificate for the web app
data "aws_acm_certificate" "webapp" {
  domain   = "webapp.example.com"
  statuses = ["ISSUED"]
}

# Reference to the bucket destination for audit logs. Use if necessary.
data "aws_s3_bucket" "audit_log_bucket" {
  bucket = "audit-logging-bucket"
}

