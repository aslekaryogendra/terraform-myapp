provider "aws" {
    region = "us-east-1"
}

# ========== State File Versioning ==========

#Create S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  #bucket = "terraform-up-and-running-state"
  bucket = var.mybkt
}

# Configuring ACL for S3
resource "aws_s3_bucket_acl" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}

# Configuring S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "s3-bucket-myapp" {
  bucket = var.mybkt
  versioning_configuration {
    status = "Enabled"
  }
}

# dynamodb table for versioning of state file
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "myapp-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# configuring backend to s3
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "mybucket07022022"
    key            = "myapp/terraform.tfstate"
    region         = "us-east-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "myapp-locks"
    encrypt        = true
  }
}

# vpc configuration
resource "aws_vpc" "mydefvpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "MyApp VPC"
  }
}

# Creating Internet Gateway 
resource "aws_internet_gateway" "igw-myapp" {
  vpc_id = aws_vpc.mydefvpc.id
}

# security-group configuration
resource "aws_security_group" "sg-myapp" {
    name = "basicsg"
    vpc_id = aws_vpc.mydefvpc.id   #attribute refernce

    ingress {
        from_port = 80  #argument refernce
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags = {
    "Name" = "basicsg"
  }

}

# Creating Subnet
resource "aws_subnet" "subnet-myapp" {
  vpc_id                  = aws_vpc.mydefvpc.id
  cidr_block             = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = aws.region
  tags = {
      Name = "Web Subnet 1"
    }
}

# Creating Route Table
resource "aws_route_table" "route" {
    vpc_id = aws_vpc.mydefvpc.id
    route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.igw-myapp.id
        }
    tags = {
            Name = "Route to internet"
        }
}

# Associating Route Table
resource "aws_route_table_association" "rt1" {
    subnet_id = aws_subnet.subnet-myapp.id
    route_table_id = aws_route_table.route.id
}


# Ec2 instance configuration
resource "aws_instance" "myinstance" {
    ami = data.aws_ami.aws_linux_2_latest.id
    key_name = "awsPracticeKey"
    #mkey= aws_key_pair.key_name
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.sg-myapp.id]
    subnet_id = tolist(data.aws_subnet_ids.default_subnets.ids)[0] 
    
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        #private_key = file(var.aws_key_pair) #file("C:/Users/Hp/Downloads/awsPracticeKey.pem")
        private_key = file(var.aws_key_pair)
    }

    # provisioner "remote-exec" {
    #     inline = [
    #         "sudo yum install httpd -y",
    #         "sudo service httpd start",
    #         "echo hi this is Sample Page type '/11' after url |sudo tee /var/www/html/index.html"
    #     ]      
    # }
    user_data = file("userData.sh")
 
    tags = {
      "Name" = "Terraform Instance_${timestamp()}"
    }
}

# loadbalancer configuration

resource "aws_lb" "external-alb" {
  name               = "External LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-myapp.id]
  subnets            = [aws_vpc.mydefvpc.id]
}

# loadbalancer target group attachment
resource "aws_lb_target_group_attachment" "lb-myapp" {
  target_group_arn = aws_lb_target_group.lb-myapp.arn
  target_id        = aws_instance.myinstance.id
  port             = 80
}

# loadbalancer target group 
resource "aws_lb_target_group" "lb-myapp" {
  # ... other configuration ...
  health_check {
    interval = 10
    path ="/"
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  name = "MyApp ALB"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.mydefvpc.id
}

#
resource "aws_lb_listener" "lb-listener-myapp" {
  loadload_balancer_arn = aws_lb.external-alb.arn
  port = 80
  protocol= "HTTP"
  default_default_action {
    target_group_arn=aws_lb_target_group.arn
    type= "forward"
  }  
}

# resource "aws_instance" "lb-myapp" {
#   # ... other configuration ...
# }

