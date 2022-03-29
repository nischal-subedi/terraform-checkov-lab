# Database instance created from snapshot
# Assume it is a default PostgreSQL database.
resource "aws_db_instance" "service_database" {
    instance_class      = "db.m5.large"
    snapshot_identifier = "snapshot-1122334455667788"
    monitoring_interval = 5
    enabled_cloudwatch_logs_exports = ["general", "error", "slowquery"]
    multi_az            = true 
    db_subnet_group_name = aws_db_subnet_group.database.name
    
    vpc_security_group_ids = [
        aws_security_group.database.id
    ]
    
    # Additional optional configuration
    # ...
}

resource "aws_security_group" "database" {
    name        = "allow_db"
    description = "Allow database traffic"

    ingress {
        description = "Database traffic from webapp"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_db_subnet_group" "database" {
    subnet_ids = [data.aws_subnet.main.*.id]
}
