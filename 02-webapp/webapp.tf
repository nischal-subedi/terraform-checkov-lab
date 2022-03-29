resource "aws_autoscaling_group" "webapp" {
    name_prefix = "webapp-asg-"
    
    min_size = "1"
    max_size = "3"

    launch_configuration = aws_launch_configuration.webapp.name
    target_group_arns    = [aws_lb_target_group.webapp.arn]
    tag {
        key = "name"
        value = "autoscaling_group"
        propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "webapp" {
    name_prefix   = "webapp-"
    image_id      = data.aws_ami.ubuntu.id
    instance_type = "m5.large"
    
    security_groups = [
        aws_security_group.webapp.id
    ]

    root_block_device {
        volume_type = "gp2"
        volume_size = 16
    }
    
    # Rolling zero-downtime deployment
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "webapp" {
    name        = "webapp-lb"
    description = "Allow web app traffic"

    ingress {
        description = "Web app traffic from load balancer"
        from_port   = 443
        to_port     = 443
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
