#################
# PROVIDER BLOCK #
##################

provider "aws" {
  access_key = var.aws_access_key          # Replace with your AWS access key ID (leave empty if using IAM roles or env vars)
  secret_key = var.aws_secret_key          # Replace with your AWS secret access key (leave empty if using IAM roles or env vars)
  region     = var.region # Specify the AWS region where resources will be created (e.g., us-east-1, us-west-2)
}

#################
# CUSTOM VPC #
##################

resource "aws_vpc" "customvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wl5vpc" 
  }
}

###########################
# VPC PEERING CONNECTION #
###########################
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = aws_vpc.customvpc.id
  vpc_id        = data.aws_vpc.default.id
  auto_accept   = true
}

########################
# UPDATING DEFAULT VPC #
########################

# Accessing default VPC
data "aws_vpc" "default" {
  default = true
}

# # Accessing the default route table of the default VPC - Don't need just gonna hard code in the one i see in aws
# data "aws_route_table" "default" {
#   vpc_id = data.aws_vpc.default.id
# }

# Add a route for VPC peering to the default route table
resource "aws_route" "vpc_peering_route" {
  route_table_id            = "rtb-0e3b29133d3e06d01"
  destination_cidr_block    = aws_vpc.customvpc.cidr_block  
  vpc_peering_connection_id  = aws_vpc_peering_connection.peer.id
}


####################
# Internet Gateway #
####################
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.customvpc.id

  tags = {
    Name = "Internet_Gateway"
  }
}

####################
# NAT Gateway 1 #
####################
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.elastic1.id
  subnet_id     = aws_subnet.pub_sub1.id ##FIX IT 

  tags = {
    Name = "NAT_Gateway1" 
  }
   # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ig]
}

####################
# Elastic IP 1 #
####################

resource "aws_eip" "elastic1" {
  domain   = "vpc"

  tags = {
    Name = "elastic1_ip"
  }
}

####################
# NAT Gateway 2 #
####################
resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.elastic2.id
  subnet_id     = aws_subnet.pub_sub2.id ##FIX IT 

  tags = {
    Name = "NAT_Gateway2" 
  }
   # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ig]
}

####################
# Elastic IP 2 #
####################

resource "aws_eip" "elastic2" {
  domain   = "vpc"

  tags = {
    Name = "elastic2_ip"
  }
}

##############################
# APPLICATION LOAD BALANCER # helps distribute incoming network traffic across multiple EC2 instances
##############################

resource "aws_lb" "app_lb" {
  # name               = "applb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.sg_for_lb.id] #Security group controlling inbound/outbound traffic for the ALB.
  subnets            = [aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id] #List of public subnets (one in each AZ) where the ALB should reside

  enable_deletion_protection = false
    tags = {
    Name = "App Load Balancer"
   }
}

################
# TARGET GROUP # defines the destination for the ALB’s traffic
################

resource "aws_lb_target_group" "mytg" {
  # name     = "my-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.customvpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    #matcher             = "200"  # Expect a 200 OK response
  }
   tags = {
    Name = "my-target-group"
  }

}

##############################
# TARGET GROUP ATTACHMENTS #
##############################

# Target Group Attachment for each EC2 instance
resource "aws_lb_target_group_attachment" "alb_tg_attachment-1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.frontend1.id  # Replace with your EC2 instance ID
  port             = 3000  # Matches the target group port
}

resource "aws_lb_target_group_attachment" "alb_tg_attachment-2" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.frontend2.id  # Replace with your EC2 instance ID
  port             = 3000  # Matches the target group port
}


#################
# ALB LISTENER # sets up the rules for how incoming traffic to the load balancer should be forwarded to the target group
#################

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mytg.arn
  }
}

##################################################
# SECURITY GROUP FOR APPLICATION LOAD BALANCER #
##################################################
resource "aws_security_group" "sg_for_lb" {
  # name   = "sg_app_balancer"
  vpc_id = aws_vpc.customvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_app_balancer"
  }
}

####################
# Public Subnet 1 #
####################
resource "aws_subnet" "pub_sub1" {
  vpc_id     = aws_vpc.customvpc.id
  cidr_block = "10.0.16.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub_sub1" 
  }
}
#############################
# Public Route Table - Main #
#############################
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.customvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
  
  tags = {
    Name = "pub_rt_main" 
  }
}

###############################################################
# Public Route Table - Main - Association to Public Subnet 1 #
###############################################################
resource "aws_route_table_association" "pub_rt_assc1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_rt.id


}

####################
# Public Subnet 2 #
####################
resource "aws_subnet" "pub_sub2" {
  vpc_id     = aws_vpc.customvpc.id
  cidr_block = "10.0.32.0/24" 
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub_sub2" 
  }
}

###############################################################
# Public Route Table - Main - Association to Public Subnet 2 #
###############################################################
resource "aws_route_table_association" "pub_rt_assc2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.pub_rt.id

}


####################
# Private Subnet 1 #
####################
resource "aws_subnet" "priv_sub1" {
  vpc_id     = aws_vpc.customvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "priv_sub1"
  }
}
#############################
# Private Route Table 1 #
#############################
resource "aws_route_table" "priv_rt1" {
  vpc_id = aws_vpc.customvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }

  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "priv_rt1" 
  }
}

#############################################################
# Private Route Table 1 Association to Private Subnet 1 #
#############################################################
resource "aws_route_table_association" "pri_rt_assc1" {
  subnet_id      = aws_subnet.priv_sub1.id
  route_table_id = aws_route_table.priv_rt1.id

}

####################
# Private Subnet 2 #
####################
resource "aws_subnet" "priv_sub2" {
  vpc_id     = aws_vpc.customvpc.id
  cidr_block = "10.0.0.0/24" 
  availability_zone = "us-east-1b"

  tags = {
    Name = "priv_sub2"
  }
}
#############################
# Private Route Table 2 #
#############################
resource "aws_route_table" "priv_rt2" {
  vpc_id = aws_vpc.customvpc.id

  route {
    cidr_block = "0.0.0.0/0" ## CHECK
    gateway_id = aws_nat_gateway.nat2.id
  }

  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "priv_rt2" 
  }
}

#############################################################
# Private Route Table 2 Association to Private Subnet 2 #
#############################################################
resource "aws_route_table_association" "pri_rt_assc2" {
  subnet_id      = aws_subnet.priv_sub2.id
  route_table_id = aws_route_table.priv_rt2.id

}

#################################
# KEY PAIR 1 FOR BACKEND EC2 #1 #
#################################

resource "tls_private_key" "backend_key1" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "backend_key1" {
  key_name   = "backend-key1"
  public_key = tls_private_key.backend_key1.public_key_openssh
}

output "backend_private_key1" {
  value     = tls_private_key.backend_key1.private_key_pem
  sensitive = false
}

#################################
# KEY PAIR 2 FOR BACKEND EC2 #2 #
#################################

resource "tls_private_key" "backend_key2" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "backend_key2" {
  key_name   = "backend-key2"
  public_key = tls_private_key.backend_key2.public_key_openssh
}

output "backend_private_key2" {
  value     = tls_private_key.backend_key2.private_key_pem
  sensitive = false
}


######################################
# SECURITY GROUP FOR BOTH FRONTEND EC2s #
######################################

resource "aws_security_group" "sg_front" { #name that terraform recognizes
  name        = "sg_frontend" #name that will show up on AWS
  description = "Port 22 for SSH and Port 3000 for Node.js"
 
  vpc_id = aws_vpc.customvpc.id
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allowing all traffic
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }

  # Tags for the security group
  tags = {
    "Name"      = "sg_frontend_main"                          # Name tag for the security group
    "Terraform" = "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

#################
# FRONTEND 1 EC2 #
##################
resource "aws_instance" "frontend1" {
  ami               = "ami-0866a3c8686eaeeba"          
                                        
  instance_type     = var.instance_type               

  subnet_id = aws_subnet.pub_sub1.id
 
  vpc_security_group_ids = [aws_security_group.sg_front.id]       
  key_name          = "AyannaCurwen932_446key"               

  user_data = "${file("frontend_setup.sh")}"

  tags = {
    "Name" = "ecommerce_frontend_az1"  
    "Terraform" = "true"       
  }

}

output "frontend_public_ip1" {
  value = aws_instance.frontend1.public_ip # Display the public IP address of the EC2 instance after creation.
}

output "frontend_private_ip1" {
  value = aws_instance.frontend1.private_ip # Display the public IP address of the EC2 instance after creation.
}

#################
# FRONTEND 2 EC2 #
##################
resource "aws_instance" "frontend2" {
  ami               = "ami-0866a3c8686eaeeba"          
                                        
  instance_type     = var.instance_type                

  subnet_id = aws_subnet.pub_sub2.id
 
  vpc_security_group_ids = [aws_security_group.sg_front.id]       
  key_name          = "AyannaCurwen932_446key"               

  user_data = "${file("frontend_setup.sh")}"

  tags = {
    "Name" = "ecommerce_frontend_az2" 
    "Terraform" = "true"        
  }
}

output "frontend_public_ip2" {
  value = aws_instance.frontend2.public_ip # Display the public IP address of the EC2 instance after creation.
}

output "frontend_private_ip2" {
  value = aws_instance.frontend2.private_ip # Display the public IP address of the EC2 instance after creation.
}


######################################
# SECURITY GROUP FOR BACKEND EC2 1 #
######################################

resource "aws_security_group" "sg_back1" { #name that terraform recognizes
  name        = "sg_backend1" #name that will show up on AWS
  description = "Port 22 for SSH, Port 8000 for Django and Port 9100 for Node Exporter"
 
  vpc_id = aws_vpc.customvpc.id
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # allowing IPs only from public subnet (RIGHT?)
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }

  # Tags for the security group
  tags = {
    "Name"      = "sg_backend1"                          # Name tag for the security group
    "Terraform" = "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

######################################
# SECURITY GROUP FOR BACKEND EC2 2 #
######################################

resource "aws_security_group" "sg_back2" { #name that terraform recognizes
  name        = "sg_backend2" #name that will show up on AWS
  description = "Port 22 for SSH, Port 8000 for Django and Port 9100 for Node Exporter"
 
  vpc_id = aws_vpc.customvpc.id
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # allowing IPs only from public subnet (RIGHT?)
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }

  # Tags for the security group
  tags = {
    "Name"      = "sg_backend2"                          # Name tag for the security group
    "Terraform" = "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

#################
# BACKEND 1 EC2 #
##################
resource "aws_instance" "backend1" {
  ami               = "ami-0866a3c8686eaeeba"          
                                        
  instance_type     = var.instance_type                

  subnet_id = aws_subnet.priv_sub1.id
 
  vpc_security_group_ids = [aws_security_group.sg_back1.id]       
  key_name          = "backend-key1"             

  user_data = "${file("backend_setup.sh")}"

  tags = {
    "Name" = "ecommerce_backend_az1"  
    "Terraform" = "true"       
  }

   depends_on = [aws_key_pair.backend_key1]  # Ensure key pair is created first
}

output "backend_private_ip1" {
  value = aws_instance.backend1.private_ip # Display the public IP address of the EC2 instance after creation.
}

#################
# BACKEND 2 EC2 #
##################
resource "aws_instance" "backend2" {
  ami               = "ami-0866a3c8686eaeeba"          
                                        
  instance_type     = var.instance_type                

  subnet_id = aws_subnet.priv_sub2.id
 
  vpc_security_group_ids = [aws_security_group.sg_back2.id]       
  key_name          = "backend-key2"               

  user_data = "${file("backend_setup.sh")}"

  tags = {
    "Name" = "ecommerce_backend_az2"  
    "Terraform" = "true"       
  }

}

output "backend_private_ip2" {
  value = aws_instance.backend2.private_ip # Display the public IP address of the EC2 instance after creation.
}

#################
# RDS DATABASE #
#################

resource "aws_db_instance" "postgres_db" {
  identifier           = "ecommerce-db"
  engine               = "postgres"
  engine_version       = "14.13"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "standard"
  db_name              = "W5Database"
  username             = "itsme2"
  password             = "lemondifficult3"
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subgroup.name
  vpc_security_group_ids = [aws_security_group.sg_for_rds.id]

  tags = {
    Name = "Ecommerce Postgres DB"
  }
}

#########################
# SUBNET GROUP FOR RDS # defines the subnets in which the RDS instance will reside.
#########################

resource "aws_db_subnet_group" "rds_subgroup" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.priv_sub1.id, aws_subnet.priv_sub2.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

#########################
# SECURITY GROUP FOR RDS # controls the inbound and outbound traffic for the RDS instance.
#########################

resource "aws_security_group" "sg_for_rds" {
  name        = "rds_sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.customvpc.id

  ingress {
    from_port       = 5432 #for PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_back1.id] 
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}
